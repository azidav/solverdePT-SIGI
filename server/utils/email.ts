import nodemailer from 'nodemailer'
import sql from '~~/server/utils/db'

interface SmtpConfig {
  host: string
  port: number
  secure: boolean
  user: string
  password: string
  fromEmail: string
  fromName: string
}

async function getSmtpConfig(): Promise<SmtpConfig | null> {
  try {
    const rows = await sql`
      SELECT key, value FROM config_variables WHERE section = 'email'
    `
    const cfg: Record<string, string> = {}
    rows.forEach((r: { key: string; value: string }) => { cfg[r.key] = r.value })

    if (!cfg.smtp_host || !cfg.smtp_user || !cfg.smtp_password) return null

    return {
      host: cfg.smtp_host,
      port: parseInt(cfg.smtp_port || '587'),
      secure: cfg.smtp_secure === 'true',
      user: cfg.smtp_user,
      password: cfg.smtp_password,
      fromEmail: cfg.from_email || cfg.smtp_user,
      fromName: cfg.from_name || 'Sistema'
    }
  } catch {
    return null
  }
}

export async function sendEmail(to: string, subject: string, html: string): Promise<boolean> {

  // send fake email test — set to `false as boolean` to use real SMTP
  if (true as boolean) {
    try {
      const testAccount = await nodemailer.createTestAccount()

      const transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass
        },
        tls: { rejectUnauthorized: false }
      })

      const info = await transporter.sendMail({
        from: `"kevin-silva" <kevin-silva1998@hotmail.com>`,
        to,
        subject,
        html,
        text: html.replace(/<[^>]*>/g, '')
      })

      console.log('\n📧 [Email Test] Preview URL:', nodemailer.getTestMessageUrl(info), '\n')
      return true
    } catch (err) {
      console.error('[Email Test] Erro ao enviar email de teste:', err)
      return false
    }
  }



  const cfg = await getSmtpConfig()
  if (!cfg) {
    console.warn('[Email] SMTP não configurado — email não enviado para', to)
    return false
  }

  try {
    const transporter = nodemailer.createTransport({
      host: cfg.host,
      port: cfg.port,
      secure: cfg.secure,
      auth: { user: cfg.user, pass: cfg.password }
    })

    await transporter.sendMail({
      from: `"${cfg.fromName}" <${cfg.fromEmail}>`,
      to,
      subject,
      html,
      text: html.replace(/<[^>]*>/g, '')
    })

    return true
  } catch (err) {
    console.error('[Email] Erro ao enviar email:', err)
    return false
  }
}

// ─── Vacation notification emails ────────────────────────────────────────────

export async function sendVacationPendingApprovalEmail(
  approvers: { email: string, name: string }[],
  opts: { employeeName: string, startDate: string, endDate: string, daysCount: number, requestUrl: string, levelName: string }
): Promise<void> {
  const subject = `Pedido de férias aguarda a sua aprovação — ${opts.employeeName}`
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#00C16A;">Pedido de Férias para Aprovação</h2>
      <p>O colaborador <strong>${opts.employeeName}</strong> submeteu um pedido de férias que aguarda aprovação no nível <strong>${opts.levelName}</strong>.</p>
      <div style="background:#f5f5f5;border-radius:8px;padding:16px;margin:16px 0;">
        <p style="margin:4px 0;"><strong>Período:</strong> ${opts.startDate} → ${opts.endDate}</p>
        <p style="margin:4px 0;"><strong>Dias úteis:</strong> ${opts.daysCount}</p>
      </div>
      <a href="${opts.requestUrl}" style="display:inline-block;background:#00C16A;color:white;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">
        Ver Pedido
      </a>
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      <p style="font-size:12px;color:#999;">Link direto: <a href="${opts.requestUrl}">${opts.requestUrl}</a></p>
    </div>
  `
  await Promise.all(
    approvers.map(a =>
      sendEmail(a.email, subject, html).catch(err => console.error('[Email] Falha aprovador', a.email, err))
    )
  )
}

export async function sendVacationApprovedEmail(
  to: string, name: string,
  opts: { startDate: string, endDate: string, daysCount: number, requestUrl: string }
): Promise<void> {
  const subject = 'O seu pedido de férias foi aprovado! ✅'
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#00C16A;">Pedido de Férias Aprovado</h2>
      <p>Olá <strong>${name}</strong>,</p>
      <p>O seu pedido de férias foi <strong>aprovado</strong> por todos os níveis.</p>
      <div style="background:#f0fdf4;border-radius:8px;padding:16px;margin:16px 0;border:1px solid #bbf7d0;">
        <p style="margin:4px 0;"><strong>Período:</strong> ${opts.startDate} → ${opts.endDate}</p>
        <p style="margin:4px 0;"><strong>Dias úteis:</strong> ${opts.daysCount}</p>
      </div>
      <a href="${opts.requestUrl}" style="display:inline-block;background:#00C16A;color:white;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">
        Ver Pedido
      </a>
    </div>
  `
  await sendEmail(to, subject, html).catch(err => console.error('[Email] Férias aprovadas', err))
}

