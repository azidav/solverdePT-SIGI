import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { sendAccountActivationEmail } from '~~/server/utils/email'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  if ((currentUser as any).permission !== 0) throw createError({ statusCode: 403, message: 'Apenas administradores' })

  const userId = parseInt(getRouterParam(event, 'id') || '')
  if (isNaN(userId)) throw createError({ statusCode: 400, message: 'ID inválido' })

  const [user] = await sql<{ id: number, name: string, username: string, email: string, status: number }[]>`
    SELECT id, name, username, email, status FROM users WHERE id = ${userId}
  `
  if (!user) throw createError({ statusCode: 404, message: 'Utilizador não encontrado' })
  if (user.status !== 2) throw createError({ statusCode: 422, message: 'Utilizador não está pendente de ativação' })
  if (!user.email) throw createError({ statusCode: 422, message: 'Utilizador não tem email configurado' })

  // Invalidate any existing tokens and create a fresh one
  await sql`DELETE FROM password_reset_tokens WHERE user_id = ${userId}`

  const token = randomBytes(32).toString('hex')
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)

  await sql`
    INSERT INTO password_reset_tokens (user_id, token, expires_at)
    VALUES (${userId}, ${token}, ${expiresAt})
  `

  const host = event.node.req.headers['host'] || 'localhost:3000'
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'
  const activationUrl = `${protocol}://${host}/reset-password?token=${token}`

  await sendAccountActivationEmail(user.email as string, user.name as string, user.username as string, activationUrl)

  return { success: true }
})
