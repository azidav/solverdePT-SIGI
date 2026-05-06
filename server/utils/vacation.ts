import sql from '~~/server/utils/db'
import type { H3Event } from 'h3'
import {
  sendVacationPendingApprovalEmail,
  sendVacationApprovedEmail,
  sendVacationRejectedEmail
} from '~~/server/utils/email'

function buildRequestUrl(event: H3Event, requestId: number): string {
  const host = event.node.req.headers['host'] || 'localhost:3000'
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'
  return `${protocol}://${host}/ferias/${requestId}`
}

async function getLevelApprovers(levelId: number): Promise<{ email: string, name: string }[]> {
  return sql<{ email: string, name: string }[]>`
    SELECT u.email, u.name
    FROM approval_level_members alm
    JOIN users u ON u.id = alm.user_id
    WHERE alm.level_id = ${levelId} AND u.status = 1 AND u.email IS NOT NULL
  `
}

function fmtDate(d: string | Date): string {
  const str = d instanceof Date ? d.toISOString() : String(d)
  const part = str.split('T')[0] ?? str
  return new Intl.DateTimeFormat('pt-PT').format(new Date(part + 'T00:00:00'))
}

// ─── Working-day helpers ──────────────────────────────────────────────────────

function isWeekend(date: Date): boolean {
  const day = date.getDay()
  return day === 0 || day === 6
}

function addDays(date: Date, n: number): Date {
  const d = new Date(date)
  d.setDate(d.getDate() + n)
  return d
}

function parseDate(dateStr: string): Date {
  return new Date(dateStr + 'T00:00:00')
}

/**
 * Count working days between two dates (inclusive), excluding weekends and any
 * blackout periods that apply to the given department (or all departments).
 */
export async function countWorkingDays(
  startDate: string,
  endDate: string,
  department: string | null = null,
  includeWeekends: boolean = false
): Promise<number> {
  const deptFilter = department ? sql`AND (department IS NULL OR department = ${department})` : sql`AND department IS NULL`

  const blackouts = await sql<{ start_date: string; end_date: string }[]>`
    SELECT start_date, end_date
    FROM blackout_dates
    WHERE 1=1
      ${deptFilter}
      AND start_date <= ${endDate}
      AND end_date >= ${startDate}
  `

  const blockedRanges = blackouts.map((b) => ({
    start: parseDate(b.start_date as string),
    end: parseDate(b.end_date as string)
  }))

  const isBlackedOut = (date: Date) =>
    blockedRanges.some((r) => date >= r.start && date <= r.end)

  let count = 0
  let cursor = parseDate(startDate)
  const end = parseDate(endDate)

  while (cursor <= end) {
    if ((includeWeekends || !isWeekend(cursor)) && !isBlackedOut(cursor)) count++
    cursor = addDays(cursor, 1)
  }

  return count
}

/**
 * Validates that the requested date range does not fall entirely within a
 * blackout period. Throws a 422 if any working day in the range is blacked out.
 */
export async function assertNoBlackout(
  startDate: string,
  endDate: string,
  department: string | null
): Promise<void> {
  const deptFilter = department ? sql`AND (department IS NULL OR department = ${department})` : sql`AND department IS NULL`

  const overlaps = await sql<{ title: string }[]>`
    SELECT title
    FROM blackout_dates
    WHERE 1=1
      ${deptFilter}
      AND start_date <= ${endDate}
      AND end_date >= ${startDate}
    LIMIT 1
  `

  if (overlaps.length > 0) {
    throw createError({
      statusCode: 422,
      message: `Período restrito: "${overlaps[0]!.title}". Não é possível submeter pedido nestas datas.`
    })
  }
}

// ─── Accrual Engine ───────────────────────────────────────────────────────────

/**
 * Calculates and upserts the leave balance for a user in a given year.
 * Base: 22 days | Seniority: +1 day/year capped at +2 | Birthday: +1 day/year
 */
