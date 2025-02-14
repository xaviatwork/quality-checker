#!/usr/bin/env bash

# To generate the `commit.json` file, the shellcheck command is:
# $shellcheck *.sh --format=json \
# | jq '.[] \
# | {"level": .level, "file": .file, "message": .message, "help": ["https://github.com/koalaman/shellcheck/wiki/SC", .code] \
# | join("")}' \
# | jq -s \
# | tee commit.json
repo="/Users/xavi/repos/work/gitc-gcp-project-watcher"
input_file="$repo/commit.json"

errors=$(jq '.[] | select( .level == "error")' $input_file | jq -s | jq length)
warnings=$(jq '.[] | select( .level == "warning")' $input_file | jq -s | jq length)
infos=$(jq '.[] | select( .level == "info")' $input_file | jq -s | jq length)
styles=$(jq '.[] | select( .level == "style")' $input_file | jq -s | jq length)
commit=$(cd $repo || exit ; git rev-parse --short HEAD)
cidate=$(cd $repo || exit ; git show --no-patch --format=%at)

echo "errors: $errors"
echo "warnings: $warnings"
echo "infos: $infos"
echo "styles: $styles"
echo "commit: $commit"
echo "commit date: $cidate"