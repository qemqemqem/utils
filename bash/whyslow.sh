#!/bin/bash
# whyslow - Show system resource usage with top CPU and RAM consumers

# Get CPU stats
load=$(awk '{print $1}' /proc/loadavg)
cores=$(nproc)
cpu_line=$(top -bn1 | grep "Cpu(s)" | head -1)
idle=$(echo "$cpu_line" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$i); print $i}}')
cpu_used=$(echo "100 - $idle" | bc)

# Get RAM stats
mem_info=$(free -b | awk '/^Mem:/ {printf "%.1f %.1f %.0f", $3/1073741824, $2/1073741824, $3/$2*100}')
mem_used_gb=$(echo "$mem_info" | awk '{print $1}')
mem_total_gb=$(echo "$mem_info" | awk '{print $2}')
mem_pct=$(echo "$mem_info" | awk '{print $3}')

# Color based on load
load_color="green"
load_int=${load%.*}
[[ $load_int -ge $cores ]] && load_color="yellow"
[[ $load_int -ge $((cores + 4)) ]] && load_color="red"

# Color based on CPU
cpu_color="green"
cpu_int=${cpu_used%.*}
[[ $cpu_int -ge 70 ]] && cpu_color="yellow"
[[ $cpu_int -ge 90 ]] && cpu_color="red"

# Color based on RAM
mem_color="green"
mem_int=${mem_pct%.*}
[[ $mem_int -ge 70 ]] && mem_color="yellow"
[[ $mem_int -ge 90 ]] && mem_color="red"

# Print System Status header through glow (blue)
echo "## System Status" | glow -

# Print colored status lines through rich
echo "  [${cpu_color}]CPU: ${cpu_used}% used[/] | [${load_color}]Load: ${load}[/] (${cores} cores)
  [${mem_color}]RAM: ${mem_used_gb}G / ${mem_total_gb}G (${mem_pct}%)[/]
" | rich -p --force-terminal -

# Build tables (piped through glow for formatting)
{
    # CPU table
    echo "## Top CPU"
    echo "| Process | CPU% | Age | Parent | PID |"
    echo "|---------|------|-----|--------|-----|"
    pidstat 1 1 2>/dev/null | awk 'NR>3 && $8>3 {
        cmd=$10; for(i=11;i<=NF;i++) cmd=cmd" "$i
        print $3, $8, cmd
    }' | sort -t' ' -k2 -rn | head -10 | while read pid cpu cmd; do
        etime=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')
        parent=$(ps -p $(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ') -o comm= 2>/dev/null | head -1)
        printf "| %-20s | %5.1f%% | %10s | %-10s | %s |\n" "$cmd" "$cpu" "$etime" "$parent" "$pid"
    done
    echo ""

    # RAM table
    echo "## Top RAM"
    echo "| Process | RAM | Age | Parent | PID |"
    echo "|---------|-----|-----|--------|-----|"
    ps -eo pid,rss,comm --sort=-rss | awk 'NR>1 && $2>102400 {
        cmd=$3; for(i=4;i<=NF;i++) cmd=cmd" "$i
        printf "%s %s %s\n", $1, $2, cmd
    }' | head -10 | while read pid rss cmd; do
        mb=$((rss / 1024))
        if [[ $mb -gt 1024 ]]; then
            ram=$(printf "%.1fG" $(echo "$mb / 1024" | bc -l))
        else
            ram="${mb}M"
        fi
        etime=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')
        parent=$(ps -p $(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ') -o comm= 2>/dev/null | head -1)
        printf "| %-20s | %6s | %10s | %-10s | %s |\n" "$cmd" "$ram" "$etime" "$parent" "$pid"
    done
} | glow -
