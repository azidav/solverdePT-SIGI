import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission !== 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const { name, uses_balance = true, requires_approval_chain = true } = await readBody(event)
  if (!name?.trim()) throw createError({ statusCode: 400, message: 'Nome obrigatório' })

  // Generate a unique code from the name
  const base = name.trim().toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '')

  const [last] = await sql`SELECT COALESCE(MAX(sort_order), 0) AS max FROM vacation_types`
  const sortOrder = (last?.max as number ?? 0) + 1

  // Ensure code uniqueness by appending a number if needed
  let code = base
  let attempt = 1
  while (true) {
    const [exists] = await sql`SELECT 1 FROM vacation_types WHERE code = ${code}`
    if (!exists) break
    code = `${base}_${++attempt}`
  }

  const [row] = await sql`
    INSERT INTO vacation_types (name, code, uses_balance, requires_approval_chain, sort_order)
    VALUES (${name.trim()}, ${code}, ${!!uses_balance}, ${!!requires_approval_chain}, ${sortOrder})
    RETURNING *
  `
  return row
})
