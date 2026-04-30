import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { getUserRoomsPermissions } from '~~/server/utils/rooms'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const currentUser = await getUserFromEvent(event)

  let showAll = false
  if (query.all === 'true' && currentUser) {
    const perms = await getUserRoomsPermissions(currentUser.id)
    showAll = perms.includes('ROOMS:MANAGE')
  }

  const statusFilter = showAll ? sql`AND TRUE` : sql`AND mr.status = 'active'`

  const rooms = await sql`
    SELECT
      mr.*,
      (
        SELECT COUNT(*) > 0
        FROM room_reservations rr
        WHERE rr.room_id = mr.id
          AND rr.start_time <= NOW()
          AND rr.end_time >= NOW()
      ) AS is_occupied,
      (
        SELECT json_build_object(
          'id', rr.id,
          'meeting_title', rr.meeting_title,
          'booker_name', COALESCE(u.name, rr.guest_name),
          'end_time', rr.end_time
        )
        FROM room_reservations rr
        LEFT JOIN users u ON rr.user_id = u.id
        WHERE rr.room_id = mr.id
          AND rr.start_time <= NOW()
          AND rr.end_time >= NOW()
        ORDER BY rr.start_time ASC
        LIMIT 1
      ) AS current_reservation
    FROM meeting_rooms mr
    WHERE TRUE ${statusFilter}
    ORDER BY mr.name ASC
  `
  return rooms
})
