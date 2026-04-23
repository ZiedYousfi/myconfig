#!/usr/bin/env zsh

# Black & Pink prompt theme for Oh My Zsh.
# Based on the bundled "refined" theme, with colors mapped to the
# blacknpink terminal palette from the shared stylesheet.

setopt prompt_subst

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable hg bzr git
zstyle ':vcs_info:*:*' unstagedstr '%F{red}!%f'
zstyle ':vcs_info:*:*' stagedstr '%F{green}+%f'
zstyle ':vcs_info:*:*' formats '%B%r%b/%S' '%s:%b' '%%u%c'
zstyle ':vcs_info:*:*' actionformats '%B%r%b/%S' '%s:%b' '%u%c (%a)'
zstyle ':vcs_info:*:*' nvcsformats '%~' '' ''

blacknpink_git_dirty() {
    command git rev-parse --is-inside-work-tree &>/dev/null || return
    command git diff --quiet --ignore-submodules HEAD &>/dev/null
    [[ $? -eq 1 ]] && print -n '%F{magenta}*%f'
}

blacknpink_repo_information() {
    local location="${vcs_info_msg_0_%%/.}"
    local repo="${vcs_info_msg_1_}"
    local state="${vcs_info_msg_2_}"
    local dirty

    dirty="$(blacknpink_git_dirty)"

    if [[ -n "$repo" ]]; then
        print -n "%F{magenta}${location}%f %F{8}${repo}${dirty} ${state}%f"
    else
        print -n "%F{white}${location}%f"
    fi
}

blacknpink_cmd_exec_time() {
    local stop="${EPOCHSECONDS:-$(date +%s)}"
    local start="${cmd_timestamp:-$stop}"
    local elapsed=$(( stop - start ))

    (( elapsed > 5 )) && print -n "${elapsed}s"
}

preexec() {
    cmd_timestamp="${EPOCHSECONDS:-$(date +%s)}"
}

precmd() {
    setopt localoptions nopromptsubst

    vcs_info
    print -P "\n$(blacknpink_repo_information) %F{yellow}$(blacknpink_cmd_exec_time)%f"
    unset cmd_timestamp
}

PROMPT='%(?.%F{magenta}.%F{red})❯%f '
RPROMPT='%F{8}${SSH_TTY:+%n@%m}%f'
