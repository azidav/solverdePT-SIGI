import sql from './db'
import type { H3Event } from 'h3'

export type AuditAction = 'CREATE' | 'UPDATE' | 'DELETE' | 'LOGIN' | 'LOGOUT' | 'ASSIGN' | 'UNASSIGN'
export type AuditEntityType = 'USER' | 'ROLE' | 'PERMISSION' | 'USER_ROLE' | 'SESSION'

interface AuditLogParams {
  userId?: number
  userName?: string
  action: AuditAction
  entityType: AuditEntityType
  entityId?: number
  entityName?: string
  ipAddress?: string
  userAgent?: string
}

export async function createAuditLog(event: H3Event, params: AuditLogParams) {
  const { userId, userName, action, entityType, entityId, entityName } = params

  // Get IP and User Agent from request
  const ipAddress = params.ipAddress || getRequestIP(event, { xForwardedFor: true }) || 'unknown'
  const userAgent = params.userAgent || getHeader(event, 'user-agent') || 'unknown'

  try {
    await sql`
      INSERT INTO audit_logs (
        user_id, user_name, action, entity_type, entity_id, entity_name,
        ip_address, user_agent
      )
      VALUES (
        ${userId || null},
        ${userName || null},
        ${action},
        ${entityType},
        ${entityId || null},
        ${entityName || null},
        ${ipAddress},
        ${userAgent}
      )
    `
  } catch (error) {
    console.error('Failed to create audit log:', error)
  }
}

export async function logUserAction(
  event: H3Event,
  currentUser: { id: number; name: string },
  action: AuditAction,
  entityType: AuditEntityType,
  entityId: number | undefined,
  entityName: string | undefined
) {
  await createAuditLog(event, {
    userId: currentUser.id,
    userName: currentUser.name,
    action,
    entityType,
    entityId,
    entityName
  })
}
