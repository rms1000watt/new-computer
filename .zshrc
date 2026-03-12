export PATH=$HOME/bin:/usr/local/bin:/opt/homebrew/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
DISABLE_MAGIC_FUNCTIONS="true"
plugins=(git)
source $ZSH/oh-my-zsh.sh

export PATH=$PATH:/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
eval "$(direnv hook zsh)"
export TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugins
RPROMPT="[%D{%L:%M:%S}]"
go env -w CGO_LDFLAGS="-O2 -w -s -extldflags -static"
export PATH="/usr/local/sbin:$PATH"

export GOPATH=$HOME/go
export CGO_ENABLED=0
export PATH=$PATH:$GOPATH/bin
export GITHUB=$GOPATH/src/github.com
export EDITOR="subl -wn"

mkdir ~/.nvm 2> /dev/null ||:

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

alias unset-aws="unset AWS_ACCESS_KEY_ID && unset AWS_SECRET_ACCESS_KEY && unset AWS_SESSION_TOKEN && unset AWS_EXPIRY"
alias oc="opencode"
