# PS1 Enhancements!
# ----------------

# To add a new ps1 part:
# 1) Make a function that calls ps1.add-part "printf format" "printf args..."
# 2) Add it to the ordered $ps1_parts array
# 3) Complain about how overkill this system is.

_ps1.setup()
{
  export ps1_parts=(_ws.ps1 _git.ps1 _venv.ps1)
  export ps1_head="\n${tc_ps1_red}┌[${tc_ps1_reset}"
  export ps1_success="●"
  export ps1_fail="○"
  export ps1_tail=" ${tc_ps1_cyan}\w\n${tc_ps1_red}└ \A${tc_ps1_reset} ▶ "
  export ps1_sep=' '
  export ps1_body_start=''
  export ps1_body_end="${tc_ps1_red}]"

  export PROMPT_COMMAND=__prompt_command
}

## ps1.add-part color name part
## Won't use the color if it doesn't exist
ps1.add-part() {
  if (($# > 2)); then
    local name="$1"
    local cvar="tc_ps1_$2"
    shift 2
    ps1_rendered_parts+=("${!cvar}$@${tc_ps1_reset}")
    ps1_uncolored_parts+=("$name:$@")
  fi
}

__prompt_command()
{
  # Capture return code of previous command. Don't bother with PIPESTATUS here.
  local RC="$?"
  if ((RC == 0)); then
    PS1="${ps1_head}${ps1_success}"
  else
    PS1="${ps1_head}${ps1_fail}"
  fi

  # Assemble ps1
  ps1_rendered_parts=()
  ps1_uncolored_parts=()

  local ps1_body
  local body_join
  for func in "${ps1_parts[@]}"; do
    $func
  done

  if ((${#ps1_rendered_parts[@]} > 0)); then
    string.join "$ps1_sep" "${ps1_rendered_parts[@]}"
    ps1_body=" ${ps1_body_start}${R}${ps1_body_end}"
  else
    ps1_body="$ps1_body_end"
  fi

  # Gotta strip PS1 escape codes. FUCK.
  iterm.status "${ps1_uncolored_parts[@]}"
  PS1="${PS1}${ps1_body}${ps1_tail}"
}


# Should be in venv.sh, but meh.
_venv.ps1()
{
  if [[ ! -z $VIRTUAL_ENV ]]; then
    ps1.add-part venv blue "${VIRTUAL_ENV##*/}"
  fi
}
# ^^


ps1.debug()
{
  echo "Ps1 parts:"
  for func in "${ps1_parts[@]}"; do
    ps1_rendered_parts=()
    $func
    if [[ -z $ps1_rendered_parts ]]; then
      ps1_rendered_parts="-empty-"
    fi

    echo "$func: $ps1_rendered_parts"
  done

  echo "head: [$ps1_head]"
  echo "tail: [$ps1_tail]"
}