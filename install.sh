#!/usr/bin/env bash

# Install devenv and its shell completions for the current user.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${HOME}/.local"
INSTALL_COMPLETIONS=1

usage() {
    cat <<'EOF'
用法: ./install.sh [选项]

将 dev 和 devenv 安装到指定前缀，并启用 Bash 与 Zsh 自动补全。

选项:
  --prefix <目录>       安装前缀（默认: ~/.local）
  --no-completion       不安装或配置自动补全
  -h, --help            显示此帮助

示例:
  ./install.sh
  ./install.sh --prefix /usr/local
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --prefix)
            [ "$#" -ge 2 ] || { echo "错误: --prefix 需要一个目录。" >&2; exit 1; }
            PREFIX="$2"
            shift 2
            ;;
        --no-completion)
            INSTALL_COMPLETIONS=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "错误: 未知选项: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

for source_file in dev devenv \
    auto-completion/dev-bash-completion \
    auto-completion/devenv-bash-completion \
    auto-completion/dev-zsh-completion \
    auto-completion/devenv-zsh-completion; do
    if [ ! -f "$SCRIPT_DIR/$source_file" ]; then
        echo "错误: 未找到安装文件: $SCRIPT_DIR/$source_file" >&2
        exit 1
    fi
done

BIN_DIR="$PREFIX/bin"
COMPLETION_DIR="$PREFIX/share/devenv/completion"

install_file() {
    local source_file="$1"
    local target_file="$2"
    mkdir -p "$(dirname "$target_file")"
    install -m 0755 "$source_file" "$target_file"
}

install_file "$SCRIPT_DIR/dev" "$BIN_DIR/dev"
install_file "$SCRIPT_DIR/devenv" "$BIN_DIR/devenv"

echo "已安装命令:"
echo "  $BIN_DIR/dev"
echo "  $BIN_DIR/devenv"

BASH_RC="${HOME}/.bashrc"
ZSH_RC="${ZDOTDIR:-$HOME}/.zshrc"
PATH_MARKER="# devenv command path"
PATH_SNIPPET="$PATH_MARKER
case \":\$PATH:\" in
    *\":$BIN_DIR:\"*) ;;
    *) export PATH=\"$BIN_DIR:\$PATH\" ;;
esac"

add_shell_snippet() {
    local rc_file="$1"
    local marker="$2"
    local snippet="$3"
    mkdir -p "$(dirname "$rc_file")"
    touch "$rc_file"
    if ! grep -Fqx "$marker" "$rc_file"; then
        printf '\n%s\n' "$snippet" >> "$rc_file"
        echo "已更新 shell 配置: $rc_file"
    fi
}

add_shell_snippet "$BASH_RC" "$PATH_MARKER" "$PATH_SNIPPET"
add_shell_snippet "$ZSH_RC" "$PATH_MARKER" "$PATH_SNIPPET"

if [ "$INSTALL_COMPLETIONS" -eq 1 ]; then
    mkdir -p "$COMPLETION_DIR"
    install -m 0644 "$SCRIPT_DIR/auto-completion/dev-bash-completion" \
        "$COMPLETION_DIR/dev.bash"
    install -m 0644 "$SCRIPT_DIR/auto-completion/devenv-bash-completion" \
        "$COMPLETION_DIR/devenv.bash"
    install -m 0644 "$SCRIPT_DIR/auto-completion/dev-zsh-completion" \
        "$COMPLETION_DIR/dev.zsh"
    install -m 0644 "$SCRIPT_DIR/auto-completion/devenv-zsh-completion" \
        "$COMPLETION_DIR/devenv.zsh"

    BASH_MARKER="# devenv shell completion"
    ZSH_MARKER="# devenv shell completion"
    BASH_SNIPPET="$BASH_MARKER
[ -r \"$COMPLETION_DIR/dev.bash\" ] && source \"$COMPLETION_DIR/dev.bash\"
[ -r \"$COMPLETION_DIR/devenv.bash\" ] && source \"$COMPLETION_DIR/devenv.bash\""
    ZSH_SNIPPET="$ZSH_MARKER
[ -r \"$COMPLETION_DIR/devenv.zsh\" ] && source \"$COMPLETION_DIR/devenv.zsh\"
[ -r \"$COMPLETION_DIR/dev.zsh\" ] && source \"$COMPLETION_DIR/dev.zsh\""

    add_shell_snippet "$BASH_RC" "$BASH_MARKER" "$BASH_SNIPPET"
    add_shell_snippet "$ZSH_RC" "$ZSH_MARKER" "$ZSH_SNIPPET"
fi

echo "安装完成。请重新打开终端，或重新加载对应的 shell 配置文件。"
