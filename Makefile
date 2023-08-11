define CLI_TOOLS_LIST
wget
vim
bottom
rnr
rm-improved
procs
exa
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
the-unarchiver
warp
docker
ultimaker-cura
freecad
telegram-desktop
postman
folx
scansion
hex-fiend
visual-studio-code
ipfs
gcc-arm-embedded
endef
export CASK_LIST

all: install-vpn config-vpn config-rust config-go install-agda config-zsh config-git config-vscode config-docker config-browser
	echo "Done!"

prepare: encode-secrets
	git add .
	git commit -m "$(shell date)"
	git push
	echo "Done!"

install-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup-init.sh
	bash /tmp/rustup-init.sh -y

config-rust: install-rust
	cp ./cargo/config.toml ~/.cargo/

install-go:
	bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
	gvm install $(gvm listall | grep "go\d+\\.\d+$" | tail -1)

config-go: install-go
	gvm use $(gvm listall | grep "go\d+\\.\d+$" | tail -1) --default
	go env -w GOPROXY=https://goproxy.cn,direct

install-agda:
	curl -sSL https://get.haskellstack.org/ | sh
	stack install agda

install-brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/install-brew.sh
	bash /tmp/install-brew.sh

config-brew: install-brew
	cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"; \
	git remote set-url origin https://mirrors.sjtug.sjtu.edu.cn/git/homebrew-core.git
	cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask; \
	git remote set-url origin https://mirrors.sjtug.sjtu.edu.cn/git/homebrew-cask.git
	brew update

install-cli-tools: config-brew
	brew install parallel
	echo "$$CLI_TOOLS_LIST" | parallel brew fetch --deps
	echo "$$CLI_TOOLS_LIST" | xargs brew install

config-zsh: install-cli-tools
	miniserve --print-completions zsh > /usr/local/share/zsh/site-functions/_miniserve
	cp ./zsh/alias.zsh $ZSH_CUSTOM/

config-git: decode-secrets
	git config --global user.email "longfangsong@icloud.com"
	git config --global user.name "longfangsong"
	git config --global credential.helper "osxkeychain"
	git config --global init.defaultBranch "main"

install-casks: config-brew
	echo "$$CASK_LIST" | xargs brew install --cask 

config-docker: install-casks decode-secrets
	cat ~/docker_password.txt | docker login --username longfangsong --password-stdin

config-browser: install-casks decode-secrets
	rm -rf /Users/longfangsong/Library/Application\ Support/Firefox
	mv ./Firefox /Users/longfangsong/Library/Application\ Support/

install-vpn:
	unzip ShadowsocksX-NG.zip
	rm -rf ./__MACOSX
	mv -r ./ShadowsocksX-NG.app /Applications/

config-vpn: install-vpn decode-secrets
	cp -r ./com.qiuyuzhou.ShadowsocksX-NG.plist ~/Library/Preferences/

collect-config:
	zip $(shell pwd)/Firefox.zip /Users/longfangsong/Library/Application\ Support/Firefox
	cp ~/Library/Preferences/com.qiuyuzhou.ShadowsocksX-NG.plist .

encode-secrets: collect-config
	openssl rand -base64 -out $(shell pwd)/aes256_password.txt 32
	openssl enc -e -aes256 -pass file:$(shell pwd)/aes256_password.txt -in Firefox.zip -out Firefox.zip.enc
	ls $(shell pwd)/*.txt | xargs -n 1 -I "{}" openssl enc -e -aes256 -pass file:./aes256_password.txt -in {} -out {}.enc
	ls $(shell pwd)/*.plist | xargs -n 1 -I "{}" openssl enc -e -aes256 -pass file:./aes256_password.txt -in {} -out {}.enc
	openssl pkeyutl -encrypt -inkey public.pem -pubin -in $(shell pwd)/aes256_password.txt -out $(shell pwd)/aes256_password.txt.enc

decode-secrets:
	openssl pkeyutl -decrypt -inkey private.pem -in $(shell pwd)/aes256_password.txt.enc > $(shell pwd)/aes256_password.txt
	ls $(shell pwd)/*.enc | rev | cut -c5- | rev | xargs -n 1 -I "{}" openssl enc -d -aes256 -pass file:./aes256_password.txt -in {}.enc -out {}
