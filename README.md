# cpvim

基于 LazyVim，包含 Kanagawa 主题、中文快捷键提示、clangd、C/C++ 格式化、
CompetiTest 样例评测、比赛工作目录和 CodeSnap 代码截图。

目标平台：Linux、macOS、原生 Windows。当前在 Linux 上验证；macOS 和 Windows
需要按下面的说明安装工具链，并在实际机器上检查。

## 一行安装

将对应平台的命令复制到本地终端执行即可，无需手动克隆仓库。
默认只安装配置，会备份原配置并保留 `local.lua`。

安装命令使用公开仓库 [`liberty-pl/cpvim`](https://github.com/liberty-pl/cpvim)。
如果采用其他仓库名，请同步修改命令中的地址。

Linux / macOS / WSL：

```sh
curl -fsSL https://raw.githubusercontent.com/liberty-pl/cpvim/main/install.sh | bash -s -- --repo https://github.com/liberty-pl/cpvim.git
```

原生 Windows（PowerShell）：

```powershell
& ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/liberty-pl/cpvim/main/install.ps1'))) -Repo 'https://github.com/liberty-pl/cpvim.git'
```

想同时安装基础系统依赖，在 Linux/macOS 命令末尾加 `--install-deps`，
Windows 命令末尾加 `-InstallDeps`。默认不安装系统依赖；Windows 的 GNU 编译器仍需按下文配置。
脚本自动下载仓库。安装完成后，请启动 `nvim`，执行 `:Lazy restore`，重启后执行 `:checkhealth`。

## 仓库内容

上传整个配置目录：`init.lua`、`lua/`、`templates/`、`lazy-lock.json`、
`lazyvim.json`、`stylua.toml`、`install.sh`、`install.ps1` 和仓库说明文件。
`lazy-lock.json` 记录插件版本，应该提交。
插件、Mason 工具、缓存、会话和工作目录不在此仓库中，应由每台机器单独安装或保存。

## 安装依赖

- Neovim >= 0.12.0（LuaJIT 构建），Git >= 2.19。当前锁文件中的 nvim-treesitter 要求 Neovim 0.12。
- GNU GCC/G++：本配置使用 GNU C++20，模板包含 `bits/stdc++.h` 和 `__int128`。
- `ripgrep`、`fd`：搜索和文件查找。
- `tar`、`curl`、C 编译器、tree-sitter CLI >= 0.26.1（与当前锁定的 nvim-treesitter 配套）。
- Nerd Font v3：在终端中设置，用于显示图标。
- `clangd` 和 `clang-format` 由 Mason 配置安装，也可以自行安装并放入 PATH。
- 系统文本剪贴板：Linux Wayland 使用 `wl-clipboard`，X11 可使用 `xclip` 或 `xsel`；
  macOS/Windows 使用 Neovim 对应的平台 provider。

Linux：通过发行版包管理器安装上面的工具，并确保 `gcc`、`g++` 在 PATH 中。

macOS：使用 GNU GCC 15，C 编译器为 `gcc-15`，C++ 编译器为 `g++-15`。
通过 Homebrew 安装：

```sh
brew install gcc@15
```

Homebrew 的 bin 目录必须在启动 Neovim 的 PATH 中，也可以通过 `local.lua` 指定完整路径。
配置默认固定使用版本 15；系统自带的 `g++` 通常是 Apple Clang，
不提供此模板需要的 `bits/stdc++.h`。安装脚本的 `--install-deps` 也会安装 `gcc@15`。

原生 Windows：安装 MSYS2，使用 **UCRT64** 工具链；在 UCRT64 终端中安装 GCC：

```sh
pacman -S mingw-w64-ucrt-x86_64-gcc
```

将 `C:\msys64\ucrt64\bin` 加入 Windows 用户 PATH，重新打开 PowerShell/终端。
这也让编译后的程序能找到工具链运行库。即使在 `local.lua` 指定了编译器，仍需这一步。
Neovim、Git、搜索工具和 tree-sitter CLI 也需要能从该终端调用。
MSVC 不适用于当前 GNU 编译参数和竞赛模板。

相关官方说明：[LazyVim 依赖](https://www.lazyvim.org/)、
[MSYS2 环境](https://www.msys2.org/docs/environments/)、
[Homebrew GCC 15](https://formulae.brew.sh/formula/gcc@15)、
[Neovim 安装](https://neovim.io/doc/install/)。

## 在另一台电脑安装

仓库提供 `install.sh` 和 `install.ps1`。默认只安装配置，不修改系统软件包；
已有配置会重命名成带时间戳的备份，原来的 `local.lua` 会复制到新配置中。
脚本先准备并检查新配置，再替换已有配置；下载失败时保留原配置。
插件在首次启动 Neovim 时安装，随后执行 `:Lazy restore`。

已经下载或克隆此仓库时，可以直接运行：

Linux / macOS / WSL：

```sh
bash install.sh
# 可选：同时通过包管理器安装基础系统依赖
bash install.sh --install-deps
```

原生 Windows（PowerShell）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
# 可选：同时通过 winget 安装 Neovim、Git、ripgrep 和 fd
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -InstallDeps
```

Windows 的 GNU GCC/MSYS2 工具链与 tree-sitter CLI 仍需按上面的依赖说明安装。
脚本不会修改系统级 PowerShell 执行策略；这里的 Bypass 仅作用于这次进程。
macOS 安装依赖需要已有 Homebrew；Linux 支持 pacman、apt-get 和 dnf，
非 root 用户会通过 sudo 安装。apt/dnf 的包版本由发行版决定，Neovim 必须达到 0.12.0；
tree-sitter CLI 在这些发行版上需另行安装。字体和终端字体设置各自维护。
版本要求以当前锁定的
[nvim-treesitter 说明](https://github.com/nvim-treesitter/nvim-treesitter/blob/857651fce37eba032ebe28f3a206283cdc65c45a/README.md#requirements)
为准。

无需手动克隆的安装方式见顶部的“一行安装”。
默认安装仓库的 `main` 分支，其他分支使用 `--branch NAME` / `-Branch NAME`。
支持 `--target PATH` / `-Target PATH` 指定配置位置；正常启动 Neovim 时仍要设置对应的
`XDG_CONFIG_HOME` / `NVIM_APPNAME`。默认路径优先读取已安装 Neovim 的 `stdpath('config')`，
未安装 Neovim 时根据这些环境变量和平台默认值确定。
私有仓库需先配置 Git 身份验证，并从已克隆的目录运行安装脚本；上面的 raw 下载示例用于公开仓库。

如果希望手动安装，也可以使用以下步骤。

如果目标目录已有配置，先重命名备份；不要直接覆盖。这里只克隆配置，不搬运插件二进制。

Linux / macOS / WSL（默认配置路径）：

```sh
git clone https://github.com/liberty-pl/cpvim.git ~/.config/nvim
nvim
```

原生 Windows（PowerShell，默认配置路径）：

```powershell
git clone https://github.com/liberty-pl/cpvim.git "$env:LOCALAPPDATA\nvim"
nvim
```

如设置了 XDG 环境变量或 `NVIM_APPNAME`，以 Neovim 中
`:echo stdpath('config')` 的输出为准。参见
[Neovim 标准路径](https://neovim.io/doc/user/starting/#standard-path)。

首次启动需要网络下载插件。在 Neovim 中执行 `:Lazy restore`，恢复锁文件记录的插件版本，
等待插件和 Mason 工具安装完成后重启，再执行 `:checkhealth`。
如果提示某个工具缺失，按提示安装；不要仅为消除提示直接更新所有插件。

## 每台机器的设置

将 `local.example.lua` 复制成同目录下的 `local.lua` 后按需修改。
它在插件配置前加载，被 Git 忽略，可保存本机路径。例如：

```lua
vim.g.cp_cc = "C:/msys64/ucrt64/bin/gcc.exe"
vim.g.cp_cxx = "C:/msys64/ucrt64/bin/g++.exe"
vim.g.cp_workspace_root = "D:/XCPC"
```

编译器设置只接受一个可执行文件名或路径，不接受含参数的 shell 命令。
Windows 路径在 Lua 字符串中使用 `/`，或对 `\` 做转义。
默认工作目录是 `~/XCPC`，模板是配置目录中的 `templates/main.cpp`。
Windows 自动编译为 `.exe`，并用对应路径运行；Linux/macOS 保留无后缀可执行文件。

clangd 会允许查询当前发现的 C/C++ 编译器，不再固定使用 `/usr/bin/g++`。
但 `--query-driver` 只是允许列表，不会替项目选择编译器。如果编译正常而 clangd
仍提示找不到头文件，请优先提供正确的 `compile_commands.json`，
或在题目/比赛目录放一个 `.clangd`，指定本机实际的 C++ 编译器：

```yaml
CompileFlags:
  Compiler: 'C:/msys64/ucrt64/bin/g++.exe'
```

macOS 使用 `g++-15`，Apple Silicon 默认路径可写成 `/opt/homebrew/bin/g++-15`，
Intel 默认路径可写成 `/usr/local/bin/g++-15`；以 `command -v g++-15` 的输出为准。
这份 `.clangd` 属于本机工作目录设置，不需要放进 Neovim 配置仓库。
参见 [clangd 系统头文件说明](https://clangd.llvm.org/guides/system-headers)。

CodeSnap 使用平台对应的原生库，在每台机器单独下载。
Wayland 下会使用 `wl-copy` 复制 PNG，其他平台调用插件自带的剪贴板功能。
如果该平台/架构的库无法下载，截图功能需要单独排查；它不影响 C++ 编辑与评测。

## 首次上传 GitHub

在这台电脑的终端执行以下命令。登录步骤需要在浏览器中由本人完成。

```sh
cd ~/.config/nvim
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
git init -b main
git add .
git diff --cached --stat
git diff --cached
git commit -m "Add portable Neovim configuration"
gh repo create cpvim --public --source=. --remote=origin --push
```

这里创建名为 `cpvim` 的公开仓库，使顶部的一行安装命令可以直接下载。
若希望使用私有仓库，将 `--public` 改成 `--private`，并使用通过 Git 登录后克隆安装的方式；
顶部的匿名下载命令不适用于私有仓库。若该仓库名已经存在，换一个名称并更新安装命令中的地址。
这套命令适用于尚未初始化 Git、尚无远端的配置目录。
提交前查看暂存差异，确认本机路径、账号凭据等不在提交内容中。
模板中保留了原有作者署名，可以在上传前自行修改。

Git 需要配置作者姓名和邮箱；如果提交时提示缺失，可在仓库中设置：

```sh
git config user.name "你的名字"
git config user.email "你的 GitHub 提交邮箱"
```

参见 [GitHub 上传本地代码](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)。

## 后续同步

修改配置后，在配置目录提交并推送：

```sh
git add .
git diff --cached
git commit -m "Update Neovim configuration"
git push
```

另一台电脑先保存本地修改，再执行 `git pull --ff-only`。
如果 `lazy-lock.json` 有更新，在 Neovim 中执行 `:Lazy restore` 并重启。
`local.lua` 在每台机器各自维护。
