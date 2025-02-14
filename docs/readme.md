# Readme

The main idea is to create an script to run `shellcheck` on each commit of the repo and save its "quality status". It will generate a "point" for each commit, and then we can represent them (over time, for example), using `chart.js`.
All of this data will be saved in a SQLite database.

## User stories

- [ ] (001) run shellcheck on a commit an get a "quality status" of the commit. The quality index is composed of error, warning, info, style levels.

### 001

We need to play with the output of the `shellcheck` command to get the information that we want

> We are currently using the latest commit (`HEAD`).

```console
$ shellcheck *.sh --format=gcc
brand.sh:26:41: note: Double quote to prevent globbing and word splitting. [SC2086]
functions.sh:2:8: note: Not following: vars.env was not specified as input (see shellcheck -x). [SC1091]
functions.sh:6:26: note: Double quote to prevent globbing and word splitting. [SC2086]
functions.sh:11:50: note: Double quote to prevent globbing and word splitting. [SC2086]
functions.sh:22:10: warning: Quote this to prevent word splitting. [SC2046]
functions.sh:22:20: note: Double quote to prevent globbing and word splitting. [SC2086]
functions.sh:22:125: note: Double quote to prevent globbing and word splitting. [SC2086]
project.sh:18:54: note: Double quote to prevent globbing and word splitting. [SC2086]
project.sh:80:9: warning: cmdb_customer_id appears unused. Verify use (or export if used externally). [SC2034]
project.sh:114:34: note: Double quote to prevent globbing and word splitting. [SC2086]
```

The best way may be to make `shellcheck` output JSON and then use Jq to filter what we want; for example, this *filters* the information that we need:

```console
shellcheck *.sh --format=json | jq '.[] | {"level": .level, "file": .file, "message": .message, "help": ["https://github.com/koalaman/shellcheck/wiki/SC", .code] | join("")}' | jq -s > commit.json
```

Then, we can get the number of warnings of each *level*; for example:

```console
errors=$(jq '.[] | select( .level == "error")' commit.json | jq -s | jq length)
warnings=$(jq '.[] | select( .level == "warning")' commit.json | jq -s | jq length)
infos=$(jq '.[] | select( .level == "info")' commit.json | jq -s | jq length)
styles=$(jq '.[] | select( .level == "style")' commit.json | jq -s | jq length)
```

We can get the current *short* version of the commit SHA:

```console
$ git rev-parse --short HEAD
f452bf8
```

Commit date (UNIT timestamp):

```console
$ git show --no-patch --format=%at f452bf8
1729157729
```

To convert to a "human readable" format, on Mac:

```console
$ date -r 1729157729
Thu Oct 17 11:35:29 CEST 2024
```

On Linux, it's supposed to be `date -d @1729157729`

We can get any other information from the commit, like the Author's name and email, for example:

```console
$ git show --no-patch --format="%an, %ae" f452bf8
Xavi Aznar, xavier.aznar@seat.es
```

We will save all of this information in tabular form, so it can be easily inserted into a SQL database.
Then, this information need to be transformed again to build the dataset in *Chart.js* format.
