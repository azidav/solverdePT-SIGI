import sql from '~~/server/utils/db'
import { H3Event } from 'h3'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { getUserFromEvent } from '~~/server/utils/auth'

const JWT_SECRET = process.env.JWT_SECRET || 'sv-secret-AJDOS165fs'
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 60 * 60 // seconds

export default defineEventHandler(async (event: H3Event) => {
  try {
    const body = await readBody(event)
    const { currentPassword, newPassword } = body || {}

    if (!currentPassword || !newPassword) {
      throw createError({ statusCode: 400, message: 'currentPassword and newPassword are required' })
    }

    if (typeof currentPassword !== 'string' || typeof newPassword !== 'string') {
      throw createError({ statusCode: 400, message: 'Passwords must be strings' })
    }

    const curr = currentPassword.trim()
    const next = newPassword.trim()

    if (curr.length < 4) {
      throw createError({ statusCode: 400, message: 'currentPassword must be at least 4 characters' })
    }
    if (next.length < 4) {
      throw createError({ statusCode: 400, message: 'newPassword must be at least 4 characters' })
    }

    if (curr === next) {
      throw createError({ statusCode: 400, message: 'New password must be different from current password' })
    }

    const user = await getUserFromEvent(event)
    if (!user) {
      throw createError({ statusCode: 401, message: 'Not authenticated' })
    }

    const dbUsers = await sql`
      SELECT id, password, username, permission
      FROM users
      WHERE id = ${user.id}
      LIMIT 1
    `

    if (dbUsers.length === 0) {
      throw createError({ statusCode: 404, message: 'User not found' })
    }

    const dbUser = dbUsers[0]
    const isValid = await bcrypt.compare(curr, dbUser.password)
    if (!isValid) {
      throw createError({ statusCode: 401, message: 'Current password is incorrect' })
    }

    const saltRounds = 10
    const hashed = await bcrypt.hash(next, saltRounds)

    await sql`
      UPDATE users
      SET password = ${hashed}, must_change_password = false, updated_at = ${new Date()}
      WHERE id = ${user.id}
    `

    // Issue fresh token — must_change_password cleared
    const payload = {
      id: dbUser.id,
      username: dbUser.username,
      permission: dbUser.permission,
      must_change_password: false
    }
    const token = (jwt as any).sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })
    const maxAge = Number(JWT_EXPIRES_IN)
    const secureFlag = process.env.NODE_ENV === 'production' ? '; Secure' : ''
    const cookieStr = `auth.token=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secureFlag}`
    event.node.res.setHeader('Set-Cookie', cookieStr)

    return { success: true, must_change_password: false }
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    const customError = error as any
    throw createError({ statusCode: customError.statusCode || 500, message: customError.message || 'Internal server error' })
  }
})
