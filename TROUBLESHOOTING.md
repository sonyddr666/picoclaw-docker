# 🔧 Troubleshooting - PicoClaw Docker

Guia completo para resolver problemas comuns no PicoClaw Docker.

## 🔴 Erro: "API key not valid" ou "401 Unauthorized"

### Sintomas
```
Error: API key not valid. Please pass a valid API key.
```

### Soluções

1. **Verifique se a API key está correta:**
   ```bash
   # No Coolify, veja a variável GEMINI_API_KEY
   # Ou nos logs do container:
   docker compose logs picoclaw | grep -i "api"
   ```

2. **Regenere a API key:**
   - Acesse [Google AI Studio](https://aistudio.google.com/api-keys)
   - Delete a key antiga
   - Crie uma nova
   - Atualize a variável `GEMINI_API_KEY`

3. **Verifique se o modelo tem acesso:**
   - Alguns modelos podem não estar disponíveis em todas as regiões
   - Teste com `gemini-2.5-flash-lite-preview-09-2025` primeiro

---

## 🔴 Modelo Gemma 3 27B não funciona

### Sintomas
```
Error: model not found
Error: invalid model name
```

### Soluções

1. **Use o nome EXATO do modelo:**
   ```bash
   # CORRETO ✅
   PICOCLAW_MODEL=gemma-3-27b-it
   
   # ERRADO ❌
   PICOCLAW_MODEL=gemma-3-27b
   PICOCLAW_MODEL=gemma3-27b-it
   PICOCLAW_MODEL=gemma-27b
   ```

2. **Verifique se o modelo está disponível na sua API key:**
   - Teste no [Google AI Studio](https://aistudio.google.com/)
   - Escolha o modelo `gemma-3-27b-it` no chat
   - Se funcionar lá, deve funcionar no PicoClaw

3. **Rebuild o container:**
   ```bash
   docker compose down
   docker compose up -d --build
   ```

---

## 🔴 Config.json não persiste / Perde configurações

### Sintomas
- Configurações somem após redeploy
- Memória do agente (SOUL.md, MEMORY.md) é perdida
- Bot precisa fazer onboard novamente

### Soluções

1. **Verifique se o volume existe:**
   ```bash
   docker volume ls | grep picoclaw
   # Deve mostrar: picoclaw_data
   ```

2. **No Coolify, verifique a aba Storages:**
   - **Source:** `picoclaw_data` (ou um volume nomeado)
   - **Destination:** `/home/picoclaw/.picoclaw`
   - **Tipo:** Volume (não Bind Mount)

3. **Certifique-se de que o caminho está CORRETO:**
   ```bash
   # CORRETO ✅
   /home/picoclaw/.picoclaw
   
   # ERRADO ❌
   ~/.picoclaw
   /.picoclaw
   /root/.picoclaw
   ```

4. **NÃO edite o config.json manualmente!**
   - Use **variáveis de ambiente** no Coolify
   - O entrypoint injeta automaticamente
   - Edições manuais podem ser sobrescritas

---

## 🔴 Bot não responde no Telegram

### Sintomas
- Bot está online mas não responde
- Mensagens não chegam
- Bot não reage a comandos

### Soluções

1. **Verifique se seu User ID está na whitelist:**
   ```bash
   # Descubra seu User ID:
   # 1. Envie uma mensagem para @userinfobot
   # 2. Copie o ID (ex: 5619062865)
   # 3. Adicione na variável:
   TELEGRAM_ALLOW_FROM=5619062865
   ```

2. **Verifique se o bot token está correto:**
   ```bash
   # No Telegram, fale com @BotFather
   /mybots → Seu Bot → API Token
   
   # Cole o token na variável:
   TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHI...
   ```

3. **Veja os logs do container:**
   ```bash
   docker compose logs -f picoclaw
   # Procure por:
   # "✅ Telegram Bot configurado"
   # "Telegram enabled: true"
   ```

4. **Teste o bot manualmente:**
   - Envie `/start` para o bot
   - Veja se aparece nos logs
   - Se aparecer mas não responder, problema é no allow_from

---

## 🔴 Container não inicia / Crashloop

### Sintomas
```
Error: failed to start container
Container exits immediately
Restarts constantly
```

### Soluções

1. **Veja os logs completos:**
   ```bash
   docker compose logs picoclaw
   # Procure pela última mensagem de erro
   ```

2. **Verifique se a API key está definida:**
   ```bash
   # GEMINI_API_KEY é OBRIGATÓRIA
   docker compose exec picoclaw env | grep GEMINI
   ```

3. **Verifique permissões do volume:**
   ```bash
   docker compose exec picoclaw ls -la /home/picoclaw/.picoclaw
   # O dono deve ser: picoclaw:picoclaw
   ```

4. **Limpe e reconstrua:**
   ```bash
   docker compose down -v  # ⚠️ Remove volumes!
   docker compose up -d --build
   ```

---

## 🔴 Erro: "jq: command not found"

### Sintomas
```
/entrypoint.sh: line 20: jq: not found
```

### Solução

- Isso indica que o build falhou
- Rebuild completamente:
  ```bash
  docker compose build --no-cache
  docker compose up -d
  ```

---

## 🔴 Erro: "Port 18790 already in use"

### Sintomas
```
Error: port is already allocated
```

### Solução

1. **Identifique o processo usando a porta:**
   ```bash
   lsof -i :18790
   # ou
   netstat -tuln | grep 18790
   ```

2. **Pare o processo conflitante:**
   ```bash
   docker ps | grep 18790
   docker stop <container_id>
   ```

3. **Ou mude a porta no config.json:**
   - Mas lembre-se: o gateway só é necessário para uso via API
   - Para Telegram/Discord, a porta NÃO precisa ser exposta

---

## 🔴 Memória do agente não funciona

### Sintomas
- Bot não lembra de conversas anteriores
- SOUL.md e MEMORY.md vazios
- Agente "esquece" tudo

### Soluções

1. **Verifique se o volume está montado:**
   ```bash
   docker compose exec picoclaw ls -la /home/picoclaw/.picoclaw/workspace/
   # Deve conter: SOUL.md, MEMORY.md
   ```

2. **Verifique permissões:**
   ```bash
   docker compose exec picoclaw ls -la /home/picoclaw/.picoclaw/
   # Dono deve ser: picoclaw:picoclaw
   ```

3. **Forçe um novo onboard:**
   ```bash
   docker compose exec picoclaw rm /home/picoclaw/.picoclaw/workspace/SOUL.md
   docker compose restart picoclaw
   ```

---

## 🟡 Como verificar se está tudo OK

### Checklist de Saúde

```bash
# 1. Container está rodando?
docker compose ps
# Status deve ser: Up

# 2. Logs não mostram erros?
docker compose logs picoclaw | tail -50

# 3. API key foi injetada?
docker compose exec picoclaw cat /home/picoclaw/.picoclaw/config.json | jq '.providers.gemini.api_key'
# NãO deve estar vazio

# 4. Modelo está correto?
docker compose exec picoclaw cat /home/picoclaw/.picoclaw/config.json | jq '.agents.defaults.model'
# Deve mostrar o modelo configurado

# 5. Volume está persistente?
docker volume inspect picoclaw_data
# Deve mostrar informações do volume

# 6. Workspace existe?
docker compose exec picoclaw ls /home/picoclaw/.picoclaw/workspace/
# Deve conter: SOUL.md, MEMORY.md
```

---

## 📞 Ainda com problemas?

1. **Capture os logs completos:**
   ```bash
   docker compose logs picoclaw > picoclaw-logs.txt
   ```

2. **Verifique a configuração:**
   ```bash
   docker compose exec picoclaw cat /home/picoclaw/.picoclaw/config.json
   ```

3. **Liste as variáveis de ambiente:**
   ```bash
   docker compose exec picoclaw env | grep -E "(GEMINI|PICOCLAW|TELEGRAM|DISCORD)"
   ```

4. **Abra uma issue no GitHub:**
   - Inclua os logs
   - Descreva o problema
   - Informe versão do Docker
   - ⚠️ **Remova credenciais senseis antes de postar!**

---

## 📚 Recursos Úteis

- [PicoClaw Original](https://github.com/sipeed/picoclaw)
- [Google AI Studio](https://aistudio.google.com/)
- [Coolify Docs](https://coolify.io/docs)
- [Docker Compose Docs](https://docs.docker.com/compose/)
