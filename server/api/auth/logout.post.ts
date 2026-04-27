import { getUserFromEvent } from '~~/server/utils/auth'
import { createAuditLog } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  // Read user before clearing the cookie so we can audit who logged out
  const user = await getUserFromEvent(event).catch(() => null)

  const cookieStr = `auth.token=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`
  event.node.res.setHeader('Set-Cookie', cookieStr)

  if (user) {
    await createAuditLog(event, {
      userId: user.id,
      userName: user.name,
      action: 'LOGOUT',
      entityType: 'SESSION',
      entityName: user.username
    })
  }

  return { ok: true }
})
