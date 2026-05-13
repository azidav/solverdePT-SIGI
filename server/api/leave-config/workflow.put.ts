import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  if ((currentUser as any).permission > 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem alterar o workflow de aprovação' })
  }

  const body = await readBody(event)
  const steps = body?.steps as Array<{ step_order: number; role_name: string; skip_after_hours: number | null }>

  if (!Array.isArray(steps) || steps.length === 0) {
    throw createError({ statusCode: 400, message: 'É necessário fornecer pelo menos um nível de aprovação' })
  }

  await sql`DELETE FROM approval_workflow_config`

  const rows = steps.map((s, i) => ({
    step_order: i + 1,
    role_name: s.role_name,
    required_permission: 'VACATION:APPROVE',
    skip_after_hours: s.skip_after_hours ?? null
  }))

  await sql`INSERT INTO approval_workflow_config ${sql(rows)}`

  return { success: true, steps: rows }
})
