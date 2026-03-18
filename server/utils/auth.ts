import jwt from 'jsonwebtoken'
import sql from '~~/server/utils/db'

const JWT_SECRET = process.env.JWT_SECRET || 'changeme'

export const verifyToken = (token?: string | null) => {
  if (!token) return null
  try {
    return jwt.verify(token, JWT_SECRET) as {
      id: number
      username?: string
      permission?: number
      role_id?: number
    }
  } catch (e) {
    return null
  }
}

export const getUserFromEvent = async (event: any) => {
  // Parse auth token from cookie header
  const token = event?.node?.req?.headers?.cookie
    ? (event.node.req.headers.cookie || '')
        .split(';')
        .map((s: string) => s.trim())
        .find((s: string) => s.startsWith('auth.token='))
        ?.split('=')[1]
    : undefined

  const rawToken = token ? decodeURIComponent(token) : undefined
  const payload = verifyToken(rawToken)
  if (!payload) return null

  const users = await sql`
    SELECT
      u.id, u.username, u.name, u.email, u.department,
      u.permission, u.status, u.role_id,
      u.created_at, u.updated_at,
      r.id as role_id, r.name as role_name, r.description as role_description
    FROM users u
    LEFT JOIN roles r ON u.role_id = r.id
    WHERE u.id = ${payload.id}
    LIMIT 1
  `

  return users[0] ?? null
}
