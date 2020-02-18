# Untested Feb 2020
# Alert
# -----
# Monitor execution of a long-running command and send an alert when finished.

export alert_time_s="20"
export alert_group="terminal-alerts"
export alert_success="👍"
export alert_fail="💢"
export alert_success_sound="default"
export alert_fail_sound="Funk"
export alert_log_root="${HOME}/.config/log/alert"

export alert_pushover_url="https://api.pushover.net/1/messages.json"


if [[ -z $alert_pushover_token ]]; then
  emsg "Set \$alert_pushover_token if you wish to use alerts. If not, chmod -x alerts.sh"
fi

if [[ -z $alert_pushover_user ]]; then
  emsg "Set \$alert_pushover_user if you wish to use alerts. If not, chmod -x alerts.sh"
fi

# Log format is:
# timestamp,runtime,commandline
_alert-log-entry()
{
  local exec_time="$1"
  shift 1

  local cmd="$(basename $1)"
  shift 1

  local log_file="${alert_log_root}/${cmd}-runtimes.log"
  local date_pattern="+%s,${exec_time},$@"
  date "$date_pattern" >> "$log_file"
}

send-alert()
{
  return_code="$1"
  runtime_s="$2"
  exec_name="$3"
  shift 3

  rmsg="$alert_fail"
  sound="$alert_fail_sound"

  if [[ "$return_code" == "0" ]]; then
    rmsg="$alert_success"
    sound="$alert_success_sound"
  fi

  echo "$exec_name $@" | terminal-notifier \
    -title "$(basename $exec_name): $rmsg" \
    -subtitle "Runtime: ${runtime_s}s" \
    -group "$alert_group" \
    -sound "$sound" &> /dev/null
}

send-pushover-alert()
{
  return_code="$1"
  runtime_s="$2"
  exec_name="$3"
  shift 3

  rmsg="fail"
  sound="pushover"

  if [[ "$return_code" == "0" ]]; then
    rmsg="success"
    sound="cashregister"
  fi

  curl -s \
    --form-string "token=${alert_pushover_token}" \
    --form-string "user=${alert_pushover_user}" \
    --form-string "title=$rmsg - $(basename $exec_name) $@" \
    --form-string "message=${runtime_s}s" \
    --form-string "sound=$sound" \
    "$alert_pushover_url" &> /dev/null
}

alert()
{
  local start_time="$(date +%s)"

  "$@"

  local result="$?"
  local end_time="$(date +%s)"
  local total_time="$((end_time - start_time))"

  if ((total_time > alert_time_s)); then
    send-alert "$result" "$total_time" "$@"

    # If the screen saver is running, also send a remote alert
    if pgrep "ScreenSaverEngine" > /dev/null; then
      send-pushover-alert "$result" "$total_time" "$@"
    fi
  fi

  _alert-log-entry "$total_time" "$@"

  return $result
}

alert-fail()
{
  local start_time="$(date +%s)"

  "$@"

  local result="$?"
  local end_time="$(date +%s)"
  local total_time="$((end_time - start_time))"

  if ((result != 0 && total_time > alert_time_s)); then
    send-alert "$result" "$total_time" "$@"
  fi

  return $result
}
