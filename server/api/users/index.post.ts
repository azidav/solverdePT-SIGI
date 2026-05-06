import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'
import { sendAccountActivationEmail } from '~~/server/utils/email'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission !== 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Only admin can create users' })
  }

  const body = await readBody(event)
  const { username, name, email, department, permission } = body

  if (!username || !name || !email) {
    throw createError({ statusCode: 400, message: 'Missing required fields' })
  }

  // Create user with no password — status 2 (pending activation)
  const result = await sql`
    INSERT INTO users (username, password, name, email, department, permission, status, must_change_password)
    VALUES (${username}, NULL, ${name}, ${email}, ${department || null}, ${permission || 2}, 2, false)
    RETURNING id, username, name, email, department, permission, status
  `

  const userId = result[0].id
  await logUserAction(event, currentUser, 'CREATE', 'USER', userId, name)

  // Generate activation token (7-day expiry)
  const token = randomBytes(32).toString('hex')
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)

  await sql`
    INSERT INTO password_reset_tokens (user_id, token, expires_at)
    VALUES (${userId}, ${token}, ${expiresAt})
  `

  const host = event.node.req.headers['host'] || 'localhost:3000'
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'
  const activationUrl = `${protocol}://${host}/reset-password?token=${token}`

  // Send activation email (non-blocking)
  sendAccountActivationEmail(email, name, username, activationUrl).catch(err =>
    console.error('[Email] Falha ao enviar email de ativação:', err)
  )

  return result[0]
})
