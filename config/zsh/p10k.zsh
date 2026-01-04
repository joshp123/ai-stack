# Temporarily change options.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh
  setopt no_unset

  autoload -Uz is-at-least && is-at-least 5.1 || return

  # Unset all configuration options.
  unset -m 'POWERLEVEL9K_*'

  # Left prompt segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      dir                       # current directory
      vcs                       # git status
      context                   # user@host
      command_execution_time    # previous command duration
      virtualenv                # python virtual environment
      prompt_char               # prompt symbol
  )

  # Right prompt segments.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      nix_shell_with_name
  )

  # Defines character set used by powerlevel10k.
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete

  # When set to `moderate`, some icons will have an extra space after them. This is meant to avoid
  # icon overlap when using non-monospace fonts. When set to `none`, spaces are not added.
  typeset -g POWERLEVEL9K_ICON_PADDING=none

  # Basic style options that define the overall prompt look.
  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no surrounding whitespace
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # separate segments with a space
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end-of-line symbol
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=           # no segment icons

  # Add an empty line before each prompt except the first. This doesn't emulate the bug
  # in Pure that makes prompt drift down whenever you use the ALT-C binding from fzf or similar.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Green prompt symbol if the last command succeeded.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=002
  # Red prompt symbol if the last command failed.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=001
  # Default prompt symbol.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  # Prompt symbol in command vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  # Prompt symbol in visual vi mode is the same as in command mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  # Prompt symbol in overwrite vi mode is the same as in command mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # Grey Python Virtual Environment.
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=007
  # Don't show Python version.
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # Blue current directory.
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=blue

  # Context format when root: user@host. The first part white, the rest grey.
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%7F%n%f%007F@%m%f'
  # Context format when not root: user@host. The whole thing grey.
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%007F%n@%m%f'
  # Don't show context unless root or in SSH.
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=

  # Show previous command duration only if it's >= 5s.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=007
  # Don't show duration when command was too fast.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

  # Git status styling.
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=002
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=003
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=003

  # Truncate long paths.
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='.git'
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true

  # Disable rprompt.
  typeset -g POWERLEVEL9K_DISABLE_RPROMPT=true
}

'builtin' 'unset' 'p10k_config_opts'
