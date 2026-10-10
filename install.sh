#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash install.sh [--repo URL] [--branch NAME] [--target DIR] [--install-deps]

By default, install the configuration beside this script into Neovim's config
directory. --repo clones a repository instead (default branch: main).
Existing configuration is backed up; its local.lua is preserved.
System packages are installed only with --install-deps.
Plugins install when you first launch Neovim; then run :Lazy restore.
EOF
}

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }
need_value() { [ "$#" -ge 2 ] && [ -n "$2" ] || die "Missing value for $1"; }

repo=""
branch="main"
target=""
install_deps=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) need_value "$@"; repo="$2"; shift 2 ;;
    --branch) need_value "$@"; branch="$2"; shift 2 ;;
    --target) need_value "$@"; target="$2"; shift 2 ;;
    --install-deps) install_deps=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

source_dir=""
script_path=${BASH_SOURCE[0]:-}
if [ -n "$script_path" ]; then
  source_dir=$(cd -- "$(dirname -- "$script_path")" && pwd -P)
fi
if [ -z "$source_dir" ] && [ -z "$repo" ]; then
  die "When running through curl | bash, supply --repo URL."
fi
os=$(uname -s)
case "$os" in Linux|Darwin) ;; *) die "Use install.ps1 on Windows." ;; esac

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install system packages."
    sudo "$@"
  fi
}

if [ "$install_deps" -eq 1 ]; then
  if [ "$os" = Darwin ]; then
    command -v brew >/dev/null 2>&1 || die "Install Homebrew first: https://brew.sh"
    brew install neovim git gcc@15 curl ripgrep fd tree-sitter
  elif command -v pacman >/dev/null 2>&1; then
    as_root pacman -S --needed neovim git gcc curl ripgrep fd tree-sitter-cli wl-clipboard xclip
  elif command -v apt-get >/dev/null 2>&1; then
    as_root apt-get update
    as_root apt-get install -y neovim git build-essential curl ripgrep fd-find wl-clipboard xclip
    note "Check the distro's Neovim version (>= 0.12.0); install tree-sitter CLI >= 0.26.1 separately."
  elif command -v dnf >/dev/null 2>&1; then
    as_root dnf install -y neovim git gcc gcc-c++ curl ripgrep fd-find wl-clipboard xclip
    note "Install a tree-sitter CLI version compatible with lazy-lock.json separately."
  else
    die "Unsupported package manager; install the dependencies listed in README.md manually."
  fi
fi

if [ -z "$target" ]; then
  if command -v nvim >/dev/null 2>&1; then
    target=$(nvim --headless -u NONE -i NONE -n -c "lua io.write(vim.fn.stdpath('config'))" -c qa)
  else
    app_name=${NVIM_APPNAME:-nvim}
    case "$app_name" in .|..|*/*|*\\*) die "Invalid NVIM_APPNAME; use a single directory name." ;; esac
    target="${XDG_CONFIG_HOME:-$HOME/.config}/$app_name"
  fi
fi
[ -n "$target" ] || die "The configuration directory is empty."
while [[ "$target" == */ ]]; do target=${target%/}; done
[ -n "$target" ] || die "Refusing to replace the filesystem root."
parent=$(dirname -- "$target")
leaf=$(basename -- "$target")
case "$leaf" in .|..) die "Invalid target directory." ;; esac
mkdir -p -- "$parent"
parent=$(cd -- "$parent" && pwd -P)
target="$parent/$leaf"
[ "$target" != "$HOME" ] || die "Refusing to replace your home directory."

stage=""
backup=""
installed=0
cleanup() {
  local status=$?
  trap - EXIT
  if [ "$installed" -eq 0 ] && [ -n "$backup" ] && { [ -e "$backup" ] || [ -L "$backup" ]; }; then
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      mv -- "$backup" "$target" || note "Restore the backup manually: $backup"
    fi
  fi
  if [ -n "$stage" ] && [ -d "$stage" ]; then rm -rf -- "$stage"; fi
  exit "$status"
}
trap cleanup EXIT

if [ -z "$repo" ]; then
  [ -f "$source_dir/init.lua" ] && [ -f "$source_dir/lua/config/lazy.lua" ] \
    || die "No local configuration found; supply --repo URL."
fi

if [ -z "$repo" ] && [ "$target" = "$source_dir" ]; then
  note "This configuration is already installed at $target"
else
  if [ -z "$repo" ]; then
    case "$target/" in "$source_dir/"*) die "Target must be outside the source configuration." ;; esac
    case "$source_dir/" in "$target/"*) die "Target must not contain the source configuration." ;; esac
  else
    command -v git >/dev/null 2>&1 || die "Git is required; install it or use --install-deps."
  fi
  stage=$(mktemp -d "$parent/.nvim-install.XXXXXXXX")
  if [ -n "$repo" ]; then
    git clone --depth 1 --branch "$branch" -- "$repo" "$stage"
  else
    tar -C "$source_dir" --exclude='./.git' --exclude='./local.lua' --exclude='./lazy' \
      --exclude='./node_modules' --exclude='./.repro' --exclude='*.swp' --exclude='*.swo' \
      -cf - . | tar -C "$stage" -xf -
  fi
  [ -f "$stage/init.lua" ] && [ -f "$stage/lua/config/lazy.lua" ] \
    || die "The source does not contain this Neovim configuration."
  if [ -f "$target/local.lua" ]; then
    cp -L -- "$target/local.lua" "$stage/local.lua"
    note "Preserving the existing local.lua"
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$target.backup.$(date +%Y%m%d-%H%M%S).$$"
    [ ! -e "$backup" ] && [ ! -L "$backup" ] || die "Backup path already exists: $backup"
    mv -- "$target" "$backup"
    note "Backup: $backup"
  fi
  mv -- "$stage" "$target"
  stage=""
  installed=1
  note "Installed configuration: $target"
fi

compiler_tools=(gcc g++)
if [ "$os" = Darwin ]; then compiler_tools=(gcc-15 g++-15); fi
for tool in nvim git curl rg tree-sitter "${compiler_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    note "Missing dependency: $tool (see README.md)"
  fi
done
if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
  note "Missing dependency: fd / fdfind (see README.md)"
fi
if command -v nvim >/dev/null 2>&1; then
  version=$(nvim --version)
  version=${version%%$'\n'*}
  if [[ "$version" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
    if [ "$major" -eq 0 ] && [ "$minor" -lt 12 ]; then
      note "Neovim is too old: $version. Upgrade to >= 0.12.0 before starting."
    fi
  fi
fi
if [ "$os" = Darwin ]; then
  note "macOS: gcc-15 and g++-15 must be on PATH (brew install gcc@15)."
fi
note "Next: launch nvim, run :Lazy restore, restart, then run :checkhealth."
note "For a custom --target, configure XDG_CONFIG_HOME/NVIM_APPNAME to use that directory."
