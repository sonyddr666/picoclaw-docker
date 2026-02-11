# 🦐 PicoClaw Docker — Gemini 2.5 Flash Lite

Deploy do [PicoClaw](https://github.com/sipeed/picoclaw) com **Gemini 2.5 Flash Lite** via Docker/Coolify.

## Quick Start

```bash
# 1. Copie o template de variáveis
cp .env.example .env

# 2. Edite o .env com sua chave API
#    GEMINI_API_KEY=sua_chave_aqui

# 3. Build e run
docker compose up -d --build

# 4. Ver logs
docker compose logs -f
```

## Variáveis de Ambiente

| Variável | Obrigatório | Descrição |
|----------|:-----------:|-----------|
| `GEMINI_API_KEY` | ✅ | Chave API do Google ([obter](https://aistudio.google.com/api-keys)) |
| `PICOCLAW_MODEL` | ❌ | Override do modelo (padrão: `gemini-2.5-flash-lite-preview-09-2025`) |
| `TELEGRAM_BOT_TOKEN` | ❌ | Token do bot Telegram (via @BotFather) |
| `TELEGRAM_ALLOW_FROM` | ❌ | User IDs permitidos, separados por vírgula |
| `DISCORD_BOT_TOKEN` | ❌ | Token do bot Discord |
| `DISCORD_ALLOW_FROM` | ❌ | User IDs permitidos, separados por vírgula |
| `BRAVE_SEARCH_API_KEY` | ❌ | API key do Brave Search (2000 queries grátis/mês) |

## Deploy no Coolify

1. **Push para Git** (GitHub, GitLab, etc.)
2. **No Coolify:** Novo Recurso → Docker Compose
3. **Adicione as variáveis** de ambiente na aba "Environment"
4. **Deploy!**

> O PicoClaw usa **Long Polling / WebSocket** (ele "disca para fora"), então **não precisa abrir portas** extras!

## Persistência

O volume `picoclaw_data` persiste:
- `~/.picoclaw/workspace/` — memória do agente (`SOUL.md`, `MEMORY.md`)
- `~/.picoclaw/config.json` — configuração

## Estrutura

```
picoclaw-docker/
├── Dockerfile          # Multi-stage: Go 1.24 → Alpine 3.21
├── docker-compose.yml  # Service + volume persistente
├── config.json         # Config template (Gemini Flash Lite)
├── entrypoint.sh       # Injeção de env vars + onboard
├── .env.example        # Template de variáveis
└── .gitignore
```
