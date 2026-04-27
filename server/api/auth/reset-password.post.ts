import sql from '~~/server/utils/db'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'sv-secret-AJDOS165fs'
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 60 * 60

export default defineEventHandler(async (event) => {
  const { token, password } = await readBody(event)

  if (!token || !password) {
    throw createError({ statusCode: 400, message: 'Token e password obrigatórios' })
  }

  if (password.length < 6) {
    throw createError({ statusCode: 400, message: 'A password deve ter pelo menos 6 caracteres' })
  }

  const rows = await sql`
    SELECT t.id, t.user_id, t.expires_at, t.used_at,
           u.id as uid, u.username, u.name, u.email, u.permission, u.status, u.role_id
    FROM password_reset_tokens t
    JOIN users u ON t.user_id = u.id
    WHERE t.token = ${token}
    LIMIT 1
  `

  if (rows.length === 0) {
    throw createError({ statusCode: 400, message: 'Link inválido ou expirado' })
  }

  const row = rows[0]

  if (row.used_at) {
    throw createError({ statusCode: 400, message: 'Este link já foi utilizado' })
  }

  if (new Date(row.expires_at) < new Date()) {
    throw createError({ statusCode: 400, message: 'Link expirado. Solicite um novo.' })
  }

  const hashedPassword = await bcrypt.hash(password, 10)

  // Set password, activate account (status 0 → 1), clear must_change_password
  await sql`
    UPDATE users
    SET password = ${hashedPassword}, status = GREATEST(status, 1), must_change_password = false, updated_at = NOW()
    WHERE id = ${row.user_id}
  `
  await sql`UPDATE password_reset_tokens SET used_at = NOW() WHERE id = ${row.id}`

  // Create session exactly like login does
  const payload = { id: row.uid, username: row.username, permission: row.permission, role_id: row.role_id, must_change_password: false }
  const jwtToken = (jwt as any).sign(payload, JWT_SECRET, { expiresIn: Number(JWT_EXPIRES_IN) })

  const maxAge = Number(JWT_EXPIRES_IN)
  const secureFlag = process.env.NODE_ENV === 'production' ? '; Secure' : ''
  const cookieStr = `auth.token=${encodeURIComponent(jwtToken)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secureFlag}`
  event.node.res.setHeader('Set-Cookie', cookieStr)

  return {
    success: true,
    user: {
      id: row.uid,
      username: row.username,
      name: row.name,
      email: row.email,
      permission: row.permission,
      status: Math.max(row.status, 1),
      must_change_password: false,
      role_id: row.role_id
    }
  }
})
