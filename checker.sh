#!/usr/bin/env bash

print_header() {
    local repository msg
    repository="$1"
    msg=$(printf "ShellCheck findings for $repository\n")
    
    echo "$msg"
    print_line "${#msg}"
}

print_total() {
    msg=$(printf "%-8s %5d\n" "TOTAL" "$total")
    print_line
    echo "$msg"
}

print_line() {
    local length
    length=$(( 8 + 1 + 5 + 1 + 3 + 1 + 1 + 2 + 1 + 100)) # Length of the bar and other fields
    for (( i=0; i< length; i++)); do
        printf "-"
    done
    echo ""
}

percentage() {
    local total value
    value=$1
    total=$2

    echo $(( value * 100 / total ))
}

print_bar() {
    local value total percent label
    local COLOR_AUTO COLOR_RED COLOR_YELLOW COLOR_BLUE
    value=$1
    total=$2
    label="$3"

    COLOR_AUTO='\e[0m'
    COLOR_RED='\e[0;31m'
    COLOR_YELLOW='\e[1;33m'
    COLOR_BLUE='\e[0;34m'

    case $label in
        "info"   ) color=$COLOR_BLUE;;
        "warning") color=$COLOR_YELLOW;;
        "error"  ) color=$COLOR_RED;;
        *        ) color=$COLOR_AUTO ;;
    esac

    if (( total != 0 )); then
        percent=$(percentage "$value" "$total")
    fi

    printf "%-8s %5d (%3d %%) " "$(echo "$label" | awk '{print toupper($0)}')" "$value" "$percent"
    printf "%b" "$color"
    for (( i=0;i < percent; ++i )) ; do
        printf "█"
    done
    printf "%b\n" "$COLOR_AUTO"
}

main() {
    local repository raw_report_file report_file
    local total info warning error
    
    raw_report_file="/tmp/raw_output.json"
    report_file="/tmp/repost.json"
    repository="$1"

    # Check if target location contain *.sh files
    if ! find "$repository"/*.sh  &> /dev/null ; then 
        echo "[WARNING] Repository '$repository' does not contains *.sh files"
        return
    fi

    # Clean Up
    if [[ -f $raw_report_file ]]; then rm $raw_report_file; fi
    if [[ -f $report_file ]]; then rm $report_file; fi

    # Generate raw report using ShellCheck
    for f in "$repository"/*.sh; do
        shellcheck "$f" --format=json | jq . >> "$raw_report_file"
    done
    # Filter raw report using Jq
    jq '.[] | {"level": .level}' "$raw_report_file" | jq -s > "$report_file"

    # Count findings
    total=$(jq 'length' "$report_file")
    if (( total != 0 )); then
        info=$(jq ' [ select( .[].level == "info" )] | length' "$report_file")
        warning=$(jq ' [ select( .[].level == "warning" )] | length' "$report_file")
        error=$(jq ' [ select( .[].level == "error" )] | length' "$report_file")
    else
        info=0
        warning=0
        error=0
    fi

    # Print Report
    print_header "$repository"
    print_bar $info $total "info"
    print_bar $warning $total "warning"
    print_bar $error $total "error"
    print_total
}

# ----

REPOS_BASE_SCRIPT="/Users/xavi/repos/work"

while read -r repo; do 
    main "$REPOS_BASE_SCRIPT/$repo"
done < repos.txt
