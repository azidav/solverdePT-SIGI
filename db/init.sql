-- =====================================================
-- SolverdePT Database Schema
-- Single-Tenant Internal Management Platform with RBAC
-- =====================================================

-- =====================================================
-- ROLES TABLE (Sistema de Roles Dinâmico)
-- =====================================================
CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_roles_name ON roles(name);

-- =====================================================
-- PERMISSIONS TABLE (Vocabulário de Ações)
-- =====================================================
CREATE TABLE IF NOT EXISTS permissions (
  id SERIAL PRIMARY KEY,
  code VARCHAR(100) UNIQUE NOT NULL,
  description TEXT NOT NULL,
  module VARCHAR(50) NOT NULL,
  action VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module);
CREATE INDEX IF NOT EXISTS idx_permissions_code ON permissions(code);

-- =====================================================
-- ROLE_PERMISSIONS TABLE (Junction M2M)
-- =====================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id INT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- =====================================================
-- USERS TABLE (Atualizada com role_id)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  department VARCHAR(100),
  role_id INT REFERENCES roles(id) ON DELETE SET NULL,
  permission INT DEFAULT 2,
  status INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_permission ON users(permission);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);

-- =====================================================
-- SEED DATA: Roles
-- =====================================================
INSERT INTO roles (name, description, is_system)
VALUES
  ('Admin', 'Administrador com acesso total ao sistema', TRUE),
  ('Manager', 'Gestor de equipa com permissões alargadas', TRUE),
  ('Employee', 'Colaborador padrão', TRUE),
  ('Restricted', 'Utilizador com acesso limitado ao sistema', TRUE);

-- =====================================================
-- SEED DATA: Permissions
-- =====================================================
INSERT INTO permissions (code, description, module, action)
VALUES
  -- VACATION (Férias)
  ('VACATION:VIEW_OWN', 'Ver apenas as minhas férias', 'VACATION', 'VIEW_OWN'),
  ('VACATION:VIEW_TEAM', 'Ver férias da equipa', 'VACATION', 'VIEW_TEAM'),
  ('VACATION:CREATE', 'Criar pedido de férias', 'VACATION', 'CREATE'),
  ('VACATION:APPROVE', 'Aprovar pedidos de férias', 'VACATION', 'APPROVE'),
  ('VACATION:CONFIG_PERIODS', 'Configurar períodos globais de férias', 'VACATION', 'CONFIG_PERIODS'),

  -- EQUIPMENT (Equipamentos)
  ('EQUIPMENT:VIEW', 'Consultar inventário de equipamentos', 'EQUIPMENT', 'VIEW'),
  ('EQUIPMENT:CREATE', 'Criar novo equipamento', 'EQUIPMENT', 'CREATE'),
  ('EQUIPMENT:UPDATE', 'Editar equipamento', 'EQUIPMENT', 'UPDATE'),
  ('EQUIPMENT:DELETE', 'Eliminar equipamento', 'EQUIPMENT', 'DELETE'),
  ('EQUIPMENT:ASSIGN', 'Atribuir equipamento a colaborador', 'EQUIPMENT', 'ASSIGN'),

  -- ROOMS (Salas de Reunião)
  ('ROOMS:VIEW', 'Ver salas de reunião disponíveis', 'ROOMS', 'VIEW'),
  ('ROOMS:RESERVE', 'Fazer reserva de sala', 'ROOMS', 'RESERVE'),
  ('ROOMS:CANCEL_OWN', 'Cancelar própria reserva', 'ROOMS', 'CANCEL_OWN'),
  ('ROOMS:CANCEL_ANY', 'Cancelar qualquer reserva', 'ROOMS', 'CANCEL_ANY'),
  ('ROOMS:MANAGE', 'Gerir salas e disponibilidade', 'ROOMS', 'MANAGE'),

  -- SETTINGS (Definições)
  ('SETTINGS:VIEW', 'Ver definições do sistema', 'SETTINGS', 'VIEW'),
  ('SETTINGS:CHANGE', 'Alterar definições do sistema', 'SETTINGS', 'CHANGE'),
  ('SETTINGS:MANAGE_USERS', 'Gerir utilizadores', 'SETTINGS', 'MANAGE_USERS'),
  ('SETTINGS:MANAGE_ROLES', 'Gerir roles e permissões', 'SETTINGS', 'MANAGE_ROLES');

-- =====================================================
-- SEED DATA: Assign Permissions to Roles
-- =====================================================
-- Admin: Todas as permissões
INSERT INTO role_permissions (role_id, permission_id)
SELECT
  (SELECT id FROM roles WHERE name = 'Admin'),
  id
