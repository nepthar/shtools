# py
# --
# Use Python in shell commands, with a few tricks to speed things up. This adds
# ~25 ms of overhead vs ~50 ms of overhead for a standard python script
# invocation. I did this instead of modules beacuse they're just a headache.

export py_interpreter="/usr/local/bin/python3"
export py_path="${shtools_root}/tools/py"

# todo: disable gc

## py (cmd) [args...]
## Runs `py_path/cmd.py` with args in python3 with some helpful options set:
##  -I : isolate Python from the user's environment (implies -E and -s)
##  -E : ignore PYTHON* environment variables (such as PYTHONPATH)
##  -s : don't add user site directory to sys.path; also PYTHONNOUSERSITE
##  -S : don't imply 'import site' on initialization
##  -B : don't write .py[co] files on import; also PYTHONDONTWRITEBYTECODE=x
py() {
  local cmdfile="${py_path}/${1}.py"
  if [[ -f "$cmdfile" ]]; then
    shift 1
    "$py_interpreter" -I "$cmdfile" "$@"
    return $?
  else
    emsg "Command not found in $py_path"
    return 1
  fi
}

## py.cmd (cmd)
##
py.cmd()
{
  local cmd
  string.join -vcmd ";" "$@"
  "$py_interpreter" -IS -c "$cmd"
}
