# installed by asdf
if [ -d ~/.asdf/installs/golang ]; then
    export GOPATH=$(go env GOPATH)
    export PATH=$PATH:$GOPATH/bin
    # for version in $(ls ~/.asdf/installs/golang); do
    #     export PATH=$PATH:~/.asdf/installs/golang/$version/go/bin
    # done
fi
