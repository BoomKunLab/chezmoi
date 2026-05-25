if (type codex > /dev/null 2>&1); then
    if [ -r "$HOME/.zsh/completions/_codex" ]; then
        case " ${fpath[*]} " in
            *" $HOME/.zsh/completions "*) ;;
            *) fpath=("$HOME/.zsh/completions" $fpath) ;;
        esac

        autoload -Uz compinit && compinit
    fi
fi
