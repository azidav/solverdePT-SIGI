import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { hasUserPermission } from '~~/server/utils/authorize'

interface BalanceRow {
  employee_no: string
  ferias_do_ano: number
  saldo_actual: number
}

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })
  const canImport = await hasUserPermission(event, ['VACATION:IMPORT_BALANCES'])
  if (!canImport) throw createError({ statusCode: 403, message: 'Sem permissão para importar saldos' })

  const body = await readBody(event) as { year: number, rows: BalanceRow[] }
  const { year, rows } = body

  if (!year || !Array.isArray(rows) || rows.length === 0) {
    throw createError({ statusCode: 400, message: 'Dados inválidos' })
  }

  const results = { updated: 0, notFound: [] as string[] }

  for (const row of rows) {
    const empNo = String(row.employee_no).trim()
    if (!empNo) continue

    const feriasDdoAno = Number(row.ferias_do_ano) || 0
    const saldoActual = Number(row.saldo_actual) || 0
    const extraDays = Math.max(0, saldoActual - feriasDdoAno)

    const [user] = await sql<{ id: number }[]>`
      SELECT id FROM users WHERE employee_no = ${empNo} AND status >= 0
    `

    if (!user) {
      results.notFound.push(empNo)
      continue
    }

    await sql`
      INSERT INTO leave_balances (employee_id, year, base_days, seniority_bonus, birthday_bonus, carryover_days, used_days, pending_days)
      VALUES (${user.id}, ${year}, ${feriasDdoAno}, 0, 0, ${extraDays}, 0, 0)
      ON CONFLICT (employee_id, year)
      DO UPDATE SET
        base_days       = ${feriasDdoAno},
        seniority_bonus = 0,
        birthday_bonus  = 0,
        carryover_days  = ${extraDays},
        updated_at      = NOW()
    `

    results.updated++
  }

  return results
})
