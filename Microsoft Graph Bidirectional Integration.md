# Microsoft Graph Bidirectional Integration

> Sincronização bidirecional entre Microsoft 365 (Outlook) e a plataforma de reservas de salas de reunião.
> Implementado em: 2026-05-01

---

## Regra de Ouro

**O Outlook é a origem da verdade para reservas feitas via Outlook**, mas a plataforma actua como espelho em tempo real. Reservas feitas na plataforma podem ser opcionalmente sincronizadas para o Outlook.

---

## Fluxo Lógico

### Outlook → Plataforma (via Webhook)

```
Utilizador reserva sala via Outlook
        ↓
Exchange verifica conflito (Tentative/Accepted)
        ↓
Microsoft Graph envia POST /api/webhook/msgraph
        ↓
Servidor valida clientState (webhook secret)
        ↓
GET ao Graph API para obter detalhes do evento
        ↓
Verifica icalUId (evitar duplicados) + changeKey (evitar versões antigas)
        ↓
Verifica conflito na DB (camada de segurança extra)
  ↙              ↘
Livre           Conflito com reserva da plataforma
  ↓                    ↓
INSERT           DELETE ao Graph API (cancela reunião no Outlook)
room_reservations
(source = 'outlook')
```

### Plataforma → Outlook (opcional)

```
Utilizador cria reserva na plataforma com add_to_outlook: true
        ↓
INSERT em room_reservations (dentro de transação com advisory lock)
        ↓
POST ao Graph API → cria evento no calendário da sala
        ↓
UPDATE room_reservations com graph_event_id, ical_uid, change_key
```

---

## Ficheiros Criados / Modificados

| Ficheiro | Tipo | Descrição |
|---|---|---|
| `db/update.sql` | Modificado | Migrações: colunas Graph em `room_reservations`, tabelas `room_graph_mappings` e `msgraph_subscriptions`, config vars |
| `server/utils/msgraph.ts` | Novo | Utilitário central: token cache, chamadas ao Graph API |
| `server/api/webhook/msgraph.post.ts` | Novo | Receptor do webhook do Microsoft Graph |
| `server/api/msgraph/room-mappings.get.ts` | Novo | Listar mapeamentos sala ↔ email de recurso |
| `server/api/msgraph/room-mappings.post.ts` | Novo | Criar mapeamento |
| `server/api/msgraph/room-mappings/[id].delete.ts` | Novo | Remover mapeamento |
| `server/api/msgraph/subscriptions.get.ts` | Novo | Listar subscrições de webhook |
| `server/api/msgraph/subscriptions.post.ts` | Novo | Criar subscrição para uma sala mapeada |
| `server/api/msgraph/subscriptions/[id].delete.ts` | Novo | Remover subscrição (também remove no Graph) |
| `server/api/msgraph/subscriptions/[id]/renew.post.ts` | Novo | Renovar subscrição (expira a cada 3 dias) |
| `server/api/room-reservations/index.post.ts` | Modificado | Transação com advisory lock + push opcional para Outlook |
| `app/components/settings/MsGraphSettings.vue` | Novo | UI de gestão: webhook URL, mapeamentos, subscrições |
| `app/pages/settings/index.vue` | Modificado | Nova secção "Integração Microsoft 365" no acordeão |

---

## Base de Dados

### Colunas adicionadas a `room_reservations`

| Coluna | Tipo | Descrição |
|---|---|---|
| `ical_uid` | `TEXT UNIQUE` | ID persistente da Microsoft — evita duplicados em reuniões recorrentes |
| `change_key` | `TEXT` | Versão do evento — ignora notificações de versões antigas |
| `graph_event_id` | `TEXT` | ID do evento no Graph (para operações futuras de update/delete) |
| `source` | `VARCHAR(20)` | `'platform'` (reserva na plataforma) ou `'outlook'` (sincronizado do Outlook) |

### Nova tabela `room_graph_mappings`

```sql
CREATE TABLE room_graph_mappings (
  id             SERIAL PRIMARY KEY,
  room_id        INT NOT NULL REFERENCES meeting_rooms(id) ON DELETE CASCADE,
  resource_email VARCHAR(255) NOT NULL UNIQUE,  -- ex: sala-a@empresa.pt
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
```

### Nova tabela `msgraph_subscriptions`

```sql
CREATE TABLE msgraph_subscriptions (
  id                   SERIAL PRIMARY KEY,
  subscription_id      VARCHAR(255) NOT NULL UNIQUE,
  room_id              INT REFERENCES meeting_rooms(id) ON DELETE SET NULL,
  resource_email       VARCHAR(255) NOT NULL,
  expiration_datetime  TIMESTAMPTZ NOT NULL,  -- máximo 3 dias no Graph
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);
```

### Config Variables (secção `msgraph`)

| Key | Descrição |
|---|---|
| `msgraph_enabled` | Activar/desactivar a integração (checkbox) |
| `msgraph_tenant_id` | Directory ID do Azure Active Directory |
| `msgraph_client_id` | Application ID da App Registration |
| `msgraph_client_secret` | Segredo da aplicação (secret) |
| `msgraph_webhook_secret` | Valor de `clientState` para validar notificações recebidas |

