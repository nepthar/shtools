# poll.sh
# Run a command every x seconds and perform actions based on the outcome

export poll_interval_s=10

# Run poll_func repeatedly and silently until it succeeds.

# Poll_func Return Code Behavior
#  +Return Code of poll_func
#  |   +Interpretation
#  |   |                    +Return code of poll
#  |   |                    |  + Callback action
#  v   v                    v  v
#  0   Success              0  $on_success [start time] [poll counter] [cmd] (args..)
#  1   Continue             -  -
#  2   Continue w/Callback  -  $on_continue [start time] [poll counter] [cmd] (args..)
#  3   Fail silent          1  -
#  *   Fail w/Callback      *  $on_fail [start time] [poll counter] [cmd] (args...)


poll()
{
  local on_success="${on_success-true}"
  local on_failure="${on_failure-true}"
  local on_continue="${on_continue-true}"

  local start_time_s="$(date +%s)"
  local rc
  local poll_counter=0

  while true; do
    let poll_counter++

    dmsg "polling: $@"
    eval "$@"
    rc=$?

    dmsg "poll rc: $rc"
    case $rc in
      0) eval $on_success $start_time_s $poll_counter "$@"; return 0; ;;
      1) true; ;;
      2) eval $on_continue $start_time_s $poll_counter "$@"; ;;
      3) return 1; ;;
      *) eval $on_failure $start_time_s $poll_counter "$@"; return 1; ;;
    esac

    sleep $poll_interval_s
  done
}


poll-test()
{
  on_success='echo success $@' poll "test -e $HOME/temp/poll_thing"
}