#!/bin/bash
# 0.a: Initializing parameters for script that will be parsed
date=""
repo=""
verbose_mode=false
debug_mode=false
yes_mode=false

# 0.b: initializing helper functions for script
# using trap to catch sigint (ctrl+C) and print required message
trap ctrl_c INT
ctrl_c() {
  echo "The execution of the script was aborted due to user entering Ctrl-c"
  exit 1
}
# Usage statement to be printed when no arguments are given
print_usage() {
  echo "usage: ./removal.sh [-v] [-b] [-d <YYYY-MM-DD>] [-r <GitHub URL>]"
  echo "arguments:"
  echo -e "  -v\t\t Verbose output"
  echo -e "  -b\t\t Debug output"
  echo -e "  -d\t\t date input for tags to be removed before (inclusive), format YYYY-MM-DD"
  echo -e "  -r\t\t repo GitHub URL from which tags will be removed"
  echo -e "  -y\t\t yes mode, not asking for any deletion approval"
}
# log functions used to describe verbose operation
log() {
  if [[ "$verbose_mode" = false ]]; then
    return
  fi

  echo "verbose=> $1"
}
# debug function to get approval before deleting every tag
debug() {
  if [[ "$debug_mode" = false ]]; then
    return
  fi
  echo "debug=> Deleting $1 $2"
  validate
}
# getting user input to confirm that a tag should be deleted
validate() {
  read -p "Do you want to continue? [Y/n]: " yesAnswer
  if [[ "$yesAnswer" != "Y" ]] && [[ "$yesAnswer" != "y"  ]];then
    echo "Abort"
    exit 1
  fi
}
# performing actual delete tag operation and debug validation and logging for verbosity
delete_tag() {
  # first send to debug to validate
  debug $1 $2
  # perform actual deletion operation
  deleteMsg=$( git tag -d $2 )
  # log for verbose that the tag is about to be deleted
  [[ $? = 0 ]] && log "$deleteMsg"
}
# 1.a: validate parameters are given and if not print usage
# If no parameters have been given, print the usage and exit
if [[ $# -eq 0 ]]; then
  print_usage
  exit 0
fi
# 1.b: get parameters and set correctly based off inputs
# using getopts to get the non-positional parameters for delete tags
while getopts 'd:r:bvy' flag; do
  case "${flag}" in
    d) date="${OPTARG}" ;;
    r) repo="${OPTARG}" ;;
    v) verbose_mode=true ;;
    b) debug_mode=true ;;
    y) yes_mode=true ;;
    *) print_usage
       exit 1 ;;
  esac
done

# 2.c: Validate user inputs for date and repo
test_date=$( date -d "$date" +%Y-%m-%d || echo "" )
test_repo=$( curl --write-out "%{http_code}\n" --silent --output /dev/null "$repo" )
if [[ -z "$date" || -z "$repo" ]];then
  echo "Error:"
  echo "  -d and -r are both required for this script"
  echo "  Please validate input parameters"
  echo "  Given repo URL: \"$repo\""
  echo "  Given date: \"$date\""
  exit 1
fi
if [[ "$test_repo" -ne 200 ]];then
  echo "Error:"
  echo "  -r parameter was unreachable with a 200 HTTP response code"
  echo "  URL return response code of $test_repo"
  echo "  Please validate repo URL"
  echo "  Example URL: https://github.com/kubernetes/kubernetes"
  echo "  Given repo URL: \"$repo\""
  exit 1
fi
if [[ -z "$test_date" ]];then
  echo "Error:"
  echo "  -d parameter was given in incorrect format, format should be YYYY-MM-DD"
  echo "  Please validate date"
  echo "  Example date: 2021-02-17"
  echo "  Given date: \"$date\""
  exit 1
fi

# 3.a: if repo does not exist in pwd then clone the repository from the given url
readarray -d / -t strarr <<< "$repo"
repoFolder=$( echo "${strarr[${#strarr[*]}-1]}" )

log "parameters received:"
log "  -r: $repo"
log "  -d: $date"
log "  -b: $debug_mode"
log "  -v: $verbose_mode"

log "looking if repo exists in pwd"
if [[ ! -d "$repoFolder" ]];then
  log "repo \"$repo\" does not exist in pwd"
  log "cloning repo into pwd now"
  git clone "$repo"
else
  log "repo exists at $( readlink -f "$repoFolder" )"
fi

cd "$repoFolder"

# 3.b: get the dates before and including the given date. Operation done comparing epoch dates
date_epoch=$(date -d "$date" +%s)
declare -a tagArr
tagArr=( $(git for-each-ref --sort=taggerdate --format='%(creatordate:raw) %(tag)' refs/tags \
   | awk -v date_epoch="$date_epoch" '{t=strftime("%Y-%m-%d",$1); if ($1 <= date_epoch) { printf("%s_%s\n", t, $3) } }') )
# 3.c: tracking yes_mode to automatically delete tags if -y parameter is given
if [[ "$yes_mode" = false ]]; then
  firstDelete="${tagArr[0]}"
  lastDelete="${tagArr[${#tagArr[*]}-1]}"
  echo "Are you sure you want to delete ${#tagArr[*]} tags in the $repo repo from:"
  echo "  ${firstDelete:0:10} - ${lastDelete:0:10}"
  validate
fi
# 3.d: starting actual deletion operations, going through every tag in date range
for tag in ${tagArr[@]}
do
  readarray -d _ -t strarr <<< "$tag"
  delete_tag "${strarr[0]}" "${strarr[1]:0:-1}"
done
