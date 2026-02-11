#!/bin/bash
set -e

PICOCLAW_HOME="$HOME/.picoclaw"
CONFIG_FILE="$PICOCLAW_HOME/config.json"

# --- Create config from template if not exists ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📋 Criando config.json a partir do template..."
    cp /defaults/config.json "$CONFIG_FILE"
fi

# --- Inject environment variables into config ---
echo "🔑 Injetando variáveis de ambiente na configuração..."

# Gemini API Key
if [ -n "$GEMINI_API_KEY" ]; then
    tmp=$(jq --arg key "$GEMINI_API_KEY" '.providers.gemini.api_key = $key' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ GEMINI_API_KEY configurada"
fi

# Model override
if [ -n "$PICOCLAW_MODEL" ]; then
    tmp=$(jq --arg model "$PICOCLAW_MODEL" '.agents.defaults.model = $model' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Modelo: $PICOCLAW_MODEL"
fi

# Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    tmp=$(jq --arg token "$TELEGRAM_BOT_TOKEN" '.channels.telegram.enabled = true | .channels.telegram.token = $token' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Telegram Bot configurado"
fi

if [ -n "$TELEGRAM_ALLOW_FROM" ]; then
    # Convert comma-separated IDs to JSON array
    IFS=',' read -ra IDS <<< "$TELEGRAM_ALLOW_FROM"
    JSON_ARRAY=$(printf '%s\n' "${IDS[@]}" | jq -R . | jq -s .)
    tmp=$(jq --argjson ids "$JSON_ARRAY" '.channels.telegram.allow_from = $ids' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Telegram allow_from: $TELEGRAM_ALLOW_FROM"
fi

# Discord
if [ -n "$DISCORD_BOT_TOKEN" ]; then
    tmp=$(jq --arg token "$DISCORD_BOT_TOKEN" '.channels.discord.enabled = true | .channels.discord.token = $token' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Discord Bot configurado"
fi

if [ -n "$DISCORD_ALLOW_FROM" ]; then
    IFS=',' read -ra IDS <<< "$DISCORD_ALLOW_FROM"
    JSON_ARRAY=$(printf '%s\n' "${IDS[@]}" | jq -R . | jq -s .)
    tmp=$(jq --argjson ids "$JSON_ARRAY" '.channels.discord.allow_from = $ids' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Discord allow_from: $DISCORD_ALLOW_FROM"
fi

# Brave Search API Key (optional)
if [ -n "$BRAVE_SEARCH_API_KEY" ]; then
    tmp=$(jq --arg key "$BRAVE_SEARCH_API_KEY" '.tools.web.search.api_key = $key' "$CONFIG_FILE")
    echo "$tmp" > "$CONFIG_FILE"
    echo "  ✅ Brave Search configurado"
fi

# --- Run onboard if workspace is empty ---
if [ ! -f "$PICOCLAW_HOME/workspace/SOUL.md" ]; then
    echo "🚀 Primeira execução — rodando onboard..."
    picoclaw onboard || echo "⚠️ Onboard falhou, continuando mesmo assim..."
fi

echo ""
echo "🦐 PicoClaw iniciando..."
echo "   Modelo: $(jq -r '.agents.defaults.model' "$CONFIG_FILE")"
echo "   Provider: gemini"
echo ""

# --- Execute command ---
exec picoclaw "$@"
