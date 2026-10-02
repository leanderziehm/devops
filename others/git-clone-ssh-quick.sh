#!/usr/bin/env bash
set -e

# Usage:
#   ./git-clone-ssh-quick.sh git@github.com:username/reponame.git

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <github-ssh-url>"
    exit 1
fi

REPO_URL="$1"
REPO_NAME=$(basename "$REPO_URL" .git)

SSH_DIR="$HOME/.ssh/github"
SSH_KEY="$SSH_DIR/$REPO_NAME"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key if it doesn't already exist
if [[ ! -f "$SSH_KEY" ]]; then
    echo "Generating SSH key..."
    echo

    ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$REPO_NAME"

    echo
    echo "=================================================="
    echo "SSH public key:"
    echo "=================================================="
    cat "$SSH_KEY.pub"
    echo "=================================================="
    echo
    echo "Add this key to GitHub."
    echo

    read -r -p "Press ENTER once the key has been added to GitHub..."

    echo
else
    echo "SSH key already exists:"
    echo "$SSH_KEY"
    echo
fi

# Check if repository directory already exists
if [[ -d "$REPO_NAME" ]]; then
    echo "Error: directory '$REPO_NAME' already exists."
    exit 1
fi

echo "Cloning $REPO_URL..."
echo

GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" \
    git clone "$REPO_URL" "$REPO_NAME"

cd "$REPO_NAME"

# Configure this repository to always use this SSH key
git config core.sshCommand \
    "ssh -i $SSH_KEY -o IdentitiesOnly=yes"

echo
echo "Done!"
echo "Repository: $REPO_NAME"
echo "SSH key:    $SSH_KEY"
