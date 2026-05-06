import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Recursive CTE returns positions in tree order (root → leaf) with depth for indentation
  const rows = await sql`
    WITH RECURSIVE position_tree AS (
      SELECT id, name, description, parent_id, 0 AS depth,
             ARRAY[id] AS path
      FROM positions
      WHERE parent_id IS NULL

      UNION ALL

      SELECT p.id, p.name, p.description, p.parent_id, pt.depth + 1,
             pt.path || p.id
      FROM positions p
      INNER JOIN position_tree pt ON p.parent_id = pt.id
    )
    SELECT
      pt.id,
      pt.name,
      pt.description,
      pt.parent_id,
      pt.depth,
      p2.name AS parent_name,
      (SELECT COUNT(*) FROM positions WHERE parent_id = pt.id) AS children_count,
      (SELECT COUNT(*) FROM users WHERE position_id = pt.id) AS users_count
    FROM position_tree pt
    LEFT JOIN positions p2 ON pt.parent_id = p2.id
    ORDER BY pt.path
  `

  return rows
})
