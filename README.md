# git-tag-cleanup

Repo with a Bash script to remove tags from a git repo

The script takes few non-positional arguments/options:
- A date (string): tags of this date and older will be removed: 
    - example: --date 2021-02-17
- A repository path to operate upon: 
	- example: --repo https://github.com/kubernetes/kubernetes

Script usage:

usage: ./removal.sh [-v] [-b] [-d <YYYY-MM-DD>] [-r <GitHub URL>]

arguments:"
- "**-v** Verbose output"
- "**-b** Debug output. All deletions must be approved manually"
- "**-d** date input for tags to be removed before (inclusive), format YYYY-MM-DD
- "**-r** repo GitHub URL from which tags will be removed"
- "**-y** yes mode, not asking for any deletion approval. Does not work with debug option"

Example usage for calling script to delete all tags in kubernetes git repo before and including 2016-07-01. Also adding
the verbose and debugging output.

`./git-tag-cleanup/removal.sh -r https://github.com/kubernetes/kubernetes -d 2016-07-01 -bv`
