# Path
# ----
# Path-related tools. Relies on a python helper

## path.which (target)
## Attempts to resolve target in the style of `which`, but also resolves functions
path.which()
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

## path.abspath [args...]
## Resolves the absolute path of all `args`, not following links
path.abs()
{
  py path "$@"
}

## path.resolve [args...]
## Resolves the absolute path of all `args`, following links
path.resolve()
{
  py path -c "$@"
}

## path (target)
## Dump the current $PATH in search order. If `target` is specified, it will
## search for it in all paths, dumping any that it finds.
## returns 0 unless `target` is specified and not found anywhere.
path()
{
  local target="$1"
  local rc=1
  local path

  IFS=':' path=($PATH)

  if [[ -z "$target" ]]; then
    # This preserves ordering. If we just pass the parts to ls, it will re-order them.
    # Even if we pass the '-f' flag (unordered), missing path parts will be listed at the start.
    for p in "${path[@]}"; do
      if [[ -d "$p" ]]; then
        ls -ld "$p"
      else
        echo "not found ${tc_red}${p}${tc_reset}"
      fi
    done
    rc=0
  else
    local paths=()
    local to_test
    for p in "${path[@]}"; do
      to_test="${p}/${target}"
      if [[ -x "$to_test" ]]; then
        rc=0
        paths+=("$to_test")
      fi
    done
    printf "%s\n" "${paths[@]}"
  fi
  return $rc
}
