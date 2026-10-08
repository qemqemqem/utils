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

# Get CPU temperature (try coretemp package, then thinkpad CPU, then thermal zone)
temp=$(sensors 2>/dev/null | awk -F'[+°]' '/^Package id 0:/ {print $2; exit}')
[[ -z "$temp" ]] && temp=$(sensors 2>/dev/null | awk -F'[+°]' '/^CPU:/ {print $2; exit}')
[[ -z "$temp" ]] && { z=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); [[ -n "$z" ]] && temp=$(echo "scale=1; $z/1000" | bc); }

# Color based on temperature
temp_color="green"
temp_int=${temp%.*}
[[ -n "$temp_int" && $temp_int -ge 75 ]] && temp_color="yellow"
[[ -n "$temp_int" && $temp_int -ge 90 ]] && temp_color="red"

# Helper: pick green/yellow/red for a value given yellow/red thresholds (integer compare)
pcolor() {
    local v=${1%.*} c="green"
    [[ -n "$v" && "$v" -ge "$2" ]] 2>/dev/null && c="yellow"
    [[ -n "$v" && "$v" -ge "$3" ]] 2>/dev/null && c="red"
    echo "$c"
}

# Helpers: KB -> "1.2G"/"340M", seconds -> "45m"/"5h"/"3d"
human_kb() { awk -v k="$1" 'BEGIN{ if (k >= 1048576) printf "%.1fG", k/1048576; else printf "%dM", k/1024 }'; }
human_age() {
    local s=$1
    if   [[ $s -lt 3600 ]];  then echo "$(( s / 60 ))m"
    elif [[ $s -lt 86400 ]]; then echo "$(( s / 3600 ))h"
    else                          echo "$(( s / 86400 ))d"; fi
}

# I/O wait — disk-bound stalls that show up as low CPU% but a frozen machine
iowait=$(echo "$cpu_line" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /wa/) {gsub(/[^0-9.]/,"",$i); print $i}}')
iowait=${iowait:-0}
iowait_color=$(pcolor "$iowait" 10 25)

# Pressure stall info — % of the last 10s some task was stalled waiting on a resource
psi_some() { awk '/^some/{for(i=1;i<=NF;i++) if(sub(/avg10=/,"",$i)) print $i}' "/proc/pressure/$1" 2>/dev/null; }
psi_cpu=$(psi_some cpu); psi_mem=$(psi_some memory); psi_io=$(psi_some io)
psi_cpu_color=$(pcolor "$psi_cpu" 30 60)
psi_mem_color=$(pcolor "$psi_mem" 5 20)
psi_io_color=$(pcolor "$psi_io" 5 20)

# CPU clock — a busy CPU pinned well below max means throttling or a power-save cap
freq_max=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
freq_cur=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -rn | head -1)
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
freq_color="green"
if [[ -n "$freq_cur" && -n "$freq_max" && ${freq_max:-0} -gt 0 ]]; then
    freq_pct=$(( freq_cur * 100 / freq_max ))
    freq_mhz=$(( freq_cur / 1000 ))
    freq_maxmhz=$(( freq_max / 1000 ))
    # Only a concern when the CPU is actually busy but clocked low (idle down-clocking is normal)
    [[ ${cpu_int:-0} -ge 50 && $freq_pct -lt 60 ]] && freq_color="yellow"
    [[ ${cpu_int:-0} -ge 50 && $freq_pct -lt 40 ]] && freq_color="red"
fi

# Thermal/PROCHOT throttle activity — live rate (events/sec) sampled over 1s.
# This counter ticks on brief limit touches that are harmless during normal
# boost-to-limit, so it's flagged red ONLY when it's actually holding the clock
# down (CPU busy but clocked well below max). Otherwise it's a neutral readout.
throttle_note=""
tcf=/sys/devices/system/cpu/cpu0/thermal_throttle/core_throttle_count
if [[ -r "$tcf" ]]; then
    t1=$(cat "$tcf"); sleep 1; t2=$(cat "$tcf")
    trate=$(( t2 - t1 ))
    if [[ $trate -gt 0 ]]; then
        if [[ ${cpu_int:-0} -ge 50 && ${freq_pct:-100} -lt 70 ]]; then
            throttle_note=" ⚠ throttling ${trate}/s — limiting clock"
            freq_color="red"
        else
            throttle_note=" (throttle ${trate}/s, not limiting)"
        fi
    fi
