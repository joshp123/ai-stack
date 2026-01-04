# Locale settings
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8

if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Use xterm-256color for universal compatibility
export TERM=xterm-256color

# Remove history data we don't want to see
export HISTIGNORE="pwd:ls:cd"

# Platform-aware ls coloring
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi

# Modern completion UX: menu selection + fzf-tab overlay
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' squeeze-slashes true

# fzf defaults (fd keeps this fast and respects .gitignore by default)
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
