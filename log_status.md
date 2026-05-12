DB — 2 new tables (meeting_rooms, room_reservations) with 3 seed rooms.

Server API (8 files):

GET /api/meeting-rooms — public list with live occupancy status; ?all=true shows inactive rooms for managers
POST/PUT/DELETE /api/meeting-rooms[/id] — room CRUD, requires ROOMS:MANAGE
GET /api/room-reservations?date= — public list grouped by date, shows booker name
POST /api/room-reservations — auth users need ROOMS:RESERVE; guests just need a name; strict double-booking check
DELETE /api/room-reservations/:id — auth users cancel own; ROOMS:CANCEL_ANY cancels any; guests need their booking_token (valid ≤10 min)
Frontend (7 files):

layouts/booking.vue — public layout with header, "Entrar" for guests, user info + Dashboard link for auth
composables/useGuestToken.ts — localStorage token store with auto-expiry
pages/meeting-rooms/index.vue — public booking page: room cards with live status, day schedule inline, booking modal, cancel buttons visible per permission/token
pages/meeting-rooms/manage/{index,new,[id]}.vue — room management using default layout
# Levantamento de Funcionalidades — SolverdePT SIGI
**Data:** 2026-04-30

---

## Autenticação & Sessões

- Login com username e password (JWT em cookie httpOnly)
- Logout com invalidação de sessão
- Recuperação de password via email (link com token, validade 1h)
- Definição de nova password via link de ativação
- Middleware global de autenticação em todas as rotas
- Modo de alteração forçada de password no primeiro acesso (`must_change_password`)
- Alteração voluntária de password nas definições
- Registo de eventos de LOGIN/LOGOUT nos audit logs

---

## Gestão de Utilizadores

- Listagem de utilizadores com pesquisa por username
- Criação de utilizador (sem password) → envia email com link de ativação (token 7 dias)
- Ativação de conta pelo próprio utilizador via link no email
- Edição de dados do utilizador (nome, email, cargo/função)
- Desativação / Ativação de conta (status 0 ↔ 1)
- Eliminação suave (soft delete, status = -1)
- Quatro estados de conta: **Pendente** (2), **Ativo** (1), **Inativo** (0), **Eliminado** (−1)
- Separação em tabs: Utilizadores ativos/pendentes, Desativados, Eliminados
- Associação de múltiplos grupos a cada utilizador (many-to-many)
- Reativação de conta desativada respeita estado pendente (sem password → volta a Pendente)

---

## Sistema de Permissões (RBAC)

- Grupos/Roles com nome, descrição e flag de sistema
- Permissões granulares por módulo e ação (ex: `ROOMS:RESERVE`, `SETTINGS:MANAGE_USERS`)
- Atribuição de permissões a grupos
- Associação de utilizadores a múltiplos grupos
- Verificação dual: frontend (ocultar UI) + backend (rejeitar chamada API)
- Página de gestão de grupos com editor de permissões
- Audit logs de todas as alterações de roles/permissões

---

## Email

- Envio de email de ativação de conta com link personalizado
- Envio de email de recuperação de password
- Modo de teste via Ethereal (preview URL no terminal)
- Modo produção via SMTP configurável nas definições
- Templates HTML com branding

---

## Definições do Sistema

- Accordion de configurações por secção (Email, Salas de Reunião)
- **Secção Email:** host SMTP, porta, SSL/TLS, utilizador, password, email/nome de origem
- **Secção Salas de Reunião:** duração mínima de reserva, hora de abertura, hora de encerramento, corpo padrão para Outlook
- Guardado por secção de forma independente

---

## Salas de Reunião

### Visualização Pública (guests + autenticados)
- Layout de dois painéis: lista de salas (esquerda) + detalhe/horário (direita)
- Layout responsivo: chips horizontais em mobile, sidebar em desktop
- Seletor de data para navegar entre dias
- Cada sala mostra: nome, estado (Livre/Ocupada), capacidade, equipamentos, descrição, e ocupação atual
- Lista de reservas do dia para a sala selecionada (título, horário, nome do reservante, descrição, badge de visitante)

