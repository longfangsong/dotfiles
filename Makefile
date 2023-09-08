define CLI_TOOLS_LIST
wget
vim
bottom
rnr
rm-improved
procs
eza
hexyl
helix
fd
git-delta
bat
zoxide
sk
miniserve
open-ocd
openssl
endef
export CLI_TOOLS_LIST

define CASK_LIST
firefox
keka
warp
orbstack
ultimaker-cura
freecad
telegram-desktop
postman
folx
scansion
hex-fiend
visual-studio-code
gcc-arm-embedded
endef
export CASK_LIST

all: install-rust install-agda config-zsh config-git config-browser
	echo "Done!"

prepare: encode-secrets
	git add .
	git commit -m "$(shell date)"
	git push
	echo "Done!"

install-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

install-agda:
	curl -sSL https://get.haskellstack.org/ | sh
	stack install agda

install-brew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

config-brew: install-brew
	brew update

install-cli-tools: config-brew
	brew install parallel
	echo "$$CLI_TOOLS_LIST" | parallel brew fetch --deps
	echo "$$CLI_TOOLS_LIST" | xargs brew install

config-zsh: install-cli-tools
	cp ./zsh/alias.zsh $ZSH_CUSTOM/

config-git: decode-secrets
	git config --global user.email "longfangsong@icloud.com"
	git config --global user.name "longfangsong"
	git config --global credential.helper "osxkeychain"
	git config --global init.defaultBranch "main"

install-casks: config-brew
	echo "$$CASK_LIST" | xargs brew install --cask 

config-browser: install-casks decode-secrets
	rm -rf /Users/longfangsong/Library/Application\ Support/Firefox
	mv ./Firefox /Users/longfangsong/Library/Application\ Support/

collect-config:
	zip $(shell pwd)/Firefox.zip /Users/longfangsong/Library/Application\ Support/Firefox

encode-secrets: collect-config
	openssl rand -base64 -out $(shell pwd)/aes256_password.txt 32
	openssl enc -e -aes256 -pass file:$(shell pwd)/aes256_password.txt -in Firefox.zip -out Firefox.zip.enc
	openssl pkeyutl -encrypt -inkey public.pem -pubin -in $(shell pwd)/aes256_password.txt -out $(shell pwd)/aes256_password.txt.enc

decode-secrets:
	openssl pkeyutl -decrypt -inkey private.pem -in $(shell pwd)/aes256_password.txt.enc > $(shell pwd)/aes256_password.txt
	ls $(shell pwd)/*.enc | rev | cut -c5- | rev | xargs -n 1 -I "{}" openssl enc -d -aes256 -pass file:./aes256_password.txt -in {}.enc -out {}
