#! /usr/bin/env zsh

# MOVE DOTFILES
# TODO

# INSTALL BREW
if ! type -a brew > /dev/null; then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# INSTALL BREW LIBS
brew tap homebrew/cask-versions
brew install $(cat libs.brew-cli | tr '\n' ' ')
brew install --cask $(cat libs.brew-cask | tr '\n' ' ')

# CONFIGURE ZSH & SHELL
if [[ "$(uname -m)" == "arm64" ]]; then
	if ! grep -q '/opt/homebrew/bin/zsh' /etc/shells; then
		echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells
	fi

	if [[ "$SHELL" != "/opt/homebrew/bin/zsh" ]]; then
		chsh -s /opt/homebrew/bin/zsh
	fi
else
	if ! grep -q '/usr/local/bin/zsh' /etc/shells; then
		echo '/usr/local/bin/zsh' | sudo tee -a /etc/shells
	fi

	if [[ "$SHELL" != "/usr/local/bin/zsh" ]]; then
		chsh -s /usr/local/bin/zsh
	fi
fi

if ! [[ -d ~/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# INSTALL ASDF LIBS
while read -r plugin; do
	asdf plugin add "${plugin}"
done < <(cut -d' ' -f1 < ~/.tool-versions)

asdf install

# INSTALL VS CODE LIBS
# Exported via: code --list-extensions | tr '\n' ' ' | pbcopy
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
## Manual Stuff
- Keyboard: Key Repeat=fastest, Delay Until Repeat=shortest
- Keyboard: Disable use smart quotes and dashes
- Displays: Adjust resolution by 1
- Mission Control: Disable automatically rearrange spaces based on most recent use
- Docker: Preference update RAM to 8GB & Disable experimental features
- Terminal stuff: terminal.md
- Dock: Depress show recent applications in dock
- Finder: Preferences > Advanced > show all file extensions

## I got too lazy...
- Install... https://github.com/yujitach/MenuMeters --> https://github.com/yujitach/MenuMeters/releases

## Divvy Settings:
- System Preferences > Security & Privacy > Privacy > Accessibility > Allow divvy
- Select Use global shortcut to display panel and set it to: control + option + space

## Menu Meters Settings
- Network: Throughput + Depress show throughput values
- CPU: Total (medium) + Percentage
- Memory: Used Free Totals + Depress show use/free labels

## Chrome extension
- Ghostery
- lastpass
- authenticator

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
