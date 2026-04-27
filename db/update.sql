-- Pending migrations go here

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
