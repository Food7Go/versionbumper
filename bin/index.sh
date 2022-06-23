#! /usr/bin/env bash

# functions
print_usage() {
  printf "
    VERSIONBUMPER\n
    Simple lightweight utility to manage package.json version.\n\n
    commands:\n
    bumpme: only command that you can run with this package. Will bump your version according to your arguments.\n\n
    flags:\n
    -s: sets the severity of the bump. Accepts: patch, minor, major\n
    -i: sets the increment. Accepts int value.\n
    -h: prints this message\n\n
    "
}

# arguments extraction
severity_flag=''
increment_flag=''
acepted_severity=("patch" "minor" "major")

while getopts 's:i:ha:' flag; do
  case "${flag}" in
    s) severity_flag=${OPTARG} ;;
    i) increment_flag=${OPTARG} ;;
    h) print_usage
    exit 0;;
  esac
done

# validating argument
# must be an accepted value
if [[ $severity_flag ]]; then 
    if [[ ! " ${acepted_severity[*]} " =~ " ${severity_flag} " ]]; then
        echo "The value you passed for severity does not match any of the accepted values: patch, minor, major";
        exit 0;
    fi
fi

# must be a number
if [[ $increment_flag ]]; then
    case $increment_flag in
        ''|*[!0-9]*) echo "The value you passed for increment is not a number.";
            exit 0;;
        *) echo '';;
    esac
else
    echo '';
    increment_flag=1;
fi

# the script can start
printf "********************************************\n"
printf "🤖 Automated version bump script activated 🤖\n"
printf "********************************************\n\n"

if [[ $severity_flag && $increment_flag ]]; then
    echo "Bumping with args";
else
    echo "Bumping with git commit message";
    # get message of latest commit which should contain the
    # details used for versioning
    echo "Getting latest commit..."
    commit=`git log -1 --pretty=%B` || exit 0;
    echo "Got latest commit ✅"

    # understand which case it has to handle: major, minor, hotfix
    echo "Extracting the severity and incrmeent of the commit..."
    command=${commit#*[[}
    severity_flag=${command%:*}
    increment_flag=${command#*:}
    increment_flag=${command%${']]'}*}
    echo "We need to bump the version of $severity_flag by increment_flag $increment_flag ✅"
fi

# gets current package version from package.json
echo "Getting current version..."
current=`node --eval="process.stdout.write(require('./package.json').version)"`
echo "Got current version: $current ✅"

# extract the current version values
echo "Exploding the current version..."
IFS='.' read -r -a versions <<< "$current"
majorcur=${versions[0]}
minorcur=${versions[1]}
patchcur=${versions[2]}
echo "Got all component separated. ✅"

# set the version in package.json
echo "Bumping version by $increment_flag..."
if [[ $severity_flag == "major" ]]; then
    majorcur=$(( $majorcur + $increment_flag ))
    minorcur=0
    patchcur=0
elif [[ $severity_flag == "minor" ]]; then
    minorcur=$(( $minorcur + $increment_flag ))
    patchcur=0
elif [[ $severity_flag == "patch" ]]; then
    patchcur=$(( $patchcur + $increment_flag ))
else
    echo "Your git commit message does not contain a proper formatted command. ex: [[patch:1]]."
    exit 0;
fi
newver=$majorcur.$minorcur.$patchcur
# npm version $newver --commit-hooks false --git-tag-version false
echo "New version $newver is set ✅"
