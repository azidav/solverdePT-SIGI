import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Only admin can update users
  if (currentUser.permission > 0) {
    throw createError({ statusCode: 403, message: 'Forbidden - Admin only' })
  }

  const userId = getRouterParam(event, 'id')
  if (!userId) throw createError({ statusCode: 400, message: 'User ID is required' })

  const body = await readBody(event)

  try {
    // Get current values for audit
    const [existingUser] = await sql`
      SELECT id, name, email, department, permission, status, password
      FROM users
      WHERE id = ${parseInt(userId)}
    `

    if (!existingUser) {
      throw createError({ statusCode: 404, message: 'User not found' })
    }

    const updateData: Record<string, unknown> = {}

    if (body.name !== undefined) updateData.name = body.name
    if (body.email !== undefined) updateData.email = body.email
    if (body.department !== undefined) updateData.department = body.department
    if (body.job_title !== undefined) updateData.job_title = body.job_title
    if (body.birthday !== undefined) updateData.birthday = body.birthday || null
    if (body.hire_date !== undefined) updateData.hire_date = body.hire_date || null
    if (body.permission !== undefined) updateData.permission = body.permission
    if (body.status !== undefined) {
      // If activating (status → 1) but user has no password, keep as pending (2)
      updateData.status = body.status === 1 && !existingUser.password ? 2 : body.status
    }
    updateData.updated_at = new Date()

    const updated = await sql`
      UPDATE users
      SET ${sql(updateData)}
      WHERE id = ${parseInt(userId)}
      RETURNING id, username, name, email, department, job_title, permission, status, created_at, updated_at
    `

    // Audit log
    await logUserAction(
      event,
      currentUser,
      'UPDATE',
      'USER',
      parseInt(userId),
      updated[0]!.name
    )

    return updated[0]
  } catch (error: unknown) {
    if (error instanceof Error && 'statusCode' in error) throw error
    if ((error as { code?: string })?.code === '23505') {
      const constraint = (error as { constraint_name?: string })?.constraint_name
      const message
        = constraint === 'idx_users_employee_no'
          ? 'Já existe um utilizador com este Nº de Identificação.'
          : constraint === 'users_username_key'
            ? 'Já existe um utilizador com este nome de utilizador.'
            : 'Já existe um utilizador com estes dados.'
      throw createError({ statusCode: 409, message })
    }
    const message = error instanceof Error ? error.message : 'Error updating user'
    throw createError({ statusCode: 500, message })
  }
})
