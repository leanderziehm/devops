#!/usr/bin/env bash
# code from: https://github.com/leanderziehm/devops/blob/main/others/git-clone-ssh-quick.sh
# last edited: 18-10-2026 
set -e
# Supports:
#   git@github.com:username/reponame.git
#   https://github.com/username/reponame.git
#   https://github.com/username/reponame

# Ask for the repository URL if not provided as an argument
if [[ $# -eq 0 ]]; then
    echo
    read -r -p "Enter the GitHub repository URL: " REPO_URL
    echo
elif [[ $# -eq 1 ]]; then
    REPO_URL="$1"
else
    echo "Usage: $0 [github-url]"
    exit 1
fi

# Remove leading/trailing whitespace
REPO_URL="$(printf '%s' "$REPO_URL" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

# Normalize GitHub URLs to SSH format
case "$REPO_URL" in
    https://github.com/*)
        REPO_PATH="${REPO_URL#https://github.com/}"
        ;;
    git@github.com:*)
        REPO_PATH="${REPO_URL#git@github.com:}"
        ;;
    *)
        echo "Error: unsupported GitHub URL."
        echo "Use an HTTPS or SSH GitHub repository URL."
        exit 1
        ;;
esac

# Remove trailing slash and optional .git suffix
REPO_PATH="${REPO_PATH%/}"

# Validate owner/repository format
if [[ ! "$REPO_PATH" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]]; then
    echo "Error: invalid GitHub repository path: $REPO_PATH"
    exit 1
fi

# Convert to standard SSH URL
REPO_NAME="${REPO_PATH##*/}"
REPO_NAME="${REPO_NAME%.git}"
REPO_URL="git@github.com:${REPO_PATH%.git}.git"

echo "Repository: $REPO_URL"
echo "Directory:  $REPO_NAME"
echo

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

# GIT_SSH_COMMAND="ssh -i ~/.ssh/github/android-apps -o IdentitiesOnly=yes" git clone git@github.com:leanderziehm/android-apps.git
GIT_SSH_COMMAND="ssh -i $SSH_KEY -o IdentitiesOnly=yes" git clone "$REPO_URL" "$REPO_NAME"

cd "$REPO_NAME"

# Configure this repository to always use this SSH key
git config core.sshCommand "ssh -i $SSH_KEY -o IdentitiesOnly=yes"

echo
echo "Done!"
echo "Repository: $REPO_NAME"
echo "SSH key:    $SSH_KEY"
