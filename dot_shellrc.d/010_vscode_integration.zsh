# vscode zsh
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  for cmd in code cursor kiro antigravity; do
    if command -v "$cmd" >/dev/null 2>&1; then
      if [ -f "$($cmd --locate-shell-integration-path zsh)" ]; then
        . "$($cmd --locate-shell-integration-path zsh)"
        break
      fi
    fi
  done
fi
