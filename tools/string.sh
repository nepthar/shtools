# String Functions
# ----------------

readonly NEW_LINE=$'\n'

string.split()
{
  # split (-vVAR_NAME) [split token] "things to" split
  local arrname

  if [[ "$1" == "-v"* ]]; then
    arrname="${1#-v}"
    shift 1
  fi

  local split_on="$1"
  local split_array=()
  local old_ifs="$IFS"
  local line

  shift 1

  for arg in "$@"; do
    line="${arg//$split_on/$NEW_LINE}"
    IFS="$NEW_LINE"
    split_array+=($line)
    IFS="$old_ifs"
  done

  if [[ ! -z $arrname ]]; then
    eval "$arrname=(\"\${split_array[@]}\")"
  else
    for i in "${split_array[@]}"; do printf "%s\n" "$i"; done
  fi
}

string.join()
{
  # join [join token] (things to join)

  if [[ $# -eq 1 ]]; then
    R=''
    return
  fi

  local jstr="$1"
  local joined="$2"

  shift 2
  for token in "$@"; do joined="${joined}${jstr}${token}"; done
  R="$joined"
}

string.sub()
{
  local varname="$1"
  local to_replace="$2"
  local replace_with="$3"

  local new_var="${!varname}"
  new_var="${new_var//$to_replace/$replace_with}"

  eval "$varname=$new_var"
}


string.strip-margin()
{
  # Strip everything starting with a pipe, |, character on the left
  local aline
  _strip-line() { aline="$*"; printf "%s\n" "${aline#*|}"; }
  ARGPIPE_FUNC=_strip-line string.argpipe "$@"
  unset -f _strip-line
}

string.argpipe()
{
  # Take both stdin and arguments and run each "line" through ARGPIPE_FUNC.
  # The Default is printf
  # argpipe (arguments!)

  local default_func='printf %s\\n'
  local cmd="${ARGPIPE_FUNC:-$default_func}"
  local old_ifs="$IFS"
  local line
  local astr

  # Process stdin iff there's data already there.
  while read -t 0.01 line; do eval $cmd $line; done

  # Process arguments. Don't use a subshell (no pipes)
  string.join "$NEW_LINE" "$@"

  IFS="$NEW_LINE"
  local args=($R)
  IFS="$old_ifs"

  for line in "${args[@]}"; do eval $cmd $line; done
}

## Multiline read command. ALWAYS writes to READALL_REPLY
string.readall() {
  READALL_REPLY=$(</dev/stdin)
}