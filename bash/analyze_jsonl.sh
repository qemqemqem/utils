#!/bin/bash

# Function to show structure recursively with proper indentation
function show_structure_recursive() {
    local json_file="$1"
    local prefix="$2"
    local path="$3"

    # Get type using the full path
    if [ -z "$path" ]; then
        type=$(jshon -t < "$json_file")
    else
        type=$(jshon $path -t < "$json_file")
    fi

    case "$type" in
        "object")
            echo "$prefix$type:"
            # Get keys at current path
            if [ -z "$path" ]; then
                keys=$(jshon -k < "$json_file")
            else
                keys=$(jshon $path -k < "$json_file")
            fi

            echo "$keys" | while read -r key; do
                echo -n "$prefix  $key: "
                if [ -z "$path" ]; then
                    new_path="-e $key"
                else
                    new_path="$path -e $key"
                fi
                show_structure_recursive "$json_file" "$prefix  " "$new_path"
            done
            ;;
        "array")
            if [ -z "$path" ]; then
                length=$(jshon -l < "$json_file")
            else
                length=$(jshon $path -l < "$json_file")
            fi
            echo "$type[length=$length]"
            if [ "$length" -gt 0 ]; then
                echo -n "$prefix  [0]: "
                if [ -z "$path" ]; then
                    new_path="-e 0"
                else
                    new_path="$path -e 0"
                fi
                show_structure_recursive "$json_file" "$prefix  " "$new_path"
            fi
            ;;
        *)
            echo "$type"

# Main function to process JSONL file
function analyze_jsonl() {
    local file="$1"
    echo "Structure of first JSONL entry:"
    echo "=============================="
    # Create a temporary file for the first JSON entry
    tmp_file=$(mktemp)
    head -n1 "$file" > "$tmp_file"
    show_structure_recursive "$tmp_file" "" ""
    rm "$tmp_file"
}

# Usage
# analyze_jsonl "dinner_party.jsonl"
