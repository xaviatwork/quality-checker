#!/usr/bin/env bash

main() {
    local repo
    local style info warning error
    local report report_raw format csv_separator csv_ouput
    local bw color_auto color_red color_yellow color_blue
    local total qscore
    main_args "$@"

    if ! found_sh_files "$repo"; then
        exit 1
    fi

    shellchecker "$repo"
    total=$(jq '. | length' "$report")
    # Get ShellCheck findings
    if [[ $total -ne 0 ]]; then
        style=$(jq '[ select( .[].level == "style" ) ] | length' "$report")
        info=$(jq '[ select( .[].level == "info" ) ] | length' "$report")
        warning=$(jq '[ select( .[].level == "warning" )] | length' "$report")
        error=$(jq '[ select( .[].level == "error" )] | length' "$report")
    fi

    qscore=$(( 0 - style - 2*info - 4*warning - 8*error ))
    
    case $format in
        csv)
            csv_separator=';'
            csv_ouput=$(mktemp -t csv.XXXXX)
            (
                echo "Repository $csv_separator style $csv_separator Info $csv_separator Warning $csv_separator Error $csv_separator Total $csv_separator Qscore"
                echo "$repo $csv_separator $style $csv_separator $info $csv_separator $warning $csv_separator $error $csv_separator $total $csv_separator  $qscore"
            ) | tee "$csv_ouput"
        ;;
        qscore)
            echo "$qscore"
        ;;
        *)
            # Default: Histogram
            print_header "$repo" "$total"
            print_bar "$style" "$total" "style"
            print_bar "$info" "$total" "info"
            print_bar "$warning" "$total" "warning"
            print_bar "$error" "$total" "error"
        ;;
    esac
}

main_args() {
    # Default values
    report_raw=$(mktemp -t shellcheck.XXX)
    report=$(mktemp -t shellcheck.XXX)
    style=0
    info=0
    warning=0
    error=0
    bw='false'
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case "$key" in
            --repo)
                repo=${2:?$1 cannot be empty}
                shift 2
            ;;
            --no-color)
                bw='true'
                shift
            ;;
            --format)
                format=${2:?$1 cannot be empty}
                case "$format" in
                    csv | hist | qscore ) shift 2; continue ;;
                    *) exit 1;;
                esac
                shift 2
            ;;
            *) shift;;
        esac
    done
    # Check required variables
    repo=${repo:?'--repo' is mandatory}

    # Set colors
    if [[ $bw == 'false' ]];then
        color_auto='\e[0m'
        color_red='\e[0;31m'
        color_yellow='\e[1;33m'
        color_blue='\e[0;34m'
    fi
}

found_sh_files() {
    # Check if target location contain *.sh files
    local repository

    repository="$1"
    if [[ ! -d "$repository" ]]; then
        echo >&2 "[ERROR] Repository '$repository' cannot be found"
        return 1
    fi
    if ! find "$repository"/*.sh -prune -path "*/.devcontainer/*" -path "*/git/*"> /dev/null ; then 
        echo >&2 "[WARNING] Repository '$repository' does not contains *.sh files"
        return 1
    fi
}

shellchecker() {
    local repository
    repository="$1"
    while read -r file; do
        shellcheck "$file" --format=json >> "$report_raw"
    done < <( find "$repository"/*.sh )
    # Join all individual reports into one 
    jq '.[] | {"level": .level}' "$report_raw" | jq -s > "$report"
}

percentage() {
    local total value
    value=$1
    total=$2
    echo $(( value * 100 / total ))
}

print_header() {
    local repository msg ok
    repository="$1"
    msg=$(printf " ShellCheck findings for '%s'\n" "$repository")
    
    ok=''
    if [[ $total == 0 && $bw == 'false' ]]; then ok='\033[42m'; fi
    # spacer=" "
    printf "\n%12s %-101s %b %s %b\n" "QSCORE: $qscore" "$msg" "$ok" "TOTAL: $total" "$color_auto"
}

print_bar() {
    local value total label percent
    local bar bar_char
    value=$1
    total=$2
    label="$3"

    case $label in
        "style"  ) color=$color_auto; bar_char="░";;
        "info"   ) color=$color_blue; bar_char="▒";;
        "warning") color=$color_yellow; bar_char="▓";;
        "error"  ) color=$color_red; bar_char="█";;
        *        ) color=$color_auto ;;
    esac

    if [[ $bw == 'true' ]]; then
        color=''
    fi

    if (( total != 0 )); then
        percent=$(percentage "$value" "$total")
    fi

    bar=""
    for (( i=0;i < percent; ++i )) ; do
        bar="${bar}${bar_char}"
    done
    for (( i=percent;i < 100; ++i )) ; do
        bar="${bar}·"
    done
    printf "%12s ├%b%100s%b┤ %3d %% (%s)\n" "$(echo "$label" | awk '{print toupper($0)}')" "$color" "$bar" "$color_auto" "$percent" "$value"
}

# Check for dependencies
which jq > /dev/null         || { echo "'jq' was not found in the \$PATH" ; exit 1; }
which shellcheck > /dev/null || { echo "'shellcheck' was not found in the \$PATH" ; exit 1; } 
# ----
main "$@"
