import sql from "~~/server/utils/db"
import { getUserFromEvent } from "~~/server/utils/auth"
import { logUserAction } from '~~/server/utils/audit'
import bcrypt from 'bcrypt'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Only Admin can create users
  if (currentUser.permission !== 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Only admin can create users' })
  }

  const body = await readBody(event)
  const { username, password, name, email, department, permission, status } = body

  if (!username || !password || !name || !email) {
    throw createError({ statusCode: 400, message: 'Missing required fields' })
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10)

  const result = await sql`
    INSERT INTO users (username, password, name, email, department, permission, status)
    VALUES (${username}, ${hashedPassword}, ${name}, ${email}, ${department || null}, ${permission || 2}, ${status || 1})
    RETURNING id, username, name, email, department, permission, status
  `

  // Audit log
  await logUserAction(
    event,
    currentUser,
    'CREATE',
    'USER',
    result[0].id,
    name
  )

  return result[0]
})
