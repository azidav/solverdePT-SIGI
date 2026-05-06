import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { countWorkingDays } from '~~/server/utils/vacation'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const { start_date, end_date, include_weekends } = getQuery(event)
  if (!start_date || !end_date) {
    throw createError({ statusCode: 400, message: 'start_date e end_date obrigatórios' })
  }

  const [employee] = await sql<{ department: string | null }[]>`
    SELECT department FROM users WHERE id = ${currentUser.id}
  `
  const days = await countWorkingDays(
    start_date as string,
    end_date as string,
    employee?.department ?? null,
    include_weekends === 'true'
  )

  return { days_count: days }
})
