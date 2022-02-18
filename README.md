# git-tag-cleanup

Repo with a Bash script to remove tags from a git repo

The script takes few non-positional arguments/options:
- A date (string): tags of this date and older will be removed: 
    - example: --date 2021-02-17
- A repository path to operate upon: 
	- example: --repo https://github.com/kubernetes/kubernetes
