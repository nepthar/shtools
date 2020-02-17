# ws.sh
# -----
# Shell workspaces. Easy peasy. Uses virtualevn as inspiration. Sort of.

# The humble comma (,) is abused as a shortcut for various things.

# Create a new workspace:
# 1) $ cd ~/my/workspace/primary/folter
# 2) $ , new [workspace name]

# Start working in a workspace:
# 1) $ , [workspace name]
#   -  Tab completion works for selecting a workspace. Woohoo.
#   -  The command (,) by itself will return you to the workspace's home

# Finish working in a workspace:
# 1) Close the shell. There's no "exiting"

# Configuration
export ws_root="${shtools_root}/workspaces"
export ws_template="${ws_root}/workspace.sh.skel"
export ws_inactive="<!NO_WORKSPACE!>"
export ws_name="$ws_inactive"
export ws_home="$ws_inactive"
export ws_funcs=()
export ws_file=$ws_inactive


_ws.isActive()
{
  [[ "$ws_name" != "$ws_inactive" ]]
}

_ws.ps1()
{
  if _ws.isActive; then
    ps1.add-part proj magenta "${ws_name}"
  fi
}

_ws.tab_comp_inactive()
{
  local cur
  local words

  cur=${COMP_WORDS[COMP_CWORD]}

  # Subshell in a tab comp isn't ideal. We strive for speed. Perhaps
  # fix this later.
  words=$(
  for file in ${ws_root}/*.ws; do
    f1="${file%.*}"
    echo "${f1##*/}"
  done)

  COMPREPLY=($(compgen -W "$words" -- $cur))
}

_ws.tab_comp_active()
{
  local cur
  cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=()
  for cg in $(compgen -c -- "${ws_name}.${cur}"); do
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

ws.debug()
{
  local hPart
  local fPart

  if [[ -f "$ws_file" ]]; then fPart="found"; else fPart="not found"; fi
  if [[ -d "$ws_home" ]]; then hPart="found"; else hPart="not found"; fi

  echo "ws_name   $ws_name"
  echo "ws_home   $ws_home ($hPart)"
  echo "ws_file   $ws_file ($fPart)"
  echo "ws_funcs  (${ws_funcs[@]})"
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

  py fill name="${new_name}" home="${new_home}" < "$ws_template" > workspace.sh

  echo "$new_name created in $new_file."
}

## ws.enter (name/filename)
## Enter into a workspace. If (name/filename) is provided, it will be looked up
## in linked workspaces. If not, the workspace in the current dir will
## be used.
ws.enter()
{
  local possible_file

  if _ws.isActive; then
    emsg "Already in a workspace: $ws_name"
    return 1
  fi

  # This will either resolve to the full path of a readable file or fail.
  if ! possible_file="$(_ws.resolve_file "$1")"; then
    emsg "Unable to resolve workspace from $1"
    return 1
  fi

  ws_file="$possible_file"
  ws_home="${ws_file%/*}"

  if ! {
    cd "$ws_home" &&
    source "$ws_file" &&
    test "$ws_name" != "$ws_inactive"
  } ; then
    emsg \
      "Failed to enter workspace. Shell is probbably in a bad state" \
      "and should be closed. Note that workspace files must set \$ws_name." \
      "Additional info:"
    ws.debug >&2
    ws_name="<Bad workspace state, close this terminal>"
    return 1
  fi

  # Sourcing the file & running init seems to have gone OK.
  # Generate the list of magic functions
  ws_funcs=($(
    for funcname in $(declare -F | cut -c12- | grep "^${ws_name}."); do
      echo "${funcname#*.}"
    done))

  # Project entry mapping
  alias ,=_ws.active
  complete -F _ws.tab_comp_active ,

  dmsg "ws_file=$ws_file, ws_name=$ws_name, ws_funcs=(${ws_funcs[@]})"

  ,,()
  {
    if source "$ws_file"; then
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
  if ! _ws.isActive; then
    emsg "Must be in an active workspace to add"
    return 1
  fi

  local linkname="${ws_root}/${ws_name}.ws"
  if ask "Link workspace $ws_name as ${linkname}?"; then
    ln -s "${ws_file}" "${linkname}"
  fi
}

## ws.exec [path] [cmd] (args...)
## Execute a [cmd] from the workspace at [path] in a subshell.
## The parent shell recieves the return code, but isn't effected.
ws.exec()
{
  if ! _ws.isActive; then
    local wd="$1"
    shift 1
    (cd "$wd" && ws.enter && eval "$@" )
  else
    emsg "cannot be used from within an active workspace"
    return 1
  fi
}

_ws.active()
{
  local cmd="$1"
  if [[ -z $cmd ]]; then
    cd "$ws_home"
    return
  fi

  # Command forwarding
  # We make "shortuct" commands which can be defined in the project files as
  # cmd.{command name}. This allows for making commands that don't
  # conflict with the global command namespace and can be listed via tab
  # completion using the ',' special command.
  #
  # They also run in a subshell from $ws_home with eu/pipefail.
  # if you don't want this behavior, just define regular functions in the
  # workspace file.bash

  local norm_cmd="${ws_name}.${cmd}"

  shift 1

  if isfunc $norm_cmd; then
    (
      cd "$ws_home"
      set -euo pipefail
      $norm_cmd "$@"
    )
  else
    echo "$cmd not found"
    return 1
  fi
}

_ws.inactive()
{
  if [[ "$1" == "new" ]]; then
    shift 1
    ws.new "$@" && ws.add
  elif [[ "$1" == "link" ]]; then
    ws.add "$2"
  else
    ws.enter "$@"
  fi
}

_ws.setup()
{
  alias ,=_ws.inactive
  complete -F _ws.tab_comp_inactive ,
}
