# ws.sh
# -----
# Workspaces keep your projects organized. The comma (,) is used to access
# workspace functionality. This is done by creating a single file,
# workspace.sh, in the pimary folder of each project. The file contains
# operations that are commonly performed or other environment variables.

# Each workspace.sh file should be able to exist without ws.sh

# Create a new workspace:
# 1) $ cd ~/my/workspace/primary/folter
# 2) $ , new

# Link up a workspace to $shtools_root/workspaces for quick access
# 1) $ ws.add # when in workspace

# Start working in a workspace:
# 1) $ , [workspace name] or [workspace file]
#   -  Tab completion works for selecting a workspace. Woohoo.
#   -  The command (,) by itself will return you to the workspace's home

# Finish working in a workspace:
# 1) Close the shell. There's no "exiting"

# Workspace Name
export workspace

# Configuration
export ws_root="${shtools_root}/workspaces"
export ws_home
export ws_funcs=()
export ws_file

## ws.info
## Dumps information about the workspace state
ws.info()
{
  echo "workspace: $workspace"
  echo "ws_root: $ws_root"
  echo "ws_home: $ws_home"
  echo "ws_funcs: (${ws_funcs[@]})"
  echo "ws_file: $ws_file"
}

## ws.ls
## List workspaces that ws knowns about
ws.ls()
{
  ls -alh "${ws_root}"/*.ws
}

## ws.new (name)
## Create a new workspace in the current folder with a given name. If
## name is not provided, the name of the folder will be used.
ws.new()
{
  local new_name="$1"
  local new_home="$PWD"

  if [[ -z $new_name ]]; then
    new_name="${new_home##*/}"
  fi

  if [[ -f workspace.sh ]]; then
    emsg "workspace.sh already exists"
    return 1
  fi

  if [[ ! -f "$ws_template" ]]; then
    emsg "Can't find template file: $ws_template"
    return 1
  fi

  if ! ask "Create \"$new_name\" @ ${new_home}?"; then
    echo "canceled."
    return 1
  fi

  _ws.new_workspace_sh "$new_name" > workspace.sh

  echo "$new_name created in $new_file."

  if ask "Enter $new_name?"; then
    ws.enter workspace.sh
    if ask "Add $new_name?"; then
      ws.add
    fi
  fi
}

## ws.enter (name/filename)
## Enter into a workspace. If (name/filename) is provided, it will be looked up
## in linked workspaces. If not, the workspace in the current dir will
## be used.
ws.enter()
{
  local possible_file

  if _ws.is_active; then
    emsg "Already in a workspace: $workspace"
    return 1
  fi

  # This will either resolve to the full path of a readable file or fail.
  if ! possible_file="$(_ws.resolve_file "$1")"; then
    emsg "Unable to resolve workspace from $1"
    return 1
  fi

  ws_file="$possible_file"
  ws_home="${ws_file%/*}"
  ws_funcs=()

  if ! {
    cd "$ws_home" &&
    source "$ws_file" &&
    test $workspace; # Tests if $workspace is not empty
  } ; then
    emsg \
      "Failed to enter workspace. Shell is probbably in a bad state" \
      "and should be closed. Note that workspace files must set \$workspace." \
      "Additional info:"
    ws.info >&2
    dmsg "Clearing workspace & ws_file"
    unset workspace
    unset ws_file
    unset ws_home
    return 1
  fi

  # Sourcing the file & running init seems to have gone OK.
  # Generate the list of magic functions
  ws_funcs=($(
    for funcname in $(declare -F | cut -c12- | grep "^${workspace}."); do
      echo "${funcname#*.}"
    done))

  # Project entry mapping
  alias ,=_ws.active
  complete -F _ws.tab_comp_active ,

  dmsg "ws_file=$ws_file, workspace=$workspace, ws_funcs=(${ws_funcs[@]})"

  ,,()
  {
    unset workspace
    if ws.enter "$ws_file"; then
      echo "Re-sourced ${ws_file}"
    else
      echo "Failed. Project may be in a broken state"
      return 1
    fi
  }
}

## ws.add
## Add a link to the active workspace in $ws_root
ws.add()
{
  if ! _ws.is_active; then
    emsg "Must be in an active workspace to add"
    return 1
  fi

  local linkname="${ws_root}/${workspace}.ws"

  dmsg "$ws_file -> $linkname"
  ln -s "$ws_file" "$linkname"
}

_ws.active()
{
  local cmd="$1"
  local norm_cmd="${workspace}.${cmd}"

  if [[ -z $cmd ]]; then
    cd "$ws_home"
    return
  fi

  shift 1

  if isfunc $norm_cmd; then
    ( cd "$ws_home"; $norm_cmd "$@"; )
  else
    echo "$cmd not found"
    return 1
  fi
}

_ws.inactive()
{
  if [[ "$1" == "new" ]]; then
    shift 1
    ws.new "$@"
  elif [[ "$1" == "add" ]]; then
    ws.add "$2"
  else
    ws.enter "$@"
  fi
}

_ws.is_active()
{
  test "$workspace"
}

_ws.ps1()
{
  if _ws.is_active; then
    ps1.add-part proj magenta "${workspace}"
  fi
}

_ws.tab_comp_inactive()
{
  # When not in a workspace, generate a list of known workspaces
  local cur
  local words

  cur=${COMP_WORDS[COMP_CWORD]}

  words=$(
  for file in ${ws_root}/*.ws; do
    f1="${file%.*}"
    echo "${f1##*/}"
  done)

  COMPREPLY=($(compgen -W "$words" -- $cur))
}

_ws.tab_comp_active()
{
  # Generate a list of forwarded functions for easy discovery
  local cur
  cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=()
  for cg in $(compgen -c -- "${workspace}.${cur}"); do
    COMPREPLY+=("${cg#*.}")
  done
}

# Resolve a token to an absolute file path of a file that exists
_ws.resolve_file()
{
  local c
  local candidates=()

  if [[ -z $1 ]]; then
    candidates=("${PWD}/workspace.sh")
  else
    candidates=(
      "$(path.resolve "${ws_root}/${1}.ws")"
      "$(path.abs "${1}/workspace.sh")"
      "$(path.abs "$1")"
    )
  fi

  dmsg "token=$1, candiates=(${candidates[@]})"
  for c in "${candidates[@]}"; do
    if [[ -f "$c" ]]; then
      echo "$c"
      return 0
    fi
  done

  return 1
}

_ws.new_workspace_sh()
{
  local name="$1"
  cat <<EOF
# workspace.sh // Common vars & operations

# This is designed to work with shtools^, but can be used without it by
# sourcing directly. Commands prefixed with '$name.' are meant to be
# run from the dir contaning this file.
# ^github.com/nepthar/shtools

# Name (required)
workspace="$name"

# Configuration
# my_variable=...

# Commands
# $name.run-test () {
#   ... run the tests ...
# }
EOF
}

alias ,=_ws.inactive
complete -F _ws.tab_comp_inactive ,
mkdir -p "$ws_root"
