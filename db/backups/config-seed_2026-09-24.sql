-- ============================================================================
-- SIGI — Seed de configuração para PRODUÇÃO
-- Gerado a partir da BD de desenvolvimento em 2026-09-24.
--
-- O QUE FAZ:
--   - Repõe as definições úteis (horário das salas, duração de slot, folga de
--     aniversário, texto do Outlook) na tabela config_variables (upsert por key).
--   - Cria as 3 salas de reunião SÓ se a tabela ainda não tiver nenhuma
--     (não-destrutivo: se já houver salas, não mexe).
--
-- O QUE NÃO FAZ (de propósito):
--   - NÃO traz passwords/segredos (SMTP, MS Graph) — configura-os na app, em
--     Definições, com o email/credenciais DA EMPRESA.
--   - NÃO traz utilizadores de teste — o admin inicial vem do init.sql.
--   - MS Graph fica DESATIVADO (estava com dados de teste inválidos).
--
-- COMO APLICAR (depois da stack a correr):
--   cat config-seed_2026-09-24.sql | docker exec -i sigi_postgres psql -U sigi -d sigi_prod
--   (ajusta 'sigi' / 'sigi_prod' se mudaste POSTGRES_USER / POSTGRES_DB)
-- ============================================================================

-- === Definições (as chaves já existem em produção, via update.sql; só atualiza o valor) ===
UPDATE config_variables SET value = '08:00'                                                   WHERE key = 'booking_start';
UPDATE config_variables SET value = '23:30'                                                   WHERE key = 'booking_end';
UPDATE config_variables SET value = '30'                                                      WHERE key = 'slot_duration';
UPDATE config_variables SET value = 'Reunião agendada através do sistema de salas de reunião.' WHERE key = 'outlook_default_body';
UPDATE config_variables SET value = 'true'                                                    WHERE key = 'vacation_birthday_enabled';
UPDATE config_variables SET value = 'smtp.gmail.com'                                          WHERE key = 'smtp_host';
UPDATE config_variables SET value = '587'                                                     WHERE key = 'smtp_port';
UPDATE config_variables SET value = 'false'                                                   WHERE key = 'smtp_secure';
UPDATE config_variables SET value = 'Sistema SIGI'                                            WHERE key = 'from_name';
-- MS Graph desativado em produção (reconfigurar na app se necessário)
UPDATE config_variables SET value = 'false'                                                   WHERE key = 'msgraph_enabled';

-- === Salas de reunião (só se não existir nenhuma) ===
INSERT INTO meeting_rooms (name, description, capacity, location, amenities, status)
SELECT * FROM (VALUES
  ('Sala 1', NULL, 10, 'Piso 1', 'TV 65", Quadro Branco, Sofá', 'active'),
  ('Sala 2', NULL,  8, NULL,     'TV 43"',                      'active'),
  ('Sala 3', NULL,  4, 'Piso 2', 'TV 43"',                      'active')
) AS v(name, description, capacity, location, amenities, status)
WHERE NOT EXISTS (SELECT 1 FROM meeting_rooms);
