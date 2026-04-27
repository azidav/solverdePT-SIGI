import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'
import { sendAccountCreatedEmail } from '~~/server/utils/email'
import bcrypt from 'bcrypt'

function generatePassword(length = 12): string {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#$%!'
  const bytes = randomBytes(length)
  return Array.from(bytes).map(b => chars[b % chars.length]).join('')
}

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if (currentUser.permission !== 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Only admin can create users' })
  }

  const body = await readBody(event)
  const { username, name, email, department, permission, status } = body

  if (!username || !name || !email) {
    throw createError({ statusCode: 400, message: 'Missing required fields' })
  }

  const plainPassword = generatePassword()
  const hashedPassword = await bcrypt.hash(plainPassword, 10)

  const result = await sql`
    INSERT INTO users (username, password, name, email, department, permission, status, must_change_password)
    VALUES (${username}, ${hashedPassword}, ${name}, ${email}, ${department || null}, ${permission || 2}, ${status || 1}, true)
    RETURNING id, username, name, email, department, permission, status
  `

  await logUserAction(event, currentUser, 'CREATE', 'USER', result[0].id, name)

  // Send welcome email (non-blocking — don't fail creation if email fails)
  sendAccountCreatedEmail(email, name, username, plainPassword).catch(err =>
    console.error('[Email] Falha ao enviar email de boas-vindas:', err)
  )

  return result[0]
})
