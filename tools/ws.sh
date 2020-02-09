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

# Current workspace information
export ws_name
export ws_funcs
export ws_file


_ws.ps1()
{
  if [[ ! -z "$ws_name" ]]; then
    ps1.add-part proj magenta "${ws_name}"
  fi
}

_ws.tab_comp_inactive()
{
  local cur
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
  local cur
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W "$ws_funcs" -- $cur))
}

## ws.ls
## List workspaces that ws knowns about
ws.ls()
{
  ls -alh "${ws_root}"/*.ws
}

## ws.new [name]
## Create a new workspace in the current folder with a given [name]
ws.new()
{
  if [[ -z $1 ]]; then
    emsg "Need a name for this new project"
    return 1
  fi

  if [[ -f workspace.sh ]]; then
    emsg "workspace.sh already exists"
    return 1
  fi

  if [[ ! -f "$ws_template" ]]; then
    emsg "Can't find template file: $ws_template"
    return 1
  fi

  local new_name="$1"
  local new_home="$PWD"

  if ! ask "Create \"$new_name\" @ ${new_home}?"; then
    echo "canceled."
    return 1
  fi

  py fill name="${new_name}" home="${new_home}" < "$ws_template" > workspace.sh

  echo "$new_name created in $new_file."
}

## ws.enter (name)
## Enter into a workspace. If (name) is provided, it will be looked up
## in linked workspaces. If not, the workspace in the current dir will
## be used.
ws.enter()
{
  local wsf
  local rc=0

  if [[ ! -z $ws_name ]]; then
    emsg "Already in a workspace: $ws_name"
    return 1
  fi

  if (( $# == 0 )); then
    wsf="${PWD}/workspace.sh"
  else
    wsf="${ws_root}/${1}.ws"
  fi

  if [[ ! -r "$wsf" ]]; then
    emsg "Couln't find workspace $1 @ $wsf"
    return 1
  fi

  if ! source "$wsf"; then emsg "Can't source $wsf"; rc=1; fi
  if [[ -z $ws_name ]]; then emsg "ws_name not set"; rc=1; fi
  if [[ ! -d $ws_home ]]; then emsg "Bad ws_home=${ws_home}"; rc=1; fi

  cd "$ws_home"

  # Only run the entry hook if it was defined
  if isfunc cmd.enter && ! cmd.enter; then
    emsg "cmd.enter failed"
    rc=1
  fi

  if (( rc != 0 )); then
    emsg "Shell is probably in a bad state and should be closed"
    return 1
  fi

  # Sourcing the file & running init seems to have gone OK.
  # Generate the list of magic functions
  ws_funcs=($(
    for funcname in $(declare -F | cut -c12- | grep ^cmd.); do
      echo "${funcname#cmd.}"
    done))

  # Project entry mapping
  export ws_file="$wsf"
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
  if [[ ! -f ./workspace.sh ]]; then
    emsg "No workspace.sh to link here"
    return 1
  fi

  local new_name="$(source ./workspace.sh && echo $ws_name)"
  if [[ -z $new_name ]]; then
    emsg "Problem with workspace.sh"
    return 1
  fi

  local linkname="${ws_root}/${new_name}.ws"

  if ask "Link workspace $new_name as ${linkname}?"; then
    ln -s "${PWD}/workspace.sh" "${linkname}"
  fi
}

## ws.exec [path] [cmd] (args...)
## Execute a [cmd] from the workspace at [path] in a subshell.
## The parent shell recieves the return code, but isn't effected.
ws.exec()
{
  if [[ -z "$ws_name" ]]; then
    local wd="$1"
    shift 1
    (
      cd "$wd"
      ws.enter && _ws.active "$@"
    )
  else
    emsg "ws.exec cannot be used from within an active workspace"
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
  # completion using the ',' special command. In the future, this might also
  # add some self-documenting help stuff

  local norm_cmd="cmd.${cmd}"

  shift 1

  if isfunc "$norm_cmd"; then
    "$norm_cmd" "$@"
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
