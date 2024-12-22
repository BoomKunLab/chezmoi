# https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh
if [ -f ~/.git_util/git-prompt.sh ]; then
    source ~/.git_util/git-prompt.sh
fi

if [ -f ~/.git_util/_git ] && [ -f ~/.git_util/git-completion.bash ]; then
    fpath=(~/.zsh $fpath)
    zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
    autoload -Uz compinit && compinit
fi

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

setopt PROMPT_SUBST

PS1='%n: %F{cyan}%c%f %F{magenta}$(__git_ps1 "(%s)")%f\$ '
