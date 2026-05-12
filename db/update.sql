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
