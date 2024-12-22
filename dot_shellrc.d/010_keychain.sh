# ssh-keychain
if [ -f /usr/bin/keychain ]; then
    /usr/bin/keychain -q --nogui $HOME/.ssh/id_rsa_bastion
    source $HOME/.keychain/`uname -n`-sh
fi
