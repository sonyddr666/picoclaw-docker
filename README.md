# 🦐 PicoClaw Docker — Gemini & Gemma

Deploy do [PicoClaw](https://github.com/sipeed/picoclaw) com suporte a **Gemini 2.5 Flash Lite** e **Gemma 3 27B** via Docker/Coolify.

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone https://github.com/sonyddr666/picoclaw-docker.git
cd picoclaw-docker

# 2. Copie o template de variáveis
cp .env.example .env

# 3. Edite o .env com suas credenciais
nano .env

# 4. Build e run
docker compose up -d --build

# 5. Ver logs
docker compose logs -f picoclaw
```

## 📦 Modelos Suportados

Este projeto suporta **todos os modelos do Google AI Studio**, incluindo:

- ✅ `gemini-2.5-flash-lite-preview-09-2025` (padrão, super rápido)
- ✅ `gemma-3-27b-it` (Gemma 3 27B, mais inteligente)
- ✅ `gemini-2.0-flash` (Gemini 2.0)
- ✅ `gemini-1.5-pro` (Gemini 1.5 Pro)

Para usar o **Gemma 3 27B**, basta definir:
```bash
PICOCLAW_MODEL=gemma-3-27b-it
```

## 🔧 Variáveis de Ambiente

| Variável | Obrigatório | Descrição | Exemplo |
|----------|:-----------:|-----------|----------|
| `GEMINI_API_KEY` | ✅ | Chave API do Google AI Studio | [Obter aqui](https://aistudio.google.com/api-keys) |
| `PICOCLAW_MODEL` | ❌ | Modelo a usar | `gemma-3-27b-it` ou `gemini-2.5-flash-lite-preview-09-2025` |
| `TELEGRAM_BOT_TOKEN` | ❌ | Token do bot Telegram | Via [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_ALLOW_FROM` | ❌ | IDs permitidos (separados por vírgula) | `123456789,987654321` |
| `DISCORD_BOT_TOKEN` | ❌ | Token do bot Discord | Via Discord Developer Portal |
| `DISCORD_ALLOW_FROM` | ❌ | IDs permitidos (separados por vírgula) | `123456789,987654321` |
| `BRAVE_SEARCH_API_KEY` | ❌ | API key do Brave Search | 2000 queries grátis/mês |

### ⚠️ IMPORTANTE: Use Variáveis de Ambiente!

**NÃO edite o `config.json` manualmente!** O entrypoint injeta automaticamente todas as variáveis de ambiente no config. Editar manualmente pode causar perda de dados em redeploys.

## 🐳 Deploy no Coolify

### Opção 1: Docker Compose (Recomendado)

1. **Push este repositório** para seu GitHub/GitLab
2. **No Coolify:** Novo Recurso → Docker Compose → Selecione seu repositório
3. **Na aba Environment**, adicione as variáveis:
   ```bash
   GEMINI_API_KEY=sua_chave_aqui
   PICOCLAW_MODEL=gemma-3-27b-it
   TELEGRAM_BOT_TOKEN=seu_token_aqui
   TELEGRAM_ALLOW_FROM=seu_user_id
   ```
4. **Verifique Storage:**
   - Deve existir um volume automático: `picoclaw_data` → `/home/picoclaw/.picoclaw`
   - Se não existir, crie manualmente:
     - **Source:** Volume nomeado (ex: `picoclaw_data`)
     - **Destination:** `/home/picoclaw/.picoclaw`
5. **Deploy!**

### Opção 2: Dockerfile Puro

1. **No Coolify:** Novo Recurso → Dockerfile
2. Adicione as variáveis de ambiente
3. **Na aba Storages**, adicione:
   - **Destination Path:** `/home/picoclaw/.picoclaw`
   - **Type:** Volume
4. **Deploy!**

> 💡 **Dica:** O PicoClaw usa **Long Polling/WebSocket** (ele "disca para fora"), então **não precisa expor portas** para Telegram/Discord!

## 📂 Persistência de Dados

O volume `/home/picoclaw/.picoclaw` persiste:
- `workspace/` — memória do agente (`SOUL.md`, `MEMORY.md`)
- `config.json` — configuração gerada automaticamente

### ⚠️ Cuidado com Caminhos!

O volume está em **`/home/picoclaw/.picoclaw`**, NÃO em `~/.picoclaw` ou `/.picoclaw`!

Se precisar editar manualmente (não recomendado):
```bash
# CORRETO ✅
docker exec -it picoclaw sh
cd /home/picoclaw/.picoclaw
cat config.json

# ERRADO ❌
cd ~/.picoclaw   # Este é outro caminho!
cd /.picoclaw    # Este também!
```

## 🔍 Troubleshooting

### Erro: "API key not valid"

1. Confirme que a API key está correta no Coolify (Environment)
2. Verifique se o modelo tem acesso na sua API key:
   - Acesse [Google AI Studio](https://aistudio.google.com/api-keys)
   - Teste se o modelo `gemma-3-27b-it` está disponível

### Config.json não persiste

1. Verifique se o volume existe no Coolify:
   ```bash
   docker volume ls | grep picoclaw
   ```
2. Confirme o Destination Path: `/home/picoclaw/.picoclaw`
3. **Não edite o config.json manualmente!** Use variáveis de ambiente.

### Modelo Gemma 3 27B não funciona

1. Certifique-se de usar o nome exato:
   ```bash
   PICOCLAW_MODEL=gemma-3-27b-it
   ```
2. O Dockerfile já inclui um patch para suportar modelos Gemma no provider Gemini
3. Verifique os logs:
   ```bash
   docker compose logs -f picoclaw
   ```

### Bot não responde no Telegram

1. Verifique se o `TELEGRAM_ALLOW_FROM` contém seu User ID
2. Para descobrir seu User ID, use [@userinfobot](https://t.me/userinfobot)
3. Confirme que o token está correto (via [@BotFather](https://t.me/BotFather))

## 🏗️ Estrutura do Projeto

```
picoclaw-docker/
├── Dockerfile          # Multi-stage: Go 1.24 → Alpine 3.21
│                       # + Patch para suportar modelos Gemma
├── docker-compose.yml  # Service + volume persistente
├── config.json         # Template de config (Gemini Flash Lite)
├── entrypoint.sh       # Injeção automática de env vars
├── .env.example        # Template de variáveis de ambiente
├── .gitignore
└── README.md
```

## 🔐 Segurança

- **NUNCA** commite arquivos `.env` com credenciais
- Use `.gitignore` para proteger `.env`
- Revogue imediatamente qualquer credencial exposta:
  - API Keys: [Google AI Studio](https://aistudio.google.com/api-keys)
  - Bot Tokens: [@BotFather](https://t.me/BotFather) → `/revoke`

## 📚 Recursos

- [PicoClaw Original](https://github.com/sipeed/picoclaw)
- [Google AI Studio](https://aistudio.google.com/)
- [Coolify Docs](https://coolify.io/docs)
- [Gemma Models](https://ai.google.dev/gemma)

## 📝 Licença

Este projeto segue a licença do [PicoClaw original](https://github.com/sipeed/picoclaw).
