# devenv

`devenv` 是一个基于 Docker 镜像的轻量开发环境隔离工具。每个环境都以独立镜像 `devenv:<环境名>` 保存：日常开发在临时容器中进行，安装依赖或修改基础环境时则进入维护模式并将变更提交回镜像。

`dev` 是 `devenv run` 的简写，适合日常使用。

## 前置条件

- 已安装并启动 Docker（Docker Desktop 或 Docker Engine）
- 当前用户可运行 `docker` 命令
- Bash 或 Zsh（用于命令与自动补全脚本）

首次创建环境时会拉取基础镜像 `ubuntu:26.04`。

## 安装

在项目目录执行：

```bash
./install.sh
```

默认会将 `dev` 和 `devenv` 安装到 `~/.local/bin`，并为 Bash、Zsh 配置 PATH 与自动补全。重新打开终端后即可使用。

也可指定安装前缀：

```bash
./install.sh --prefix /usr/local
```

若只安装命令、不安装补全脚本：

```bash
./install.sh --no-completion
```

> 使用 Zsh 时，请确保已在 `.zshrc` 中启用补全系统，例如 `autoload -Uz compinit && compinit`。

## 快速开始

进入一个名为 `python-dev` 的隔离环境：

```bash
cd /path/to/your/project
dev python-dev
```

如果环境尚不存在，工具会自动基于 `ubuntu:26.04` 创建 `devenv:python-dev`。启动时会在容器内创建（或复用）与当前宿主用户相同用户名、组名、UID/GID 的账号；若镜像中已有同一 UID/GID 的 `ubuntu` 等默认账号，则会改名为宿主名称。容器 shell 以该账号运行。当前目录会以相同的绝对路径挂载进容器，并作为容器工作目录；退出 shell 后临时容器会被删除，项目文件仍保留在宿主机上。因此在挂载目录中新建的文件不会归属为 root。

为环境安装依赖并持久保存：

```bash
devenv maint python-dev
# 容器内：apt update && apt install -y git curl python3
exit
```

退出维护模式后，容器的文件系统变更会被提交回 `devenv:python-dev`。之后再次执行 `dev python-dev`，即可使用更新后的环境。

## 命令

| 命令 | 说明 |
| --- | --- |
| `devenv ls` | 列出已创建的开发环境。 |
| `devenv create <环境名>` | 创建开发环境。 |
| `devenv rm <环境名>` | 删除开发环境及对应镜像。 |
| `devenv run <环境名> [Docker 参数...]` | 启动以当前宿主用户身份运行的临时开发容器。环境不存在时会自动创建。 |
| `devenv maint <环境名>` | 以 root 进入维护容器；退出时自动保存变更。环境不存在时会自动创建。 |
| `dev <环境名> [Docker 参数...]` | `devenv run` 的快捷方式。 |

例如，将 8080 端口映射到宿主机：

```bash
dev web-dev -p 8080:8080
```

`run` 和 `dev` 后面的参数会原样传给 `docker run`，并位于镜像名之前，因此可用于传递端口、环境变量、设备或额外挂载等 Docker 运行参数。

## 环境名规则

环境名会用作 Docker tag，须符合以下规则：

- 只能包含小写字母、数字、下划线（`_`）、中划线（`-`）和点（`.`）
- 必须以小写字母、数字或下划线开头
- 最长 128 个字符

有效示例：`python-dev`、`node_20`、`go1.24`。

## 工作方式

```text
devenv create demo  →  devenv:demo 镜像
dev demo            →  临时容器 + 挂载当前项目目录 → exit 后容器删除
devenv maint demo   →  维护容器 → exit 后 docker commit → 更新 devenv:demo
```

项目源码通过挂载保存在宿主机；`run`/`dev` 会自动将容器 shell 切换为当前宿主 UID/GID，以避免挂载目录的文件所有权问题。维护模式则有意保留 root 权限，以便安装工具链；只有维护模式中对容器文件系统的修改会保存到环境镜像。需要移除环境时执行：

```bash
devenv rm demo
```

## 自动补全

安装脚本会提供以下补全：

- `devenv <Tab>`：补全子命令。
- `devenv rm|run|maint <Tab>`：补全已创建环境名。
- `dev <Tab>`：补全已创建环境名。

补全查询本机 Docker 镜像，因此显示的是当前存在的 `devenv:*` 环境。
