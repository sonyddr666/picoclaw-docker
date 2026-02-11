#!/bin/bash
set -e

PICOCLAW_HOME="$HOME/.picoclaw"
CONFIG_FILE="$PICOCLAW_HOME/config.json"
WORKSPACE="$PICOCLAW_HOME/workspace"

echo "======================================"
echo "🦐 PicoClaw Docker - Inicializando..."
echo "======================================"

# --- SEMPRE recria o config.json do template ---
echo "📝 Criando config.json do zero..."
cp /defaults/config.json "$CONFIG_FILE"

# --- Injeta TODAS as env vars no JSON ---
echo "🔑 Injetando variáveis de ambiente..."
echo ""

# GEMINI API KEY (OBRIGATÓRIO)
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ ERRO: GEMINI_API_KEY é obrigatória!"
    echo "   Defina a variável de ambiente e reinicie."
    exit 1
fi

tmp=$(jq --arg key "$GEMINI_API_KEY" '.providers.gemini.api_key = $key' "$CONFIG_FILE")
echo "$tmp" > "$CONFIG_FILE"
echo "  ✅ GEMINI_API_KEY: ...${GEMINI_API_KEY: -8}"

# MODELO
if [ -n "$PICOCLAW_MODEL" ]; then
    tmp=$(jq --arg model "$PICOCLAW_MODEL" '.agents.defaults.model = $model' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ PICOCLAW_MODEL: $PICOCLAW_MODEL"
else
    echo "  ℹ️ PICOCLAW_MODEL: (usando padrão do template)"
fi

# TELEGRAM BOT TOKEN
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    tmp=$(jq --arg token "$TELEGRAM_BOT_TOKEN" '.channels.telegram.enabled = true | .channels.telegram.token = $token' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ TELEGRAM_BOT_TOKEN: ...${TELEGRAM_BOT_TOKEN: -8}"
    
    # TELEGRAM ALLOW FROM
    if [ -n "$TELEGRAM_ALLOW_FROM" ]; then
        IFS=',' read -ra IDS <<< "$TELEGRAM_ALLOW_FROM"
        JSON_ARRAY=$(printf '%s\n' "${IDS[@]}" | jq -R . | jq -s .)
        tmp=$(jq --argjson ids "$JSON_ARRAY" '.channels.telegram.allow_from = $ids' "$CONFIG_FILE")
        echo "$tmp" > "$CONFIG_FILE"
        echo "  ✅ TELEGRAM_ALLOW_FROM: $TELEGRAM_ALLOW_FROM"
    fi
fi

# DISCORD BOT TOKEN
if [ -n "$DISCORD_BOT_TOKEN" ]; then
    tmp=$(jq --arg token "$DISCORD_BOT_TOKEN" '.channels.discord.enabled = true | .channels.discord.token = $token' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ DISCORD_BOT_TOKEN: ...${DISCORD_BOT_TOKEN: -8}"
    
    # DISCORD ALLOW FROM
    if [ -n "$DISCORD_ALLOW_FROM" ]; then
        IFS=',' read -ra IDS <<< "$DISCORD_ALLOW_FROM"
        JSON_ARRAY=$(printf '%s\n' "${IDS[@]}" | jq -R . | jq -s .)
        tmp=$(jq --argjson ids "$JSON_ARRAY" '.channels.discord.allow_from = $ids' "$CONFIG_FILE")
        echo "$tmp" > "$CONFIG_FILE"
        echo "  ✅ DISCORD_ALLOW_FROM: $DISCORD_ALLOW_FROM"
    fi
fi

# BRAVE SEARCH API KEY
if [ -n "$BRAVE_SEARCH_API_KEY" ]; then
    tmp=$(jq --arg key "$BRAVE_SEARCH_API_KEY" '.tools.web.search.api_key = $key' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ BRAVE_SEARCH_API_KEY: ...${BRAVE_SEARCH_API_KEY: -8}"
fi

echo ""
echo "======================================"
echo "📊 Configuração Final:"
echo "======================================"
echo "  Modelo: $(jq -r '.agents.defaults.model' "$CONFIG_FILE")"
echo "  Provider: gemini"
echo "  Workspace: $WORKSPACE"
echo "  Config: $CONFIG_FILE"
echo "======================================"
echo ""

# --- Cria workspace e arquivos essenciais ---
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
    echo "📁 Criando workspace..."
    mkdir -p "$WORKSPACE/memory"
    mkdir -p "$WORKSPACE/skills"
    
    # SOUL.md
    cat > "$WORKSPACE/SOUL.md" << 'EOFSOULO'
# Soul

I am picoclaw, a lightweight AI assistant.

## Personality

- Helpful and friendly
- Concise and to the point
- Curious and eager to learn
- Honest and transparent

## Values

- Accuracy over speed
- User privacy and safety
- Transparency in actions
- Continuous improvement
EOFSOULO

    # USER.md
    cat > "$WORKSPACE/USER.md" << 'EOFUSER'
# User

Information about user goes here.

## Preferences

- Communication style: casual
- Timezone: UTC
- Language: English
EOFUSER

    # MEMORY.md
    cat > "$WORKSPACE/memory/MEMORY.md" << 'EOFMEMORY'
# Long-term Memory

This file stores important information that should persist across sessions.

## User Information

(Important facts about user)

## Preferences

(User preferences learned over time)

## Important Notes

(Things to remember)
EOFMEMORY

    echo "  ✅ Workspace criado em $WORKSPACE"
    echo ""
fi

echo "🦐 Iniciando PicoClaw Agent..."
echo ""

# --- Executa o PicoClaw ---
exec picoclaw "$@"
