if [ -f $HOMEBREW_PREFIX/bin/starship ]; then
    eval "$(starship init bash)"
    export STARSHIP_CONFIG=~/.config/starship/bash/starship.toml
fi