FROM permissions;

-- Manager: Tudo menos SETTINGS gerais
INSERT INTO role_permissions (role_id, permission_id)
SELECT
  (SELECT id FROM roles WHERE name = 'Manager'),
  id
FROM permissions
WHERE code NOT IN ('SETTINGS:CHANGE', 'SETTINGS:MANAGE_USERS', 'SETTINGS:MANAGE_ROLES');

-- Employee: Apenas ações de utilizador comum
INSERT INTO role_permissions (role_id, permission_id)
SELECT
  (SELECT id FROM roles WHERE name = 'Employee'),
  id
FROM permissions
WHERE code IN (
  'VACATION:VIEW_OWN', 'VACATION:CREATE',
  'EQUIPMENT:VIEW',
  'ROOMS:VIEW', 'ROOMS:RESERVE', 'ROOMS:CANCEL_OWN',
  'SETTINGS:VIEW'
);

-- Restricted: Apenas leitura
INSERT INTO role_permissions (role_id, permission_id)
SELECT
  (SELECT id FROM roles WHERE name = 'Restricted'),
  id
FROM permissions
WHERE code IN (
  'VACATION:VIEW_OWN',
  'EQUIPMENT:VIEW',
  'ROOMS:VIEW',
  'SETTINGS:VIEW'
);

-- =====================================================
-- SEED DATA: Users
-- =====================================================
-- Insert default users (password: admin123)
INSERT INTO users (username, password, name, email, department, role_id, permission, status)
VALUES
  ('admin', '$2b$10$xn/YpyF2OAwALd8gicGoCOcMcV5Q5ZSnyV9tD9nbXMRjU9O48uKVS', 'Administrador', 'admin@solverdept.pt', 'IT', (SELECT id FROM roles WHERE name = 'Admin'), 0, 1),
  ('manager', '$2b$10$xn/YpyF2OAwALd8gicGoCOcMcV5Q5ZSnyV9tD9nbXMRjU9O48uKVS', 'Gestor', 'manager@solverdept.pt', 'Operations', (SELECT id FROM roles WHERE name = 'Manager'), 1, 1),
  ('employee', '$2b$10$xn/YpyF2OAwALd8gicGoCOcMcV5Q5ZSnyV9tD9nbXMRjU9O48uKVS', 'João Silva', 'joao@solverdept.pt', 'Sales', (SELECT id FROM roles WHERE name = 'Employee'), 2, 1);


-- =====================================================
-- Migration: Multi-Role Support & Audit Logs
-- Date: 2026-03-17
-- =====================================================

-- =====================================================
-- USER_ROLES TABLE (Many-to-Many: Users <-> Roles)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_roles (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP DEFAULT NOW(),
  assigned_by INT REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE(user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);

-- =====================================================
-- AUDIT_LOGS TABLE (Sistema de Auditoria)
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE SET NULL,
  user_name VARCHAR(150),
  action VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT,
  entity_name VARCHAR(255),
  old_values JSONB,
  new_values JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- =====================================================
-- MIGRATE: Copy existing role_id to user_roles table
-- =====================================================
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT id, role_id, NOW()
FROM users
WHERE role_id IS NOT NULL
ON CONFLICT (user_id, role_id) DO NOTHING;


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

INSERT INTO config_variables (section, key, label, value, is_secret, description, input_type) VALUES
  ('email', 'smtp_host',     'SMTP Host',          '',      false, 'Endereço do servidor SMTP (ex: smtp.gmail.com)',     'text'),
  ('email', 'smtp_port',     'SMTP Port',           '587',   false, 'Porta SMTP (25, 465, 587)',                         'number'),
  ('email', 'smtp_secure',   'Usar SSL/TLS',        'false', false, 'Activar conexão segura SSL/TLS (porta 465)',        'checkbox'),
  ('email', 'smtp_user',     'Utilizador SMTP',     '',      false, 'Email ou utilizador de autenticação',               'text'),
  ('email', 'smtp_password', 'Password SMTP',       '',      true,  'Password de autenticação SMTP',                     'password'),
  ('email', 'from_email',    'Email de Origem',     '',      false, 'Endereço de email do remetente',                    'email'),
  ('email', 'from_name',     'Nome de Origem',      'Sistema', false, 'Nome que aparece como remetente',                 'text')
ON CONFLICT (key) DO NOTHING;



CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reset_tokens_token ON password_reset_tokens(token);

ALTER TABLE users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;
