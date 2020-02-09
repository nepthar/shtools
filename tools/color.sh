# ANSI terminal color setup
# -------------------------

# Map of name -> tput args to generate code
color_tab=(
  # Normal Colors
  'black      setaf 0'
  'red        setaf 1'
  'green      setaf 2'
  'yellow     setaf 3'
  'blue       setaf 4'
  'magenta    setaf 5'
  'cyan       setaf 6'
  'white      setaf 7'

  # Bright Colors
  'bblack     setaf 8'
  'bred       setaf 9'
  'bgreen     setaf 10'
  'byellow    setaf 11'
  'bblue      setaf 12'
  'bmagenta   setaf 13'
  'bcyan      setaf 14'
  'bwhite     setaf 15'

  # Modifiers
  'bold       bold'
  'ul         smul'
  'reset      sgr0'
)

_color.export_var()
{
  local name="$1"
  shift 1
  local color="$(tput $@)"

  export "tc_${name}=${color}"

  # For PS1, we wrap the color command with brackets so it isn't counted towards
  # the character count.
  export "tc_ps1_${name}=\[${color}\]"
}

_color.demo_color()
{
  local name="$1"
  local vname="tc_${name}"
  local color="${!vname}"
  printf "%-16s %s%-16s%s\n" "\$$vname" "$color" "$name" "$tc_reset"
}

color.vars()
{
  echo "Available color modifiers:"
  for line in "${color_tab[@]}"; do
    _color.demo_color $line
  done
  echo "For use in PS1, colors are prefixed with 'tc_ps1_'"
}

color.demo-256()
{
  # generates an 8 bit color table (256 colors) for reference,
  # using the ANSI CSI+SGR \033[48;5;${val}m for background and
  # \033[38;5;${val}m for text (see "ANSI Code" on Wikipedia)

  echo -en "\n   +  "
  for i in {0..35}; do
    printf "%2b " $i
  done

  printf "\n\n %3b  " 0
  for i in {0..15}; do
    echo -en "\033[48;5;${i}m  \033[m "
  done
  #for i in 16 52 88 124 160 196 232; do
  for i in {0..6}; do
    let "i = i*36 +16"
    printf "\n\n %3b  " $i
    for j in {0..35}; do
      let "val = i+j"
      echo -en "\033[48;5;${val}m  \033[m "
    done
  done
  echo -e "\n"
}

color.echo()
{
  local vname="tc_$1"
  local color="${!vname}"

  shift 1
  printf "${color}%s${tc_reset}\n" "$@"
}

if [[ -z $tc_colors_setup ]]; then
  dmsg "Exporting colors"
  for line in "${color_tab[@]}"; do
    _color.export_var $line
  done
  export tc_colors_setup="yep yep"
else
  dmsg "Colors have already been setup. Skipping"
fi