fi

# Stuck processes — D = uninterruptible sleep (stuck on I/O), Z = zombie
read d_count z_count < <(ps -eo state= 2>/dev/null | awk '/^D/{d++} /^Z/{z++} END{print d+0, z+0}')
stuck_color="green"
[[ ${d_count:-0} -ge 1 ]] && stuck_color="yellow"
{ [[ ${d_count:-0} -ge 3 ]] || [[ ${z_count:-0} -ge 10 ]]; } && stuck_color="red"

# Swap — only surfaced when usage is notable (>=10%)
read swap_total swap_used < <(free -m | awk '/^Swap:/ {print $2, $3}')
swap_line=""
if [[ ${swap_total:-0} -gt 0 ]]; then
    swap_pct=$(( swap_used * 100 / swap_total ))
    if [[ $swap_pct -ge 10 ]]; then
        # swap_line="  [$(pcolor "$swap_pct" 10 50)]Swap: ${swap_used}M / ${swap_total}M (${swap_pct}%)[/]"
        swap_line="  [green]Swap: ${swap_used}M / ${swap_total}M (${swap_pct}%)[/]"
    fi
fi

# Disk (root fs) — only surfaced when nearly full (>=85%)
read disk_pct disk_avail < <(df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5, $4}')
disk_line=""
if [[ ${disk_pct:-0} -ge 85 ]]; then
    disk_line="  [$(pcolor "$disk_pct" 85 95)]Disk /: ${disk_pct}% used (${disk_avail} free)[/]"
fi

# Files in RAM — tmpfs mounts (/tmp, /dev/shm, ...) live entirely in memory and only
# shrink when files are deleted. Surfaced when one holds >=100MB; colored by share of RAM.
mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
tmpfs_mounts=(); tmpfs_parts=""; tmpfs_kb=0
while read -r target used_kb; do
    [[ $used_kb -ge 102400 ]] || continue
    tmpfs_mounts+=("$target")
    tmpfs_kb=$(( tmpfs_kb + used_kb ))
    tmpfs_parts+="${tmpfs_parts:+ | }${target} $(human_kb "$used_kb")"
done < <(df -k --output=target,used -t tmpfs 2>/dev/null | tail -n +2)
tmpfs_line=""
if [[ ${#tmpfs_mounts[@]} -gt 0 ]]; then
    tmpfs_pct=$(( tmpfs_kb * 100 / mem_total_kb ))
    tmpfs_line="  [$(pcolor "$tmpfs_pct" 10 25)]Files in RAM: ${tmpfs_parts} (${tmpfs_pct}% of RAM)[/]"
fi

# Power input — USB-C PD negotiation. A low-wattage source power-throttles the
# CPU (clamped to ~min clock) even though it reads as "plugged in". Laptop-class
# charging needs the negotiated voltage to step up to ~20V, not stay at 5V.
charger_text="—"; charger_color="green"
for d in /sys/class/power_supply/ucsi-source-psy-*; do
    v=$(cat "$d/voltage_now" 2>/dev/null)
    [[ -z "$v" || ${v:-0} -le 0 ]] && continue
    c=$(cat "$d/current_now" 2>/dev/null)
    cv=$(( v / 1000000 ))
    ca=$(awk -v x="${c:-0}" 'BEGIN{printf "%.1f", x/1e6}')
    cw=$(awk -v v="$v" -v c="${c:-0}" 'BEGIN{printf "%.0f", (v/1e6)*(c/1e6)}')
    charger_text="${cv}V ${ca}A (~${cw}W in)"
    # Voltage is the capability tell: 5V = 15W-class brick, 9V = partial PD, 15/20V = laptop-class
    # [[ $cv -le 9 ]] && charger_color="yellow"
    # [[ $cv -le 5 ]] && charger_color="red"
    break
done
if [[ "$charger_text" == "—" && "$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)" == "0" ]]; then
    # charger_text="on battery"; charger_color="yellow"
    charger_text="on battery"
fi

# Limits — the levers that actually cap this ThinkPad's clock: the MMIO PL1 power
# cap (EC can drop it; ~6W = Lap-mode throttle), the platform_profile (fan curve /
# EC budget; low-power = lazy fan), and the hottest skin sensor (EC clamps the clock
# at the SEN hot/critical trips, typically 75/80°C).
pl1_uw=$(cat /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw 2>/dev/null)
pl1_w=$(( ${pl1_uw:-0} / 1000000 ))
pl1_color="green"
[[ $pl1_w -lt 20 ]] && pl1_color="yellow"
[[ $pl1_w -lt 15 ]] && pl1_color="red"
profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)
case "$profile" in
    performance) profile_color="green" ;;
    low-power)   profile_color="red" ;;
    *)           profile_color="yellow" ;;
