#!/usr/bin/env bash
REPO_PATH="/Users/xavi/repos/work/gitc-gcp-apptio"

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
    for (( i=0; i<122; i++)); do
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

    percent=$(percentage $value $total)

    printf "%-8s %5d (%3d %%) " "$(echo "$label" | awk '{print toupper($0)}')" "$value" "$percent"
    printf "$color"
    for (( i=0;i < percent; ++i )) ; do
        printf "█"
    done
    printf "${COLOR_AUTO}\n"
}

main() {
    local repository raw_report_file report_file
    local total info warning error
    
    raw_report_file="/tmp/raw_output.json"
    report_file="/tmp/repost.json"
    repository="$1"

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
    info=$(jq ' [ select( .[].level == "info" )] | length' "$report_file")
    warning=$(jq ' [ select( .[].level == "warning" )] | length' "$report_file")
    error=$(jq ' [ select( .[].level == "error" )] | length' "$report_file")

    # Print Report
    print_header "$repository"
    print_bar $info $total "info"
    print_bar $warning $total "warning"
    print_bar $error $total "error"
    print_total
}

main $REPO_PATH

# (
#     printf "%8s %5d ShellCheck findings\n" "TOTAL" "$total"
#     printf "${COLOR_AUTO}-----------------------------------\n"
#     printf "%8s %5d: %3d %% " "INFO" $info $percent_info

#    print_bar $percent_info

#     printf "%8s %5d: %3d %% " "WARNINGS" $warning $percent_warning
#     printf $COLOR_YELLOW
#     for (( i=0;i < percent_warning; i++ )) ; do
#         printf "█"
#     done
#     printf "${COLOR_AUTO}\n" $percent_warning

#     printf "%8s %5d: %3d %% " "ERRORS" $error
#         printf $COLOR_RED
#     for (( i=0;i < percent_error; i++ )) ; do 
#         printf "█"
#     done
#     printf "${COLOR_AUTO}\n-----------------------------------\n"
# ) | tee -a history.txt

# # # To generate the `commit.json` file, the shellcheck command is:
# # $shellcheck *.sh --format=json \
# # | jq '.[] 
# # | {"level": .level, "file": .file, "message": .message, "help": ["https://github.com/koalaman/shellcheck/wiki/SC", .code] 
# # | join("")}' \
# # | jq -s \
# # | tee commit.json
# # repo="/Users/xavi/repos/work/gitc-gcp-project-watcher"
# # input_file="$repo/commit.json"

# # INFO=$(jq '.[] | select( .level == "error")' $input_file | jq -s | jq length)
# # warnings=$(jq '.[] | select( .level == "warning")' $input_file | jq -s | jq length)
# # infos=$(jq '.[] | select( .level == "info")' $input_file | jq -s | jq length)
# # styles=$(jq '.[] | select( .level == "style")' $input_file | jq -s | jq length)
# # commit=$(cd $repo || exit ; git rev-parse --short HEAD)
# # # cidate=$(cd $repo || exit ; git show --no-patch --format=%at)

# # echo "errors: $errors"
# # echo "warnings: $warnings"
# # echo "infos: $infos"
# # echo "styles: $styles"
# # echo "commit: $commit"
# # echo "commit date: $cidate"

# # # data="{category: \"errors\", count: $errors}, {category: \"warning\", count: $warnings}, {category: \"infos\", count: $infos}, {category: \"styles\", count: $styles}"

# # # sed -e "s/CIPLACEHOLDER/$commit/g" -e "s/DATAPLACEHOLDER/${data}/g" chart.tpl > chart.html 


