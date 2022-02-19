#!/bin/bash
# Usage statement to be printed when no arguments are given
print_usage() {
  echo "usage: ./removal.sh [-v] [-b] [-d <YYYY-MM-DD>] [-r <GitHub URL>]"
  echo "arguments:"
  echo -e "  -v\t\t Verbose output"
  echo -e "  -b\t\t Debug output"
  echo -e "  -d\t\t date input for tags to be removed before (inclusive), format YYYY-MM-DD"
  echo -e "  -r\t\t repo GitHub URL from which tags will be removed"
}
# If no parameters have been given, print the usage and exit
if [[ $# -eq 0 ]]; then
  print_usage
  exit 0
fi

# Initializing parameters for script that will be parsed
date=""
repo=""
verbose_mode=false
debug_mode=true

while getopts 'd:r:bv' flag; do
  case "${flag}" in
    d) date="${OPTARG}" ;;
    r) repo="${OPTARG}" ;;
    v) verbose_mode=true ;;
    b) debug_mode=true ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Validate inputs
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
