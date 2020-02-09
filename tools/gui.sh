# GUI
# ---
# Tools for GUI popups, etc. (osx only)

## gui.prompt [Prompt text] (default value) (timeout)
## Prompts the user for an answer, writes the result to stdout. Optionally,
## a default value and a timeout can be specified. The default value will be
## returned if the timeout is reached.
gui.prompt() {
  local prompt="$1"
  local default="$2"

  if [[ ! -z "$3" ]]; then
    local giveup="giving up after $3"
  else
    local giveup=""
  fi

  osascript <<EOF
  tell application "System Events"
    display dialog "$prompt" default answer "$default" default button "OK" $giveup
    set ret to text returned of result
  end tell

  ret
EOF
}

## gui.popup [title] [text]
## Make a simple popup & block until the user acknowledges.
gui.popup()
{
  local title="$1"
  local text="$2"
  osascript > /dev/null <<EOF
  tell application "System Events"
    display dialog "$text" buttons { "OK" } default button "OK" with title "$title"
  end tell
EOF
}
