# String Functions
# ----------------

readonly NEW_LINE=$'\n'


# string.split()
# {
#   # split (-vVAR_NAME) [split token] "things to" split
#   local arrname

#   if [[ "$1" == "-v"* ]]; then
#     arrname="${1#-v}"
#     shift 1
#   fi

#   local split_on="$1"
#   local split_array=()
#   local old_ifs="$IFS"
#   local line

#   shift 1

#   for arg in "$@"; do
#     line="${arg//$split_on/$NEW_LINE}"
#     IFS="$NEW_LINE"
#     split_array+=($line)
#     IFS="$old_ifs"
#   done

#   if [[ ! -z $arrname ]]; then
#     eval "$arrname=(\"\${split_array[@]}\")"
#   else
#     for i in "${split_array[@]}"; do printf "%s\n" "$i"; done
#   fi
# }

# join -vVAR_NAME [join token] (things to join)
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