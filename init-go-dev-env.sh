#!/bin/bash
# 功能：UOS/deepin V20 系统初始化go开发环境，适合 dde-daemon 等项目开发。

# git config
GIT_USER_NAME="${GIT_USER_NAME:-electricface}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-songwentai@uniontech.com}"

if ! command -v git &> /dev/null; then
    echo "git not found, installing..."
    sudo apt install -y git
else
    echo "git is already installed"
fi

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global gitreview.remote origin
git config --global gitreview.scheme ssh

# install vfox if not installed
if ! command -v vfox &> /dev/null; then
    echo "vfox not found, installing..."
    echo "deb [trusted=yes lang=none] https://apt.fury.io/versionfox/ /" | sudo tee /etc/apt/sources.list.d/versionfox.list
    sudo apt-get update
    sudo apt-get install -y vfox
    echo "vfox installed successfully"
else
    echo "vfox is already installed"
fi

echo 'eval "$(vfox activate bash)"' >> ~/.bashrc
source ~/.bashrc

# install golang
vfox add golang
#vfox search golang
vfox install golang@1.24.6
vfox use golang@1.24.6


# install gopls golang language server
export GO111MODULE=on
export GOBIN=$HOME/go/bin
export GOPROXY=https://goproxy.cn,direct
go version
GO_ELF_FILE=$(realpath "$(which go)")
go install -v golang.org/x/tools/gopls@v0.18.1
if [ -x $GOBIN/gopls ]; then
    echo "gopls installed successfully"
else
    echo "gopls installation failed"
fi

#go install -v golang.org/x/lint/golint@latest
#go install -v github.com/go-delve/delve/cmd/dlv@latest

# 配置 qoder 开发环境
QODER_SETTINGS_DIR="$HOME/.qoder-server/data/Machine"
QODER_SETTINGS_FILE="$QODER_SETTINGS_DIR/settings.json"

mkdir -p "$QODER_SETTINGS_DIR"

cat > "$QODER_SETTINGS_FILE" << EOF
{
  "go.toolsEnvVars": {
    "GOMODCACHE": "\${env:HOME}/go/pkg/mod",
    "GOBIN": "\${env:HOME}/go/bin",
    "GOPROXY": "https://goproxy.cn,direct"
  },
  "go.alternateTools": {
    "go": "$GO_ELF_FILE"
    // "go": "/usr/bin/go"
  }
}
EOF

echo "qoder settings written to $QODER_SETTINGS_FILE"