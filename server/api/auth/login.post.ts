import sql from '~~/server/utils/db'
import { H3Event } from 'h3'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'changeme'
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 60 * 60 // seconds

export default defineEventHandler(async (event: H3Event) => {
  try {
    const { username, password } = await readBody(event)

    if (!username || !password) {
      throw createError({
        statusCode: 400,
        message: 'Utilizador e password necessárias'
      })
    }

    const users = await sql`
      SELECT
        u.id, u.username, u.password, u.name, u.email, u.department,
        u.permission, u.status, u.role_id,
        r.id as role_id, r.name as role_name, r.description as role_description
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      WHERE u.username = ${username}
      AND u.status IN (1,0)
      LIMIT 1
    `

    if (users.length === 0) {
      throw createError({
        statusCode: 401,
        message: 'Credenciais inválidas'
      })
    }

    const user = users[0]

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password)

    if (!isValidPassword) {
      throw createError({
        statusCode: 401,
        message: 'Credenciais inválidas'
      })
    }

    // Check if account is active
    if (user.status === 0) {
      throw createError({
        statusCode: 401,
        message: 'Conta por validar'
      })
    }

    // Create JWT token
    const payload = {
      id: user.id,
      username: user.username,
      permission: user.permission,
      role_id: user.role_id
    }
    const token = (jwt as any).sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })

    // Set httpOnly cookie
    const maxAge = Number(JWT_EXPIRES_IN)
    const secureFlag = process.env.NODE_ENV === 'production' ? '; Secure' : ''
    const cookieStr = `auth.token=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secureFlag}`
    event.node.res.setHeader('Set-Cookie', cookieStr)

    return {
      user: {
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        department: user.department,
        permission: user.permission,
        status: user.status,
        role: {
          id: user.role_id,
          name: user.role_name,
          description: user.role_description
        }
      }
    }
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const customError = error as any
    throw createError({
      statusCode: customError.statusCode || 500,
      message: customError.message || 'Internal server error'
    })
  }
})
