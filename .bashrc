# SSH agent for VS Code/Cursor
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Add key if not already loaded
ssh-add -l &>/dev/null || ssh-add ~/.ssh/id_ed25519