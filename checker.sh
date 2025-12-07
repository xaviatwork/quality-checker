#!/usr/bin/env bash

REPO_PATH="/Users/xavi/repos/work/gitc-gcp-unipipe-service-broker-d"
shellcheck_report="raw_output.json"
report="report.json"
if [[ -f $shellcheck_report ]]; then rm $shellcheck_report; fi
if [[ -f $report ]]; then rm $report; fi

for f in "$REPO_PATH"/*.sh; do
    shellcheck "$f" --format=json | jq . >> "./$shellcheck_report"
done

jq '.[] | {"code": .code, "message": .message, "level": .level}' "$shellcheck_report" | jq -s > "$report"

total=$(jq 'length' "$report")
info=$(jq ' [ select( .[].level == "info" )] | length' "$report")
warning=$(jq ' [ select( .[].level == "warning" )] | length' "$report")
error=$(jq ' [ select( .[].level == "error" )] | length' "$report")

percent_error=$(( error * 100 / total ))
percent_warning=$(( warning * 100 / total ))
percent_info=$(( 100 -  percent_warning - percent_error ))

COLOR_AUTO='\e[0m'
COLOR_RED='\e[0;31m'
COLOR_YELLOW='\e[1;33m'
COLOR_BLUE='\e[0;34m'

(
    printf "%8s %5d ShellCheck findings\n" "TOTAL" "$total"
    printf "${COLOR_AUTO}-----------------------------------\n"
    printf "%8s %5d: %3d %% " "INFO" $info $percent_info
    printf "$COLOR_BLUE"
    for (( i=0;i < percent_info; ++i )) ; do
        printf "█"
    done
    printf "${COLOR_AUTO}\n"

    printf "%8s %5d: %3d %% " "WARNINGS" $warning $percent_warning
    printf $COLOR_YELLOW
    for (( i=0;i < percent_warning; i++ )) ; do
        printf "█"
    done
    printf "${COLOR_AUTO}\n" $percent_warning

    printf "%8s %5d: %3d %% " "ERRORS" $error
        printf $COLOR_RED
    for (( i=0;i < percent_error; i++ )) ; do 
        printf "█"
    done
    printf "${COLOR_AUTO}\n-----------------------------------\n"
) | tee -a history.txt

# # To generate the `commit.json` file, the shellcheck command is:
# $shellcheck *.sh --format=json \
# | jq '.[] 
# | {"level": .level, "file": .file, "message": .message, "help": ["https://github.com/koalaman/shellcheck/wiki/SC", .code] 
# | join("")}' \
# | jq -s \
# | tee commit.json
# repo="/Users/xavi/repos/work/gitc-gcp-project-watcher"
# input_file="$repo/commit.json"

# INFO=$(jq '.[] | select( .level == "error")' $input_file | jq -s | jq length)
# warnings=$(jq '.[] | select( .level == "warning")' $input_file | jq -s | jq length)
# infos=$(jq '.[] | select( .level == "info")' $input_file | jq -s | jq length)
# styles=$(jq '.[] | select( .level == "style")' $input_file | jq -s | jq length)
# commit=$(cd $repo || exit ; git rev-parse --short HEAD)
# # cidate=$(cd $repo || exit ; git show --no-patch --format=%at)

# echo "errors: $errors"
# echo "warnings: $warnings"
# echo "infos: $infos"
# echo "styles: $styles"
# echo "commit: $commit"
# echo "commit date: $cidate"

# # data="{category: \"errors\", count: $errors}, {category: \"warning\", count: $warnings}, {category: \"infos\", count: $infos}, {category: \"styles\", count: $styles}"

# # sed -e "s/CIPLACEHOLDER/$commit/g" -e "s/DATAPLACEHOLDER/${data}/g" chart.tpl > chart.html 

