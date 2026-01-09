

# ln -s "/Users/samuelfahim/Library/Mobile Documents/iCloud~md~obsidian/Documents/" ~/Obsidian
DISABLE_IMK=1
PROMPT='%~ %# '
set -o vi

# use `cd - ` to go back to the prev directory
alias icloud="cd '/Users/samuelfahim/Library/Mobile Documents/com~apple~CloudDocs' "
alias "note"="cd ~/Obsidian/second-brain/ && ./note.sh"
alias P="cd ~/Obsidian/second-brain &&  ./project.sh"
alias downloads="cd ~/Downloads"
alias guides="cd ~/guides/"
alias scratch="cd ~/Obsidian/second-brain/ && ./scratch.sh"
alias zshrc="nvim ~/.zshrc"
alias t="cd ~/Obsidian/second-brain/ && ./todo.sh"
alias brain="cd ~/Obsidian/second-brain && ./organize_brain.sh"
alias n='nvim'
alias track="rg --no-heading --color=always 'track::' "
alias p="cd ~/Obsidian/second-brain/protocols && ./protocols.sh "
alias secret='hdiutil attach ~/Obsidian/second-brain/secret.sparsebundle -stdinpass'
alias lock='cd ~ && hdiutil detach /Volumes/Secret'
alias clc="clear"
alias cls="clear"
alias py="python3"
alias start-venv="python3 -m venv venv && source venv/bin/activate"

alias door="echo 'This doesn't look like anything to me.''"

# Capture anywhere → 00_inbox/_capture.md
cap() {
  local root="$HOME/Obsidian/second-brain"
  local f="$root/00_inbox/_capture.md"
  local d line
  d=$(date '+%Y-%m-%d %H:%M')
  mkdir -p "$root/00_inbox"
  line="- [ ] $* "
  print -r -- "$line" >> "$f"
  print -r -- "$line"
}

# Capture to today's daily (create if missing)
ct() {
  local root="$HOME/Obsidian/second-brain"
  local daily="$root/10_daily/$(date '+%m.%d.%y').md"
  local d line
  d=$(date '+%Y-%m-%d %H:%M')

  mkdir -p "$root/10_daily"
  if [[ ! -f "$daily" ]]; then
    if [[ -f "$root/templates/daily.md" ]]; then
      cp "$root/templates/daily.md" "$daily"
    else
      print -r -- "# $(date '+%Y-%m-%d')" > "$daily"
      print -r -- "" >> "$daily"
      print -r -- "## Capture" >> "$daily"
      print -r -- "" >> "$daily"
    fi
  fi

  line="- [ ] $*  added:: $d"
  print -r -- "$line" >> "$daily"
  print -r -- "$line"
}

# Optional helpers to front-date in your preferred style
capd() {
  cap "$(date '+%m.%d.%y') -- $*"
}
ctd() {
  ct "$(date '+%m.%d.%y') -- $*"
}



# PATH
export PATH="$HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# STM32CubeMX
export STM32CubeMX_PATH="/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources"

# xPack ARM GCC (pick newest installed)
xpack_gcc="$(ls -d "$HOME/Library/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/"*/.content/bin 2>/dev/null | tail -n 1)"
if [[ -n "$xpack_gcc" ]]; then
  export PATH="$xpack_gcc:$PATH"
fi

# Homebrew (keep last so it always wins)
eval "$(/opt/homebrew/bin/brew shellenv)"