---

## API de Gestão

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/api/msgraph/room-mappings` | Listar mapeamentos sala ↔ email Outlook |
| `POST` | `/api/msgraph/room-mappings` | `{ room_id, resource_email }` — criar mapeamento |
| `DELETE` | `/api/msgraph/room-mappings/:id` | Remover mapeamento |
| `GET` | `/api/msgraph/subscriptions` | Listar subscrições activas |
| `POST` | `/api/msgraph/subscriptions` | `{ mapping_id }` — criar subscrição no Graph |
| `DELETE` | `/api/msgraph/subscriptions/:id` | Remover subscrição (Graph + DB) |
| `POST` | `/api/msgraph/subscriptions/:id/renew` | Renovar subscrição (nova expiração +3 dias) |
| `POST` | `/api/webhook/msgraph` | Receptor de notificações do Microsoft Graph |

---

## Autenticação Microsoft Graph

### Obter Access Token (Client Credentials Flow)

```typescript
POST https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

client_id={client_id}
&client_secret={client_secret}
&scope=https://graph.microsoft.com/.default
&grant_type=client_credentials
```

O token é válido por ~1 hora. A implementação em `server/utils/msgraph.ts` faz cache automático e renova 1 minuto antes da expiração.

### Criar Subscrição de Webhook

```typescript
POST https://graph.microsoft.com/v1.0/subscriptions
{
  "changeType": "created,updated,deleted",
  "notificationUrl": "https://[teu-dominio]/api/webhook/msgraph",
  "resource": "users/sala-a@empresa.pt/events",
  "expirationDateTime": "2026-05-04T10:00:00Z",
  "clientState": "[webhook-secret]"
}
```

---

## Payload Mock para Testes Locais

Envia este JSON via `POST /api/webhook/msgraph` para simular uma notificação do Graph sem acesso ao Azure AD:

```json
{
  "value": [
    {
      "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "subscriptionExpirationDateTime": "2026-05-04T10:00:00.0000000Z",
      "changeType": "created",
      "resource": "users/sala-a@empresa.pt/events/AAMkAGI2...",
      "resourceData": {
        "@odata.type": "#Microsoft.Graph.Event",
        "@odata.id": "Users/xxxxxxxx/Events/AAMkAGI2...",
        "@odata.etag": "W/\"abc123\"",
        "id": "AAMkAGI2..."
      },
      "clientState": "o-teu-webhook-secret"
    }
  ]
}
```

Para testar `deleted`, muda `"changeType": "deleted"` e certifica que o `id` corresponde a um `graph_event_id` existente na DB.

---

## Race Conditions

### Problema
Duas pessoas reservam a mesma sala ao mesmo milissegundo (plataforma ou Outlook).

### Solução implementada

**Reservas na plataforma** — transação PostgreSQL com advisory lock por sala:
```sql
BEGIN;
SELECT pg_advisory_xact_lock({room_id}::bigint);
-- verifica conflitos (nenhuma outra transação pode interferir para este room_id)
INSERT INTO room_reservations ...;
COMMIT;
```

**Reservas via Outlook** — a constraint `UNIQUE` em `ical_uid` garante que mesmo que duas instâncias do servidor processem a mesma notificação em simultâneo, apenas um INSERT terá sucesso. O segundo falhará silenciosamente.

**Conflito Outlook vs Plataforma** — o webhook verifica conflitos com reservas existentes da plataforma. Se existir conflito, envia `DELETE` ao Graph API para cancelar a reunião no Outlook.

---

## Renovação de Subscrições

As subscrições do Microsoft Graph expiram ao fim de **3 dias (4320 minutos)**. A implementação cria subscrições com expiração em 3 dias − 5 minutos como buffer.

**Opções para renovação automática:**
1. **Manual** — via UI em Definições → Integração Microsoft 365 → botão "Renovar"
2. **Automática futura** — pode-se adicionar um cron job no servidor que verifique `msgraph_subscriptions WHERE expiration_datetime < NOW() + INTERVAL '12 hours'` e renove

---

## Configuração no Azure AD (passos manuais)

1. **Azure Portal** → Azure Active Directory → App registrations → **New registration**
2. Nome: `SolverdePT-Rooms` (ou similar)
3. **API permissions** → Add permission → Microsoft Graph → **Application permissions** → `Calendars.ReadWrite`
4. Clica em **Grant admin consent**
5. **Certificates & secrets** → New client secret → copia o valor (só visível uma vez)
6. Preenche em **Definições → Integração Microsoft 365**:
   - Tenant ID: Azure AD → Overview → Directory (tenant) ID
   - Client ID: App registration → Application (client) ID
   - Client Secret: valor copiado no passo 5
   - Webhook clientState: qualquer string secreta (ex: `openssl rand -hex 32`)
7. Activa **Integração Ativa** e guarda
8. Em **Mapeamentos**, associa cada sala interna ao email da sua caixa de recurso Exchange
9. Clica **Subscrever webhook** em cada mapeamento para activar a sincronização em tempo real

> **Nota:** As caixas de recurso das salas devem ter licença **Exchange Online** activa no Microsoft 365.
