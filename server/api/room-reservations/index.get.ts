import sql from '~~/server/utils/db'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const roomId = query.room_id ? parseInt(query.room_id as string) : null
  const dateParam = query.date as string | undefined

  const target = dateParam ? new Date(dateParam) : new Date()
  const start = new Date(target)
  start.setHours(0, 0, 0, 0)
  const end = new Date(target)
  end.setHours(23, 59, 59, 999)

  const roomFilter = roomId ? sql`AND rr.room_id = ${roomId}` : sql`AND TRUE`

  const reservations = await sql`
    SELECT
      rr.id,
      rr.room_id,
      mr.name AS room_name,
      rr.meeting_title,
      rr.description,
      rr.start_time,
      rr.end_time,
      rr.created_at,
      rr.user_id,
      COALESCE(u.name, rr.guest_name) AS booker_name,
      rr.user_id IS NULL AS is_guest
    FROM room_reservations rr
    JOIN meeting_rooms mr ON rr.room_id = mr.id
    LEFT JOIN users u ON rr.user_id = u.id
    WHERE rr.start_time >= ${start}
      AND rr.start_time <= ${end}
      ${roomFilter}
    ORDER BY rr.start_time ASC
  `
  return reservations
})
