-- Pending migrations go here

-- Meeting Rooms module
CREATE TABLE IF NOT EXISTS meeting_rooms (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  image_url VARCHAR(500),
  capacity INT DEFAULT 0,
  location VARCHAR(200),
  amenities TEXT,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS room_reservations (
  id SERIAL PRIMARY KEY,
  room_id INT NOT NULL REFERENCES meeting_rooms(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  guest_name VARCHAR(150),
  booking_token VARCHAR(255) UNIQUE,
  token_expires_at TIMESTAMPTZ,
  meeting_title VARCHAR(255) NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meeting_rooms_status ON meeting_rooms(status);
CREATE INDEX IF NOT EXISTS idx_room_reservations_room_id ON room_reservations(room_id);
CREATE INDEX IF NOT EXISTS idx_room_reservations_start_time ON room_reservations(start_time);
CREATE INDEX IF NOT EXISTS idx_room_reservations_user_id ON room_reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_room_reservations_token ON room_reservations(booking_token);

-- Add job_title column to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS job_title VARCHAR(150);

-- Config variables table
CREATE TABLE IF NOT EXISTS config_variables (
  id SERIAL PRIMARY KEY,
  section VARCHAR(100) NOT NULL,
  key VARCHAR(100) NOT NULL UNIQUE,
  label VARCHAR(255) NOT NULL,
  value TEXT DEFAULT '',
  is_secret BOOLEAN DEFAULT false,
  description VARCHAR(500),
  input_type VARCHAR(50) DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default email config variables
INSERT INTO config_variables (section, key, label, value, is_secret, description, input_type) VALUES
  ('email', 'smtp_host',     'SMTP Host',          '',      false, 'Endereço do servidor SMTP (ex: smtp.gmail.com)',     'text'),
  ('email', 'smtp_port',     'SMTP Port',           '587',   false, 'Porta SMTP (25, 465, 587)',                         'number'),
  ('email', 'smtp_secure',   'Usar SSL/TLS',        'false', false, 'Activar conexão segura SSL/TLS (porta 465)',        'checkbox'),
  ('email', 'smtp_user',     'Utilizador SMTP',     '',      false, 'Email ou utilizador de autenticação',               'text'),
  ('email', 'smtp_password', 'Password SMTP',       '',      true,  'Password de autenticação SMTP',                     'password'),
  ('email', 'from_email',    'Email de Origem',     '',      false, 'Endereço de email do remetente',                    'email'),
  ('email', 'from_name',     'Nome de Origem',      'Sistema', false, 'Nome que aparece como remetente',                 'text')
ON CONFLICT (key) DO NOTHING;

-- Microsoft Graph Integration (bidirectional Outlook sync)
ALTER TABLE room_reservations ADD COLUMN IF NOT EXISTS ical_uid TEXT;
ALTER TABLE room_reservations ADD COLUMN IF NOT EXISTS change_key TEXT;
ALTER TABLE room_reservations ADD COLUMN IF NOT EXISTS graph_event_id TEXT;
ALTER TABLE room_reservations ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'platform';

CREATE UNIQUE INDEX IF NOT EXISTS idx_room_reservations_ical_uid
  ON room_reservations(ical_uid) WHERE ical_uid IS NOT NULL;

-- Maps internal room IDs to Outlook resource mailbox addresses
CREATE TABLE IF NOT EXISTS room_graph_mappings (
  id SERIAL PRIMARY KEY,
  room_id INT NOT NULL REFERENCES meeting_rooms(id) ON DELETE CASCADE,
  resource_email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tracks active Microsoft Graph webhook subscriptions
CREATE TABLE IF NOT EXISTS msgraph_subscriptions (
  id SERIAL PRIMARY KEY,
  subscription_id VARCHAR(255) NOT NULL UNIQUE,
  room_id INT REFERENCES meeting_rooms(id) ON DELETE SET NULL,
  resource_email VARCHAR(255) NOT NULL,
  expiration_datetime TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO config_variables (section, key, label, value, is_secret, description, input_type) VALUES
  ('msgraph', 'msgraph_enabled',        'Integração Ativa',       'false', false, 'Activar sincronização bidirecional com Microsoft 365',              'checkbox'),
  ('msgraph', 'msgraph_tenant_id',      'Tenant ID (Azure AD)',   '',      false, 'ID do tenant do Azure Active Directory (Directory ID)',             'text'),
  ('msgraph', 'msgraph_client_id',      'Client ID (App ID)',     '',      false, 'ID da aplicação registada no Azure AD (Application ID)',            'text'),
  ('msgraph', 'msgraph_client_secret',  'Client Secret',          '',      true,  'Segredo da aplicação — gerar em Azure AD → Certificates & secrets', 'password'),
  ('msgraph', 'msgraph_webhook_secret', 'Webhook clientState',    '',      false, 'Valor secreto para validar notificações recebidas do Graph',        'text')
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- Leave Management System
-- ============================================================

-- Extend users with hire date and birthday for accrual engine
ALTER TABLE users ADD COLUMN IF NOT EXISTS hire_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS birthday DATE;

-- Core leave requests
CREATE TABLE IF NOT EXISTS vacation_requests (
  id SERIAL PRIMARY KEY,
  employee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL DEFAULT 'annual',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_count INT NOT NULL,
  reason TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  current_approval_step INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vacation_requests_employee_id ON vacation_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_vacation_requests_status ON vacation_requests(status);
CREATE INDEX IF NOT EXISTS idx_vacation_requests_start_date ON vacation_requests(start_date);

-- Immutable decision history per request
CREATE TABLE IF NOT EXISTS vacation_request_history (
  id SERIAL PRIMARY KEY,
  request_id INT NOT NULL REFERENCES vacation_requests(id) ON DELETE CASCADE,
  actor_id INT REFERENCES users(id) ON DELETE SET NULL,
  actor_name VARCHAR(150),
  old_status VARCHAR(20),
  new_status VARCHAR(20),
  step_order INT,
  comment TEXT,
  actioned_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vacation_request_history_request_id ON vacation_request_history(request_id);

-- Per-employee annual leave balance
CREATE TABLE IF NOT EXISTS leave_balances (
  id SERIAL PRIMARY KEY,
  employee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  year INT NOT NULL,
  base_days INT NOT NULL DEFAULT 22,
  seniority_bonus INT NOT NULL DEFAULT 0,
  birthday_bonus INT NOT NULL DEFAULT 0,
  used_days INT NOT NULL DEFAULT 0,
  pending_days INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, year)
);

-- Configurable n-tier approval chain template
CREATE TABLE IF NOT EXISTS approval_workflow_config (
  id SERIAL PRIMARY KEY,
  step_order INT NOT NULL UNIQUE,
  role_name VARCHAR(100) NOT NULL,
  required_permission VARCHAR(100) NOT NULL DEFAULT 'VACATION:APPROVE',
  skip_after_hours INT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default 2-tier chain: Manager (48h skip) → Admin (no skip)
INSERT INTO approval_workflow_config (step_order, role_name, required_permission, skip_after_hours)
VALUES
  (1, 'Gestor',        'VACATION:APPROVE', 48),
  (2, 'Administrador', 'VACATION:APPROVE', NULL)
ON CONFLICT (step_order) DO NOTHING;

-- Approval steps instantiated per request
CREATE TABLE IF NOT EXISTS approval_workflow_steps (
  id SERIAL PRIMARY KEY,
  request_id INT NOT NULL REFERENCES vacation_requests(id) ON DELETE CASCADE,
  step_order INT NOT NULL,
  approver_id INT REFERENCES users(id) ON DELETE SET NULL,
  role_name VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  comment TEXT,
  actioned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_approval_steps_request_id ON approval_workflow_steps(request_id);
CREATE INDEX IF NOT EXISTS idx_approval_steps_status ON approval_workflow_steps(status);

-- Blackout / restricted date periods
CREATE TABLE IF NOT EXISTS blackout_dates (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  department VARCHAR(100),
  created_by INT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blackout_dates_start_date ON blackout_dates(start_date);
CREATE INDEX IF NOT EXISTS idx_blackout_dates_end_date ON blackout_dates(end_date);

-- ============================================================
-- Positions (hierarchical org chart)
-- ============================================================

CREATE TABLE IF NOT EXISTS positions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  parent_id INT REFERENCES positions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_positions_parent_id ON positions(parent_id);

ALTER TABLE users ADD COLUMN IF NOT EXISTS position_id INT REFERENCES positions(id) ON DELETE SET NULL;

-- Ver Níveis de Aprovação permission
INSERT INTO permissions (code, description, module, action)
VALUES ('VACATION:VIEW_LEVELS', 'Ver Níveis de Aprovação', 'VACATION', 'VIEW_LEVELS')
ON CONFLICT (code) DO NOTHING;

-- Carryover days column on leave_balances
ALTER TABLE leave_balances ADD COLUMN IF NOT EXISTS carryover_days INT NOT NULL DEFAULT 0;

-- Férias config variables
INSERT INTO config_variables (section, key, label, value, is_secret, description, input_type) VALUES
  ('ferias', 'vacation_birthday_enabled',     'Ativar folga de aniversário',                       'false', false, 'Conceder um dia de folga no dia de aniversário do colaborador',                         'checkbox'),
  ('ferias', 'vacation_seniority_1y_enabled',  'Dia extra após 1 ano de empresa',                   'true',  false, 'Conceder +1 dia de férias a colaboradores com pelo menos 1 ano de antiguidade',        'checkbox'),
  ('ferias', 'vacation_seniority_2y_enabled',  'Dia extra adicional após 2 anos de empresa',        'true',  false, 'Conceder mais +1 dia de férias a colaboradores com pelo menos 2 anos de antiguidade',  'checkbox')
ON CONFLICT (key) DO NOTHING;

-- Grant every permission to the Admin role (catches any permissions added after init.sql)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'Admin'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );
