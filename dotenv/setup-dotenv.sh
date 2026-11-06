#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Copy configuration files if they don't exist
[[ -f ~/.bashrc.devops ]] || cp "$SCRIPT_DIR/.bashrc" ~/.bashrc.devops
[[ -f ~/.vimrc.devops ]] || cp "$SCRIPT_DIR/.vimrc" ~/.vimrc.devops

# Ensure main configuration files exist
touch ~/.bashrc
touch ~/.vimrc

# Append source statements if missing
BASHRC_ENTRY='[ -f ~/.bashrc.devops ] && source ~/.bashrc.devops'
VIMRC_ENTRY='if filereadable(expand("~/.vimrc.devops")) | source ~/.vimrc.devops | endif'

grep -Fqx "$BASHRC_ENTRY" ~/.bashrc || echo "$BASHRC_ENTRY" >> ~/.bashrc

grep -Fqx "$VIMRC_ENTRY" ~/.vimrc || echo "$VIMRC_ENTRY" >> ~/.vimrc

echo "Dotfiles setup completed!"
