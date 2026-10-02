import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'
import { logUserAction } from '~~/server/utils/audit'
import { sendAccountActivationEmail } from '~~/server/utils/email'

interface ImportRow {
  name?: string
  username?: string
  email?: string
  employee_no?: string
  department?: string
  job_title?: string
  group?: string
}

interface RowError {
  line: number
  identifier: string
  reason: string
}

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // Apenas administradores podem criar utilizadores (igual ao /api/users POST)
  if (currentUser.permission !== 0) {
    throw createError({ statusCode: 403, message: 'Apenas administradores podem importar utilizadores' })
  }

  const body = await readBody(event) as { rows: ImportRow[], default_group?: string, send_emails?: boolean }
  const rows = body.rows
  const defaultGroup = (body.default_group || '').trim()
  const sendEmails = body.send_emails !== false

  if (!Array.isArray(rows) || rows.length === 0) {
    throw createError({ statusCode: 400, message: 'Nenhuma linha para importar' })
  }
  if (rows.length > 1000) {
    throw createError({ statusCode: 400, message: 'Importação limitada a 1000 utilizadores de cada vez' })
  }

  // Mapa de grupos (nome -> id), case-insensitive
  const roles = await sql<{ id: number, name: string }[]>`SELECT id, name FROM roles`
  const roleByName = new Map(roles.map(r => [r.name.trim().toLowerCase(), r.id]))

  const host = event.node.req.headers['host'] || 'localhost:3000'
  const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'

  const result = {
    created: 0,
    emailsSent: 0,
    emailsFailed: 0,
    errors: [] as RowError[]
  }

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i]!
    const line = i + 2 // +1 cabeçalho, +1 base-1
    const name = String(row.name ?? '').trim()
    const username = String(row.username ?? '').trim()
    const email = String(row.email ?? '').trim()
    const employeeNo = String(row.employee_no ?? '').trim()
    const department = String(row.department ?? '').trim() || null
    const groupName = (String(row.group ?? '').trim() || defaultGroup)
    const ident = username || employeeNo || email || `linha ${line}`

    // Validação dos campos obrigatórios
    if (!name || !username || !email || !employeeNo) {
      result.errors.push({ line, identifier: ident, reason: 'Campos obrigatórios em falta (Nome, Username, Email, Nº Identificação)' })
      continue
    }
    if (!groupName) {
      result.errors.push({ line, identifier: ident, reason: 'Grupo em falta (sem coluna "Grupo" nem grupo por defeito)' })
      continue
    }
    const roleId = roleByName.get(groupName.toLowerCase())
    if (!roleId) {
      result.errors.push({ line, identifier: ident, reason: `Grupo "${groupName}" não existe` })
      continue
    }

    try {
      // Cria o utilizador (sem password, estado 2 = pendente de ativação)
      const inserted = await sql<{ id: number }[]>`
        INSERT INTO users (username, password, name, email, department, permission, employee_no, status, must_change_password, role_id)
        VALUES (${username}, NULL, ${name}, ${email}, ${department}, 3, ${employeeNo}, 2, false, ${roleId})
        RETURNING id
      `
      const userId = inserted[0]!.id

      // Associa o grupo (tabela many-to-many)
      await sql`
        INSERT INTO user_roles (user_id, role_id, assigned_by)
        VALUES (${userId}, ${roleId}, ${currentUser.id})
        ON CONFLICT (user_id, role_id) DO NOTHING
      `

      // Token de ativação (7 dias)
      const token = randomBytes(32).toString('hex')
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      await sql`
        INSERT INTO password_reset_tokens (user_id, token, expires_at)
        VALUES (${userId}, ${token}, ${expiresAt})
      `

      await logUserAction(event, currentUser as never, 'CREATE', 'USER', userId, name)

      // Email de ativação
      if (sendEmails) {
        const activationUrl = `${protocol}://${host}/reset-password?token=${token}`
        const ok = await sendAccountActivationEmail(email, name, username, activationUrl).catch(() => false)
        if (ok) result.emailsSent++
        else result.emailsFailed++
      }

      result.created++
    } catch (err: unknown) {
      const code = (err as { code?: string })?.code
      const constraint = (err as { constraint_name?: string })?.constraint_name
      let reason = 'Erro ao criar utilizador'
      if (code === '23505') {
        reason = constraint === 'idx_users_employee_no'
          ? 'Já existe um utilizador com este Nº de Identificação'
          : constraint === 'users_username_key'
            ? 'Já existe um utilizador com este username'
            : 'Já existe um utilizador com estes dados'
      }
      result.errors.push({ line, identifier: ident, reason })
    }
  }

  return result
})