export async function sendVacationRejectedEmail(
  to: string, name: string,
  opts: { startDate: string, endDate: string, comment: string | undefined, requestUrl: string }
): Promise<void> {
  const subject = 'O seu pedido de férias foi rejeitado'
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#ef4444;">Pedido de Férias Rejeitado</h2>
      <p>Olá <strong>${name}</strong>,</p>
      <p>O seu pedido de férias foi <strong>rejeitado</strong>.</p>
      <div style="background:#fef2f2;border-radius:8px;padding:16px;margin:16px 0;border:1px solid #fecaca;">
        <p style="margin:4px 0;"><strong>Período:</strong> ${opts.startDate} → ${opts.endDate}</p>
        ${opts.comment ? `<p style="margin:8px 0 4px;"><strong>Motivo:</strong> ${opts.comment}</p>` : ''}
      </div>
      <a href="${opts.requestUrl}" style="display:inline-block;background:#6b7280;color:white;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">
        Ver Pedido
      </a>
    </div>
  `
  await sendEmail(to, subject, html).catch(err => console.error('[Email] Férias rejeitadas', err))
}

export async function sendVacationAutoApprovedNotificationEmail(
  approvers: { email: string, name: string }[],
  opts: { employeeName: string, typeName: string, startDate: string, endDate: string, daysCount: number, requestUrl: string }
): Promise<void> {
  const subject = `Ausência submetida (aprovação automática) — ${opts.employeeName}`
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#6b7280;">Pedido de Ausência Submetido</h2>
      <p>O colaborador <strong>${opts.employeeName}</strong> submeteu um pedido de <strong>${opts.typeName}</strong> que foi <strong>aprovado automaticamente</strong>.</p>
      <div style="background:#f5f5f5;border-radius:8px;padding:16px;margin:16px 0;">
        <p style="margin:4px 0;"><strong>Período:</strong> ${opts.startDate} → ${opts.endDate}</p>
        <p style="margin:4px 0;"><strong>Dias:</strong> ${opts.daysCount}</p>
      </div>
      <p style="color:#6b7280;font-size:13px;">Este pedido não requer ação da sua parte — é apenas uma notificação informativa.</p>
      <a href="${opts.requestUrl}" style="display:inline-block;background:#6b7280;color:white;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:bold;margin:12px 0;">
        Ver Pedido
      </a>
    </div>
  `
  await Promise.all(
    approvers.map(a =>
      sendEmail(a.email, subject, html).catch(err => console.error('[Email] Notificação automática', a.email, err))
    )
  )
}

export async function sendAccountActivationEmail(
  to: string,
  name: string,
  username: string,
  activationUrl: string
): Promise<boolean> {
  const subject = 'Ative a sua conta'
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#00C16A;">Bem-vindo(a), ${name}!</h2>
      <p>A sua conta foi criada com sucesso. Para aceder ao sistema, precisa de definir a sua password.</p>
      <div style="background:#f5f5f5;border-radius:8px;padding:16px;margin:16px 0;">
        <p style="margin:4px 0;"><strong>Username:</strong> ${username}</p>
      </div>
      <p>Clique no botão abaixo para definir a sua password e ativar a conta:</p>
      <a href="${activationUrl}"
        style="display:inline-block;background:#00C16A;color:white;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">
        Definir Password
      </a>
      <p style="color:#666;font-size:14px;">⏱ Este link expira em <strong>7 dias</strong>.</p>
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      <p style="font-size:12px;color:#999;">Link direto: <a href="${activationUrl}">${activationUrl}</a></p>
    </div>
  `
  return sendEmail(to, subject, html)
}
