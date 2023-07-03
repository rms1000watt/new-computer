#! /usr/bin/env zsh

set -e

# MOVE DOTFILES
cp .gitconfig ~/.gitconfig
mkdir ~/.ssh &> /dev/null ||:
cp .ssh-config ~/.ssh/config
cp .tool-versions ~/.tool-versions
cp .zshrc ~/.zshrc

# INSTALL BREW
if ! type -a brew > /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# INSTALL BREW LIBS
brew tap homebrew/cask-versions
brew install $(cat libs.brew-cli | tr '\n' ' ')
brew install --cask $(cat libs.brew-cask | tr '\n' ' ')

# ADD VSCODE CONFIG (required after brew casks)
if [[ ! -d "$HOME/Library/Application Support/Code/User" ]]; then 
  mkdir "$HOME/Library/Application Support/Code/User"
fi

cp configs.vscode.json "$HOME/Library/Application Support/Code/User/settings.json"

# CONFIGURE ZSH & SHELL
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! grep -q '/opt/homebrew/bin/zsh' /etc/shells; then
    echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells
  fi

  if [[ "$SHELL" != "/opt/homebrew/bin/zsh" ]]; then
    chsh -s /opt/homebrew/bin/zsh
  fi
elif [[ "$(uname -m)" == "x86_64" ]]; then
  if ! grep -q '/usr/local/bin/zsh' /etc/shells; then
    echo '/usr/local/bin/zsh' | sudo tee -a /etc/shells
  fi

  if [[ "$SHELL" != "/usr/local/bin/zsh" ]]; then
    chsh -s /usr/local/bin/zsh
  fi
else
  echo "ERROR: uname -m didn't output a proper value"
  exit 1
fi

if ! [[ -d ~/.oh-my-zsh ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# INSTALL ASDF LIBS
while read -r plugin; do
  asdf plugin add "${plugin}" ||:
done < <(cut -d' ' -f1 < ~/.tool-versions)

asdf install

# INSTALL VS CODE LIBS
# Exported via: code --list-extensions
while read -r plugin; do
  code --install-extension "${plugin}"
done < libs.vscode

# CONFIGURE FINDER
if [[ "$(defaults read com.apple.Finder AppleShowAllFiles)" != "true" ]]; then
  defaults write com.apple.Finder AppleShowAllFiles true
  killall Finder
fi

# SSH STUFF
if [[ ! -f ~/.ssh/id_rsa_gmail ]]; then
  ssh-keygen -t rsa -b 4096 -C "rms1000watt@gmail.com" -f ~/.ssh/id_rsa_gmail
fi

# GPG STUFF
if [[ ! -f ~/.gnupg/pubring.kbx ]]; then
  gpg --generate-key
fi

echo "
## Manual System Preferences
- Keyboard: Key Repeat=fastest, Delay Until Repeat=shortest
- Keyboard: Disable use smart quotes and dashes
- Displays: Adjust resolution by 1
- Mission Control: Disable automatically rearrange spaces based on most recent use
- Docker: Preference update RAM to 8GB & Disable experimental features
- Terminal stuff: terminal.md
- Dock: Depress show recent applications in dock
- Finder: Preferences > Advanced > show all file extensions
- Finder: Show > Show Path Bar

## Github
- Upload the new ssh public key into github

## I got too lazy...
- Install... https://github.com/yujitach/MenuMeters --> https://github.com/yujitach/MenuMeters/releases

## Divvy Settings:
- System Preferences > Security & Privacy > Privacy > Accessibility > Allow divvy
- Select Use global shortcut to display panel and set it to: control + option + space
- 10x10 grid

## Menu Meters Settings
- Network: Throughput + Depress show throughput values
- CPU: Total (medium) + Percentage
- Memory: Used Free Totals + Depress show use/free labels

## Chrome extension
- Ghostery
- lastpass
- authenticator
- aws-extend-switch-roles

## App Store
- amphetamine

## Startup Apps
- Users & Groups
- Select User
- Login Items tab
- Add:
  - Amphetamine
  - Bartender
  - Divvy
  - Menumeters
"
