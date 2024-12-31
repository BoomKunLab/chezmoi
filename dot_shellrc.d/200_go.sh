# installed by asdf
if [ -d ~/.asdf/installs/golang ]; then
    export GOPATH=$(go env GOPATH)
    export PATH=$PATH:$GOPATH/bin
    # for version in $(ls ~/.asdf/installs/golang); do
    #     export PATH=$PATH:~/.asdf/installs/golang/$version/go/bin
    # done
fi

# installed by mise
if [ -d ~/.local/share/mise/installs/go ]; then
    export GOPATH=~/.go
    # export PATH=$PATH:$GOPATH/bin
    # for version in $(ls ~/.local/share/mise/installs/go); do
    #     export PATH=$PATH:~/.local/share/mise/installs/go/$version/bin
    # done
fi