export async function recalculateLeaveBalance(userId: number, year: number): Promise<void> {
  const [user] = await sql<{ hire_date: string | null; birthday: string | null }[]>`
    SELECT hire_date, birthday FROM users WHERE id = ${userId}
  `
  if (!user) return

  // Load relevant settings
  const cfgRows = await sql<{ key: string; value: string }[]>`
    SELECT key, value FROM config_variables
    WHERE key IN ('vacation_seniority_1y_enabled', 'vacation_seniority_2y_enabled', 'vacation_birthday_enabled')
  `
  const cfg: Record<string, string> = {}
  cfgRows.forEach(r => { cfg[r.key] = r.value })

  const s1y = cfg['vacation_seniority_1y_enabled'] !== 'false'
  const s2y = cfg['vacation_seniority_2y_enabled'] !== 'false'
  const birthdayEnabled = cfg['vacation_birthday_enabled'] === 'true'

  let seniorityBonus = 0
  if (user.hire_date) {
    const hire = parseDate(user.hire_date as string)
    const yearsOfService = Math.floor(
      (new Date().getTime() - hire.getTime()) / (365.25 * 24 * 60 * 60 * 1000)
    )
    if (s1y && yearsOfService >= 1) seniorityBonus++
    if (s2y && yearsOfService >= 2) seniorityBonus++
  }

  let birthdayBonus = 0
  if (birthdayEnabled && user.birthday) {
    const bday = parseDate(user.birthday as string)
    if (bday.getFullYear() <= year) birthdayBonus = 1
  }

  // Carryover = unused days from previous year (frozen on first insert of this year's row)
  const [prevBal] = await sql<{
    base_days: number; seniority_bonus: number; birthday_bonus: number
    carryover_days: number; used_days: number
  }[]>`
    SELECT base_days, seniority_bonus, birthday_bonus, carryover_days, used_days
    FROM leave_balances WHERE employee_id = ${userId} AND year = ${year - 1}
  `
  const carryoverDays = prevBal
    ? Math.max(0,
        (prevBal.base_days ?? 22) + (prevBal.seniority_bonus ?? 0) +
        (prevBal.birthday_bonus ?? 0) + (prevBal.carryover_days ?? 0) -
        (prevBal.used_days ?? 0)
      )
    : 0

  await sql`
    INSERT INTO leave_balances (employee_id, year, base_days, seniority_bonus, birthday_bonus, carryover_days)
    VALUES (${userId}, ${year}, 22, ${seniorityBonus}, ${birthdayBonus}, ${carryoverDays})
    ON CONFLICT (employee_id, year)
    DO UPDATE SET
      seniority_bonus = ${seniorityBonus},
      birthday_bonus  = ${birthdayBonus},
      updated_at      = NOW()
  `
}

// ─── Workflow Engine ──────────────────────────────────────────────────────────

/**
 * Instantiates approval_workflow_steps for a newly created request,
 * based on the current approval_workflow_config.
 */
type LevelRow = { id: number; step_order: number; name: string; parent_id: number | null }

function buildLevelTree(levels: LevelRow[]): LevelRow[] {
  const map = new Map(levels.map(l => [l.id, { ...l, children: [] as LevelRow[] }]))
  const roots: (LevelRow & { children: LevelRow[] })[] = []

  for (const l of levels) {
    const node = map.get(l.id)!
    if (l.parent_id && map.has(l.parent_id)) {
      map.get(l.parent_id)!.children.push(node as any)
    } else {
      roots.push(node as any)
    }
  }

  const sort = (nodes: any[]) => {
    nodes.sort((a: any, b: any) => a.step_order - b.step_order)
    nodes.forEach((n: any) => sort(n.children))
  }
  sort(roots)

  // DFS walk: returns flat list in tree-traversal order
  const result: LevelRow[] = []
  const dfs = (nodes: any[]) => {
    for (const n of nodes) {
      result.push(n)
      dfs(n.children)
    }
  }
  dfs(roots)
  return result
}

/**
 * Returns true when approval steps were created (request stays pending).
 * Returns false when the employee is at the top of the hierarchy — caller must auto-approve.
 */
