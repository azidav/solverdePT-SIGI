import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  const reservations = await sql`
    SELECT
      rr.id,
      rr.meeting_title,
      rr.description,
      rr.start_time,
      rr.end_time,
      mr.name AS room_name
    FROM room_reservations rr
    JOIN meeting_rooms mr ON rr.room_id = mr.id
    WHERE rr.user_id = ${currentUser.id}
      AND rr.end_time >= NOW()
    ORDER BY rr.start_time ASC
    LIMIT 10
  `

  return reservations
})
