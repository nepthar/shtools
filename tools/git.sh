# Git
# ---
# Various git.related enhancements

_git.setup()
{
  git_ps1_fmt="${tc_ps1_green}${tc_ps1_bold}%s${tc_ps1_reset}"
  complete -o bashdefault -o default -o nospace -F _complete_g g
}

# Shortcuts
alias g=git
alias gs=git.status
alias gp=git.push-current
alias gc=git.commit
alias gca=git.commit-all

git.status()
{
  git status "$@"
}

git.push-current()
{
  git push "$@" origin $branch
}

# g.c: Commit staged changes w/branch prefix
git.commit()
{
  if git.is-clean; then
    echo "g.c: Nothing to commit"
    return 1
  fi
  local branch="$(git.current-branch)"
  git commit -m "$branch: $@"
}

# g.ca: Stage & commit all changes w/branch prefix
git.commit-all()
{
  if git.is-clean; then
    echo "g.ca: Nothing to commit"
    return 1
  fi
  git add -u
  git.commit "$@"
}

g.rc() {
  git rebase --continue
}


git.trace-file() {

  local path=$1
  local dump_path="./git-trace-temp"

  # if [[ ! -f "$path" ]]; then
  #   echo "No such file: $path" >&2
  #   return 1
  # fi

  local filename="${path##*/}"

  echo "Generating list of commits"
  local commits=($(git log --pretty=format:"%H" --follow "$path"))

  if [[ -z "$commits" ]]; then
    echo "List of commits is empty" >&2
    return 1
  fi

  echo "Found ${#commits[@]} commits. Generating file revisions"

  rm -rf "$dump_path"
  mkdir "$dump_path"

  local -a metadata

  for csha in "${commits[@]}"; do
    metadata=($(git show -s --format="%ct %s" $csha))

    echo "Writing ${metadata[*]}"

    commit_header="$(date -r${metadata[0]} "+%y-%m-%d_%H-%M_${filename}")"
    commit_desc="${metadata[@]:1}"

    filepath="${dump_path}/${commit_header}"

    echo -e "$commit_header $csha $commit_desc\n" > "$filepath"

    git show "${csha}:${path}" >> "$filepath"
  done
}

git.is-clean() {
  [[ -z "$(git status -s || echo "nope" )" ]]
}

git.is-dirty() {
  [[ ! -z "$(git status -s)" ]]
}

## git.root (args)
## Get the full path to the .git folder if it exists pass args to printf
## for intance, to have it assing it to a var.
git.root()
{
  local wd="$PWD"
  until [[ -z "$wd" ]]; do # Loop will hang if $PWD doesn't start with /
    if [[ -d "${wd}/.git" ]]; then
      printf "$@" "%s" "${wd}/.git"
      return 0
    fi
    wd="${wd%/*}"
  done
  return 1
}

# Get the current branch if it exists. Pass args to printf
git.current-branch()
{
  if git.root -vgit_root; then
    local git_head="${git_root}/HEAD"
    local cb="???"
    if [[ -f "$git_head" ]]; then
      read < "$git_head"
      case $REPLY in
        "ref: "*) cb="${REPLY:16}" ;; # ref: refs/heads/your/branch
        *) cb="${REPLY:0:8}" ;; # hash (probably) - take first 8
      esac
      printf "$@" "%s" "$cb"
      return 0
    fi
  fi
  return 1
}

git.local-branches()
{
  git branch | cut -c3-
}


# Generate a PS1 addition. Also sets $git_branch via git.current-branch and $git_root
_git.ps1()
{
  unset git_branch
  unset git_root
  unset branch

  if git.current-branch -vgit_branch; then
    export git_branch
    export git_root
    export branch="$git_branch"

    local fmt="%s"
    local git_ps1="$git_branch"
    if [[ "$1" == "-e" ]]; then
      shift 1
      # gotchya! git.current-branch sets git_root
      if [[ "$PWD" == "$git_root"* ]]; then
        git_ps1="${git_ps1}|GIT_DIR"
      fi

      if [[ -d "${git_root}/rebase-merge" || -d "${git_root}/rebase-apply" ]]; then
        git_ps1="${git_ps1}|REBASE"
      fi
    fi
    ps1.add-part git green "${git_ps1}"
    return 0
  fi
  return 1
}

git.log-master()
{
  git log --oneline --decorate --graph --format="format:%C(auto)%h%Creset %s %Cgreen<%ae>%Creset" origin/master..HEAD
}

_complete_g()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev="${COMP_WORDS[COMP_CWORD - 1]}"
  local key="${COMP_CWORD}:$prev"

  case $key in

    "1:"*)
      return 124 # For now
      ;;

    "2:co"|"2:checkout")
      COMPREPLY=($(compgen -W "$(git.local-branches)" -- $cur))
      ;;

    *)
      return 124
      ;;
  esac
}