export async function createWorkflowSteps(requestId: number, employeeId: number): Promise<boolean> {
  const levels = await sql<LevelRow[]>`
    SELECT id, step_order, name, parent_id FROM approval_levels ORDER BY step_order ASC
  `

  if (levels.length === 0) {
    // Legacy fallback
    const config = await sql<{ step_order: number; role_name: string }[]>`
      SELECT step_order, role_name FROM approval_workflow_config ORDER BY step_order ASC
    `
    if (config.length === 0) return false
    const rows = config.map((c) => ({
      request_id: requestId,
      step_order: c.step_order,
      role_name: c.role_name,
      status: 'pending'
    }))
    await sql`INSERT INTO approval_workflow_steps ${sql(rows)}`
    return true
  }

  const levelMap = new Map(levels.map(l => [l.id, l]))

  const [membership] = await sql<{ level_id: number }[]>`
    SELECT level_id FROM approval_level_members WHERE user_id = ${employeeId} LIMIT 1
  `

  let approvalChain: LevelRow[]

  if (membership) {
    // Build the ancestor chain: immediate parent → grandparent → ... → root
    const ancestors: LevelRow[] = []
    let current = levelMap.get(membership.level_id)
    while (current?.parent_id != null) {
      const parent = levelMap.get(current.parent_id)
      if (!parent) break
      ancestors.push(parent)
      current = parent
    }

    if (ancestors.length === 0) {
      // Employee is at the root level — no one above to approve
      return false
    }
    approvalChain = ancestors
  } else {
    // Employee not assigned to any level — use full tree
    approvalChain = buildLevelTree(levels)
  }

  const rows = approvalChain.map((l, idx) => ({
    request_id: requestId,
    step_order: idx + 1,
    role_name: l.name,
    level_id: l.id,
    status: 'pending'
  }))

  await sql`INSERT INTO approval_workflow_steps ${sql(rows)}`
  return true
}

/**
 * Advances (or closes) the workflow after an approver acts on a step.
 * Logs the decision to vacation_request_history.
 * On final approval, marks the request approved and moves pending_days → used_days.
 * On rejection, marks the request rejected and releases pending_days.
 */
export async function advanceWorkflow(
  event: H3Event,
  requestId: number,
  actor: { id: number; name: string },
  approved: boolean,
  comment: string | undefined
): Promise<void> {
  const [request] = await sql<{
    id: number
    employee_id: number
    status: string
    current_approval_step: number
    days_count: number
    start_date: string | Date
    end_date: string | Date
  }[]>`
    SELECT id, employee_id, status, current_approval_step, days_count, start_date, end_date
    FROM vacation_requests WHERE id = ${requestId}
  `

  if (!request) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })
  if (request.status !== 'pending') {
    throw createError({ statusCode: 409, message: 'Pedido já foi processado' })
  }

  const currentStep = request.current_approval_step
  const oldStatus = request.status
  const rawStart = request.start_date instanceof Date ? request.start_date.toISOString() : String(request.start_date)
  const year = new Date(rawStart).getFullYear()
  const requestUrl = buildRequestUrl(event, requestId)
  const startDate = fmtDate(request.start_date)
  const endDate = fmtDate(request.end_date)

  // Fetch employee info for emails
  const [employee] = await sql<{ name: string, email: string }[]>`
    SELECT name, email FROM users WHERE id = ${request.employee_id}
  `

  if (!approved) {
    await sql`
      UPDATE approval_workflow_steps
      SET status = 'rejected', approver_id = ${actor.id}, comment = ${comment || null}, actioned_at = NOW()
      WHERE request_id = ${requestId} AND step_order = ${currentStep}
    `
    await sql`
      UPDATE vacation_requests SET status = 'rejected', updated_at = NOW() WHERE id = ${requestId}
    `
    await sql`
      UPDATE leave_balances
      SET pending_days = GREATEST(0, pending_days - ${request.days_count})
      WHERE employee_id = ${request.employee_id} AND year = ${year}
    `
    await logVacationHistory(requestId, actor, currentStep, oldStatus, 'rejected', comment)

    // Notify employee of rejection
    if (employee?.email) {
      sendVacationRejectedEmail(employee.email, employee.name, {
        startDate, endDate, comment, requestUrl
      }).catch(console.error)
    }
    return
  }

  // Approve current step
  await sql`
    UPDATE approval_workflow_steps
    SET status = 'approved', approver_id = ${actor.id}, comment = ${comment || null}, actioned_at = NOW()
    WHERE request_id = ${requestId} AND step_order = ${currentStep}
  `

  // Next step comes from approval_workflow_steps (this request's own chain)
  const [nextStep] = await sql<{ step_order: number, level_id: number | null, role_name: string }[]>`
    SELECT step_order, level_id, role_name
    FROM approval_workflow_steps
    WHERE request_id = ${requestId} AND step_order > ${currentStep}
    ORDER BY step_order ASC
    LIMIT 1
  `

  if (nextStep) {
    await sql`
      UPDATE vacation_requests
      SET current_approval_step = ${nextStep.step_order}, updated_at = NOW()
      WHERE id = ${requestId}
    `
    await logVacationHistory(requestId, actor, currentStep, oldStatus, 'pending', comment)

    // Notify next level's approvers
    if (nextStep.level_id) {
      const approvers = await getLevelApprovers(nextStep.level_id)
      if (approvers.length > 0) {
        sendVacationPendingApprovalEmail(approvers, {
          employeeName: employee?.name ?? 'Colaborador',
          startDate, endDate,
          daysCount: request.days_count as number,
          requestUrl,
          levelName: nextStep.role_name as string
        }).catch(console.error)
      }
    }
  } else {
    await sql`
      UPDATE vacation_requests SET status = 'approved', updated_at = NOW() WHERE id = ${requestId}
    `
    await sql`
      UPDATE leave_balances
      SET
        pending_days = GREATEST(0, pending_days - ${request.days_count}),
        used_days    = used_days + ${request.days_count}
      WHERE employee_id = ${request.employee_id} AND year = ${year}
    `
    await logVacationHistory(requestId, actor, currentStep, oldStatus, 'approved', comment)

    // Notify employee of full approval
    if (employee?.email) {
      sendVacationApprovedEmail(employee.email, employee.name, {
        startDate, endDate, daysCount: request.days_count as number, requestUrl
      }).catch(console.error)
    }
  }
}

