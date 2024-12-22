if [ -f "$GOPATH/bin/powerline-go" ]; then
    function _update_ps1() {
        # PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(jobs -p | wc -l))"
        PS1="$($GOPATH/bin/powerline-go -error $? -modules venv,ssh,cwd,git,hg,jobs,root -jobs $(jobs -p | wc -l))"

        # Uncomment the following line to automatically clear errors after showing
        # them once. This not only clears the error for powerline-go, but also for
        # everything else you run in that shell. Don't enable this if you're not
        # sure this is what you want.

        #set "?"
    }
fi

if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
