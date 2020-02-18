# String Functions
# ----------------

NEW_LINE=$'\n'
RecordSeparator=$'\x1E'

split_reply=()


## string.split [token] [string]
## Splits the given string by the token. Puts the result in
## split_reply
string.split()
{
  split_reply=()

  if (( $# != 2 )); then
    emsg "string.split [token] [string]"
    return 1
  fi

  IFS="$RecordSeparator" split_reply=($splits)
}

## string.join (-vVAR_NAME) [join token] (things to join)
## Joins all of the things to join with join token. If -vVAR_NAME is
## specificed, writes it out to that var
string.join()
{
  if (( $# < 2 )); then
    emsg "join (-vVAR_NAME) [join token] (things to join...)"
    return 1
  fi

  local printfArg
  local jstr
  local joined
  local token

  if [[ "$1" == "-v"* ]]; then
    printfArg="$1"
    shift 1
  fi

  jstr="$1"
  joined="$2"

  shift 2
  for token in "$@"; do joined="${joined}${jstr}${token}"; done

  printf $printfArg "$joined"
}

## Multiline read command. ALWAYS writes to READALL_REPLY
string.readall() {
  READALL_REPLY=$(</dev/stdin)
}