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

export async function sendAccountCreatedEmail(
  to: string,
  name: string,
  username: string,
  password: string
): Promise<boolean> {
  const subject = 'A sua conta foi criada'
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
      <h2 style="color:#00C16A;">Bem-vindo(a), ${name}!</h2>
      <p>A sua conta foi criada com sucesso. Utilize as credenciais abaixo para aceder ao sistema.</p>
      <div style="background:#f5f5f5;border-radius:8px;padding:16px;margin:16px 0;">
        <p style="margin:4px 0;"><strong>Username:</strong> ${username}</p>
        <p style="margin:4px 0;"><strong>Password:</strong> <code style="background:#e5e5e5;padding:2px 6px;border-radius:4px;">${password}</code></p>
      </div>
      <p style="color:#dc2626;"><strong>⚠ Importante:</strong> Altere a sua password após o primeiro acesso em <em>Definições → Mudar Password</em>.</p>
    </div>
  `
  return sendEmail(to, subject, html)
}
