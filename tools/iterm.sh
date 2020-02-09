# iterm.sh ~ iterm integration without installing it
# There's so much there. Latest copy of the actual shell integ can be found here:
# https://iterm2.com/shell_integration/bash

export iterm2_begin_osc="\033]"
export iterm2_end_osc="\007"


## iterm.status (new status)
## Set the iterm status to `new status`. Useful for the mbp touch bar.
iterm.status() {
  local things="$@"
  printf "\033]1337;SetKeyLabel=status=%s\a" "$things"
}

iterm.osc() {
  printf "$iterm2_begin_osc"
  printf "$@"
  printf "$iterm2_end_osc"
}

# iterm.printStateData() {
#   iterm.osc "1337;RemoteHost=%s@%s" "$USER" "$hostname"
#   iterm.osc "1337;CurrentDir=%s" "$PWD"
# }