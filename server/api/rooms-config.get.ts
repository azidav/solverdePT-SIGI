import sql from '~~/server/utils/db'

// Public endpoint — only exposes the non-sensitive rooms configuration
export default defineEventHandler(async () => {
  const rows = await sql`SELECT key, value FROM config_variables WHERE section = 'rooms'`
  const cfg: Record<string, string> = {}
  rows.forEach((r: { key: string; value: string }) => { cfg[r.key] = r.value })
  return {
    slot_duration: parseInt(cfg.slot_duration || '30'),
    booking_start: cfg.booking_start || '08:00',
    booking_end: cfg.booking_end || '22:00',
    outlook_default_body: cfg.outlook_default_body || 'Reunião agendada através do sistema de salas de reunião.'
  }
})
