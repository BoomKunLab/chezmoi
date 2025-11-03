# mise installed by brew on bash
if [ -f $HOMEBREW_PREFIX/bin/mise ]; then
    eval "$(mise activate bash)"
    # source <(mise completion bash)
fi

# mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise
