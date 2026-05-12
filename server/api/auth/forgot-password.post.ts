import { randomBytes } from 'crypto'
import sql from '~~/server/utils/db'
import { sendEmail } from '~~/server/utils/email'

export default defineEventHandler(async (event) => {
  const { email } = await readBody(event)

  if (!email) {
    throw createError({ statusCode: 400, message: 'Email obrigatório' })
  }

  // Always return success to avoid revealing whether the email exists
  try {
    const users = await sql`
      SELECT id, name, username FROM users WHERE email = ${email} AND status >= 0 LIMIT 1
    `

    if (users.length > 0) {
      const user = users[0]
      const token = randomBytes(32).toString('hex')
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000) // 1 hour

      await sql`
        INSERT INTO password_reset_tokens (user_id, token, expires_at)
        VALUES (${user.id}, ${token}, ${expiresAt})
      `

      const host = event.node.req.headers['host'] || 'localhost:3000'
      const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http'
      const resetUrl = `${protocol}://${host}/reset-password?token=${token}`

      const subject = 'Recuperação de Password'
      const html = `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px;">
          <h2 style="color:#00C16A;">Recuperação de Password</h2>
          <p>Olá <strong>${user.name}</strong>,</p>
          <p>Recebemos um pedido para redefinir a password da tua conta.</p>
          <p>Clica no botão abaixo para definires uma nova password:</p>
          <a href="${resetUrl}"
            style="display:inline-block;background:#00C16A;color:white;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:bold;margin:16px 0;">
            Redefinir Password
          </a>
          <p style="color:#666;font-size:14px;">⏱ Este link expira em <strong>1 hora</strong>.</p>
          <p style="color:#dc2626;font-size:14px;">Se não solicitou esta recuperação, pode ignorar este email.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
          <p style="font-size:12px;color:#999;">Link direto: <a href="${resetUrl}">${resetUrl}</a></p>
        </div>
      `

      await sendEmail(email, subject, html)
    }
  } catch (err) {
    console.error('[ForgotPassword]', err)
  }

  return { success: true }
})
