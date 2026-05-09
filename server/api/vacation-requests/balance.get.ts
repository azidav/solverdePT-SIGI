import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'
import { recalculateLeaveBalance } from '~~/server/utils/vacation'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const query = getQuery(event)
  const year = parseInt(query.year as string) || new Date().getFullYear()
  const requestedUserId = query.user_id ? parseInt(query.user_id as string) : null

  // Allow viewing another user's balance only for top-level approvers (root approval level, no parent)
  let targetId = currentUser.id
  if (requestedUserId && requestedUserId !== currentUser.id) {
    const [isTopLevel] = await sql`
      SELECT 1 FROM approval_level_members alm
      JOIN approval_levels al ON al.id = alm.level_id
      WHERE alm.user_id = ${currentUser.id} AND al.parent_id IS NULL
      LIMIT 1
    `
    if (!isTopLevel) throw createError({ statusCode: 403, message: 'Apenas aprovadores de nível superior podem ver o saldo de outros utilizadores' })
    targetId = requestedUserId
  }

  await recalculateLeaveBalance(targetId, year)

  const [balance] = await sql`
    SELECT lb.*, u.birthday, u.name AS employee_name
    FROM leave_balances lb
    JOIN users u ON u.id = lb.employee_id
    WHERE lb.employee_id = ${targetId} AND lb.year = ${year}
  `

  if (!balance) {
    const [user] = await sql<{ birthday: string | null, name: string }[]>`
      SELECT birthday, name FROM users WHERE id = ${targetId}
    `
    return {
      employee_id: targetId, year,
      base_days: 22, seniority_bonus: 0, birthday_bonus: 0,
      carryover_days: 0, used_days: 0, pending_days: 0,
      birthday: user?.birthday ?? null, employee_name: user?.name ?? ''
    }
  }

  return balance
})
