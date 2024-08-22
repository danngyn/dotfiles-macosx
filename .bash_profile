#!/bin/bash
# .bash_profile

for file in ~/.{bash_prompt,bash_export,bash_alias,bash_function,bash_solarized}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

#[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

eval "$(/opt/homebrew/bin/brew shellenv)"