/**
 * Admin-only: skip the current approval step (e.g. manager absent) and escalate.
 */
export async function skipWorkflowStep(
  requestId: number,
  actor: { id: number; name: string },
  comment: string | undefined
): Promise<void> {
  const [request] = await sql<{ current_approval_step: number; status: string }[]>`
    SELECT current_approval_step, status FROM vacation_requests WHERE id = ${requestId}
  `
  if (!request) throw createError({ statusCode: 404, message: 'Pedido não encontrado' })
  if (request.status !== 'pending') throw createError({ statusCode: 409, message: 'Pedido já foi processado' })

  const currentStep = request.current_approval_step

  await sql`
    UPDATE approval_workflow_steps
    SET status = 'skipped', approver_id = ${actor.id}, comment = ${comment || 'Escalado automaticamente'}, actioned_at = NOW()
    WHERE request_id = ${requestId} AND step_order = ${currentStep}
  `

  const [nextStep] = await sql<{ step_order: number }[]>`
    SELECT step_order FROM approval_workflow_config
    WHERE step_order > ${currentStep}
    ORDER BY step_order ASC
    LIMIT 1
  `

  if (nextStep) {
    await sql`
      UPDATE vacation_requests SET current_approval_step = ${nextStep.step_order}, updated_at = NOW()
      WHERE id = ${requestId}
    `
  }

  await logVacationHistory(requestId, actor, currentStep, 'pending', 'pending', comment ?? 'Nível escalado')
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

async function logVacationHistory(
  requestId: number,
  actor: { id: number; name: string },
  stepOrder: number,
  oldStatus: string,
  newStatus: string,
  comment: string | undefined
): Promise<void> {
  await sql`
    INSERT INTO vacation_request_history
      (request_id, actor_id, actor_name, old_status, new_status, step_order, comment)
    VALUES
      (${requestId}, ${actor.id}, ${actor.name}, ${oldStatus}, ${newStatus}, ${stepOrder}, ${comment || null})
  `
}
