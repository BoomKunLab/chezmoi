# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# less
export LESS='-i -M -R'

if [ -d "$HOME/.managed/bin" ] ; then
    PATH="$HOME/.managed/bin:$PATH"
fi
