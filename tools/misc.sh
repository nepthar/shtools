# Make a new random mac address and set it
mac-gen()
{
  openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'
}

# Screen saver
# ss()
# {
#   '/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine'
# }

# For splitting purposes:
#   IFS=':' command eval 'local -a paths=($py_path)'


fs_date_stamp()
{
    date '+%F_%H-%M-%S'
}

mac-set()
{
  device="en0"

  if [[ -z $1 ]]; then
    new_addr=$(mac-gen)
  else
    new_addr=$1
  fi

  echo "Setting mac address to: $new_addr"
  sudo ifconfig $device ether $new_addr

  echo "Updated address is:"
  ifconfig $device | grep ether
}

lw()
{
  local prg
  local output
  local -a lsarray
  prg=$( which $1 )
  if [[ "$prg" == "" ]]; then
    type $1 2>/dev/null || echo "$1 not found"
  else
    lsarray=($(ls -alh $prg))
    output="$prg"
    while [[ -s "${lsarray[10]}" ]]; do
      output="$output -> ${lsarray[10]}"
      lsarray=($(ls -alh "${lsarray[10]}"))
    done
    echo $output
  fi
}

# curry()
# {
#   local name="$1"
#   local func="$2"
#   shift 2
#   local args="$*"
#   cmd=$"$name () { $func $args \"\$@\"; }"
#   eval $cmd
# }

# Blow away the old environment and make a brand new shell
reshell()
{
  exec login -f $USER
}
