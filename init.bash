# Shell Tools Initialization
# --------------------------
# Sets everything up and gives you dmsg and emsg (debug message and error message)
# If you want to spit something out that's neither of those, use echo :)
#
# Usage:
# In .bashrc/profile/similar:
#   source "path/to/init.bash" # This file.

# Some utilities shared with everything + messaging
isfunc() {
  declare -F "$1" &> /dev/null
}

ask() {
  local throwaway
  read -r -p "$* (Enter to continue, ctrl+c to cancel)" throwaway
}

if [[ -z "${SHELL_DEBUG}" ]]; then
  dmsg() {
    :;
  }
else
  dmsg() {
    local msg="$*"

    # Strip out full path
    local src="${BASH_SOURCE[1]##*/}"
    local fn="${FUNCNAME[1]}"
    local prefix="[${src}:${fn}]"

    if [[ "$prefix" == "[:]" ]]; then
      prefix=""
    fi

    echo -e "\033[30m${prefix} ${msg}\033[0m" >&2
  }
fi

emsg() {
  local msg="$*"

  # Strip out full path
  local src="${BASH_SOURCE[1]##*/}"
  local fn="${FUNCNAME[1]}"
  local prefix="[${src}:${fn}]"

  if [[ "$prefix" == "[:]" ]]; then
    prefix="[term?]"
  fi

  echo -e "\033[31m${prefix} error: ${msg}\033[0m" >&2
}

shtools() {
  echo "shtools_root:  $shtools_root"
  echo "shtools_setup: $shtools_setup"
  echo "shtools:       (${shtools[@]})"
}

if [[ ! -z $shtools_setup ]]; then
  dmsg "Skipping Shell tools due to shtools_setup being set"
elif (( BASH_VERSINFO[0] < 4 )); then
  dmsg "Skipping shell tools: Bash version < 4"
else

  setuptools() {
    export shtools=()
    export shtools_root="${1}"

    local tool_name
    local setup_fn
    local tool_dir="${shtools_root}/tools"

    if [[ ! -d "$shtools_root" ]]; then
      emsg "Can't find folder: $shtools_root"
      return 1
    fi

    dmsg "Setting up shell tools shtools_root=${shtools_root}"

    for tool in ${tool_dir}/*.sh; do
        if [[ -x $tool ]]; then
            dmsg "+ $tool"
            source $tool
            # If a _$tool.setup() function exists add it to the list.
            tool_name="${tool##*/}"
            tool_name="${tool_name%.sh}"
            shtools+=("$tool_name")
            setup_fn="_${tool_name}.setup"
            if isfunc "$setup_fn"; then
              tool_setups="$tool_setups $setup_fn"
            fi
        else
          dmsg "skip $tool"
        fi
    done

    # There is no guarantee about sourcing order of tools, so this
    # allows for running a command after all of the tools have been
    # sourced.
    dmsg "Running tool setup functions"
    for setup_fn in $tool_setups; do
      dmsg "-> $setup_fn"
      $setup_fn
    done

    export shtools_setup="Yup"
  }

  setuptools "${BASH_SOURCE[0]%/init.bash}"
  unset -f setuptools
fi
