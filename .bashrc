# ====== Clio LLM Gateway (managed by `dev`) ======
# Routes Claude through Clio's LLM gateway by setting ANTHROPIC_BASE_URL and
# ANTHROPIC_AUTH_TOKEN from the local token file.
#
#   Gateway: https://llm-gateway.clio.systems/
#   Help:    #pt-llm-gateway on Slack
#   Refresh: `dev login --force`
#
# Edits to this block will be overwritten.
__clio_llm_gateway_token_path="$HOME/.clio/llm-gateway-token"
if [ -f "$__clio_llm_gateway_token_path" ]; then
  export ANTHROPIC_BASE_URL="${LLM_GATEWAY_URL:-https://llm-gateway.clio.systems}"
  export ANTHROPIC_AUTH_TOKEN="$(cat "$__clio_llm_gateway_token_path")"
fi
unset __clio_llm_gateway_token_path

# Avoid loading all tools into context. True is the default, except
# ANTHROPIC_BASE_URL switches the default to false
export ENABLE_TOOL_SEARCH=true
# ====== End Clio LLM Gateway ======

#!/bin/bash
# .bashrc

[ -n "$PS1" ] && source ~/.bash_profile;


[[ -d "/opt/clio/bin/devxp" ]] && export PATH="/opt/clio/bin/devxp:$PATH"

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
