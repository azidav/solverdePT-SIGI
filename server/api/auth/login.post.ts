import sql from '~~/server/utils/db'
import { H3Event } from 'h3'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { createAuditLog } from '~~/server/utils/audit'

const JWT_SECRET = process.env.JWT_SECRET || 'sv-secret-AJDOS165fs'
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 8 * 60 * 60 // 8 hours

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
        u.permission, u.status, u.role_id, u.must_change_password,
        r.id as role_id, r.name as role_name, r.description as role_description
      FROM users u
      LEFT JOIN roles r ON u.role_id = r.id
      WHERE u.username = ${username}
      AND u.status >= 0
      LIMIT 1
    `

    if (users.length === 0) {
      throw createError({
        statusCode: 401,
        message: 'Credenciais inválidas'
      })
    }

    const user = users[0]

    // Check activation status before touching password (pending users have NULL password)
    if (user.status === 2) {
      throw createError({
        statusCode: 401,
        message: 'Conta não ativada. Verifica o teu email para definires a tua password.'
      })
    }

    if (user.status === 0) {
      throw createError({
        statusCode: 401,
        message: 'Conta desativada. Contacte o administrador.'
      })
    }

    // Verify password
    const isValidPassword = user.password && await bcrypt.compare(password, user.password)

    if (!isValidPassword) {
      throw createError({
        statusCode: 401,
        message: 'Credenciais inválidas'
      })
    }

    // Create JWT token
    const payload = {
      id: user.id,
      username: user.username,
      permission: user.permission,
      role_id: user.role_id,
      must_change_password: user.must_change_password ?? false
    }
    const token = (jwt as any).sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })

    // Audit log
    await createAuditLog(event, {
      userId: user.id,
      userName: user.name,
      action: 'LOGIN',
      entityType: 'SESSION',
      entityName: user.username
    })

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
        must_change_password: user.must_change_password ?? false,
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