### Reservas
- Reserva por utilizadores autenticados (ligada ao `user_id`)
- Reserva por visitantes sem conta (requer nome, gera `booking_token`)
- Token de convidado guardado em LocalStorage com validade de 10 minutos para cancelamento
- Dropdowns de hora (início e fim) gerados pelo intervalo configurado nas definições
- Hora de fim filtrada automaticamente: mínimo = hora início + duração mínima
- Horas passadas filtradas automaticamente quando a data selecionada é hoje
- Botão "Reservar" desativado para datas passadas e para hoje sem slots disponíveis
- Campo de descrição opcional na reserva
- Validação de double-booking no servidor
- Validação de reserva no passado no servidor
- Restrição de data mínima no seletor de data do formulário

### Cancelamento
- Confirmação antes de cancelar (modal "Tem a certeza?")
- Cancelamento pelo próprio (por `user_id` ou `booking_token` válido)
- Cancelamento de qualquer reserva por utilizadores com permissão `ROOMS:CANCEL_ANY`
- Token de visitante expira após 10 minutos (impossível cancelar depois)

### Integração Outlook
- Botão "Adicionar ao Outlook" no dropdown de cada reserva (3 pontos)
- Abre o Outlook Web com campos pré-preenchidos: título, corpo, hora início/fim, sala
- Corpo usa a descrição da reserva ou o texto padrão configurável nas definições
- Datas convertidas para hora local do utilizador

### Gestão de Salas (ROOMS:MANAGE)
- Listagem de salas (ativas e inativas)
- Criação de sala: nome, descrição, capacidade, equipamentos, estado
- Edição de sala
- Ativar/Desativar sala
- Eliminar sala (cascata: remove todas as reservas associadas)
- Dropdown de ações com 3 pontos (Editar, Ativar/Desativar, Eliminar)
- Nome da sala clicável para edição

---

## Navegação & Layout

- Sidebar colapsável e redimensionável (dashboard)
- Navegação condicional por permissões (links só aparecem se o utilizador tiver acesso)
- "Salas de Reunião" com sub-menu para quem tem `ROOMS:MANAGE` (Fazer Reserva + Gerir Salas)
- Pesquisa global (Cmd+K / Ctrl+K)
- Menu de utilizador com perfil e logout
- Layout público `booking` para visitantes (header simples com botão de login)
- Middleware que aplica layout `default` ou `booking` consoante a sessão
- Página de login com acesso direto às salas como visitante

---

## Homepage

- Saudação personalizada com nome do utilizador
- Lista das próximas reservas de sala do utilizador autenticado
- Destaque visual para reservas de hoje
- Estado vazio com atalho para reservar
- Link "Ver tudo" para a página de salas

---

## Audit Logs

- Registo automático de: criação/edição/eliminação de utilizadores, alterações de roles, login/logout
- Página de consulta com filtros por ação, tipo de entidade, utilizador e data
- Filtro de data predefinido para hoje
- Paginação
- Badge por tipo de entidade
- Acesso restrito a administradores (`SETTINGS:VIEW`)

---

## Stack Técnica

| Camada | Tecnologia |
|---|---|
| Framework | Nuxt 4.2 (Vue 3 + Nitro) |
| UI | Nuxt UI 4.1 (Reka UI + Tailwind CSS v4) |
| Base de dados | PostgreSQL 16 (Docker) |
| ORM/Query | `postgres` (tagged template SQL) |
| Autenticação | JWT (httpOnly cookie) + bcrypt |
| Estado | Pinia 3 |
| Validação | Zod v4 |
| Email | Nodemailer (Ethereal em dev, SMTP em prod) |
| Linguagem | TypeScript (full-stack) |
