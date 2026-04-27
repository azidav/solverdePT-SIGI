export interface IGroup {
  id: number
  name: string
  description: string
  is_system: boolean
  users_count: number
  users: { id: number; name: string; email: string }[]
  modified_at: string
  modified_by: string
  created_at: string
  updated_at: string
}

export interface IUser {
  id: number
  username: string
  name: string
  first_name: string
  last_name: string
  email: string
  role_id: number
  role_name: string
  status: number
  modified_at: string
  modified_by: string
  updated_at?: string
  avatar?: { src?: string; alt?: string }
  roles: { id: number; name: string }[]
}
