import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { recalculateLeaveBalance } from '~~/server/utils/vacation'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const year = parseInt(getQuery(event).year as string) || new Date().getFullYear()

  await recalculateLeaveBalance(currentUser.id, year)

  const [balance] = await sql`
    SELECT lb.*, u.birthday
    FROM leave_balances lb
    JOIN users u ON u.id = lb.employee_id
    WHERE lb.employee_id = ${currentUser.id} AND lb.year = ${year}
  `

  if (!balance) {
    const [user] = await sql<{ birthday: string | null }[]>`SELECT birthday FROM users WHERE id = ${currentUser.id}`
    return {
      employee_id: currentUser.id, year,
      base_days: 22, seniority_bonus: 0, birthday_bonus: 0,
      used_days: 0, pending_days: 0,
      birthday: user?.birthday ?? null
    }
  }

  return balance
})