esac
skin_name=""; skin_c=""; skin_hot=""; skin_crit=""
for z in /sys/class/thermal/thermal_zone*; do
    [[ "$(cat "$z/type" 2>/dev/null)" == SEN* ]] || continue
    t=$(( $(cat "$z/temp" 2>/dev/null || echo 0) / 1000 ))
    if [[ -z "$skin_c" || $t -gt $skin_c ]]; then
        skin_name=$(cat "$z/type"); skin_c=$t; skin_hot=""; skin_crit=""
        for p in "$z"/trip_point_*_type; do
            case "$(cat "$p")" in
                hot)      skin_hot=$(( $(cat "${p%_type}_temp") / 1000 )) ;;
                critical) skin_crit=$(( $(cat "${p%_type}_temp") / 1000 )) ;;
            esac
        done
    fi
done
skin_text=""
if [[ -n "$skin_name" ]]; then
    skin_color=$(pcolor "$skin_c" "${skin_hot:-75}" "${skin_crit:-80}")
    skin_text=" | [${skin_color}]skin ${skin_name} ${skin_c}°C (trip ${skin_hot:-?}/${skin_crit:-?})[/]"
fi
limits_line="  [${pl1_color}]Limits: PL1 ${pl1_w}W[/] | [${profile_color}]profile ${profile:-?}[/]${skin_text}"

# Print System Status header through glow (blue)
echo "## System Status" | glow -

# Assemble colored status lines for rich
status="  [${cpu_color}]CPU: ${cpu_used}% used[/] | [${load_color}]Load: ${load}[/] (${cores} cores)
  [${mem_color}]RAM: ${mem_used_gb}G / ${mem_total_gb}G (${mem_pct}%)[/]
  [${temp_color}]Temp: ${temp:-N/A}°C[/]
  [${psi_cpu_color}]Pressure: cpu ${psi_cpu:-?}%[/] | [${psi_mem_color}]mem ${psi_mem:-?}%[/] | [${psi_io_color}]io ${psi_io:-?}%[/]
  [${freq_color}]Clock: ${freq_mhz:-?}MHz / ${freq_maxmhz:-?}MHz (${freq_pct:-?}%, ${governor:-?})${throttle_note}[/]
${limits_line}
  [${charger_color}]Power: ${charger_text}[/]
  [${iowait_color}]I/O wait: ${iowait}%[/] | [${stuck_color}]Stuck: ${d_count:-0}D / ${z_count:-0}Z[/]"
[[ -n "$swap_line" ]] && status+=$'\n'"$swap_line"
[[ -n "$disk_line" ]] && status+=$'\n'"$disk_line"
[[ -n "$tmpfs_line" ]] && status+=$'\n'"$tmpfs_line"

printf '%s\n\n' "$status" | rich -p --force-terminal -

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

    # RAM files table — biggest top-level entries in the tmpfs mounts flagged above.
    # "Last change" = newest modification anywhere inside; old = likely safe to clear.
    if [[ ${#tmpfs_mounts[@]} -gt 0 ]]; then
        echo ""
        echo "## Top RAM files"
        echo "| Path | Size | Last change |"
        echo "|------|------|-------------|"
        now=$(date +%s)
        for m in "${tmpfs_mounts[@]}"; do
            du -xs --time --time-style=+%s -- "$m"/* "$m"/.[!.]* 2>/dev/null
        done | sort -rn | awk '$1 >= 51200' | head -10 | while read -r kb mtime path; do
            printf "| %s | %6s | %s ago |\n" "$path" "$(human_kb "$kb")" "$(human_age $(( now - mtime )))"
        done
    fi
} | glow -
