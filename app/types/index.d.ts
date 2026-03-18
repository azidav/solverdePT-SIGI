import type { AvatarProps } from '@nuxt/ui'

export type UserGender = "M" | "F";
export type UserGenderText = "Masculino" | "Feminino" | "Undefined";
export type UserPermissionText = "Super Admin" | "Admin" | "Utilizador";
export type UserStatusText = "Apagada" | "Pendente" | "Ativa";

export type SaleStatus = "paid" | "failed" | "refunded";

export interface User {
  id: number;
  username: string;
  name: string;
  email: string;
  role_id: int;
  role_name: string;
  subrole_id: int;
  subrole_name: string;
  avatar: string;
  permission: int;
  permission_text: UserPermissionText;
  gender: UserGender;
  gender_text: UserGenderText;
  date_of_birth: date;
  status: int;
  status_text: UserStatusText;
}


// export interface User {
//   id: number;
//   username: string;
//   name: string;
//   email: string;
//   avatar?: AvatarProps;
//   status: UserStatus;
//   location: string;
// }

export interface Mail {
  id: number
  unread?: boolean
  from: User
  subject: string
  body: string
  date: string
}

export interface Member {
  name: string
  username: string
  role: 'member' | 'owner'
  avatar: AvatarProps
}

export interface Stat {
  title: string
  icon: string
  value: number | string
  variation: number
  formatter?: (value: number) => string
}

export interface Sale {
  id: string
  date: string
  status: SaleStatus
  email: string
  amount: number
}

export interface Notification {
  id: number
  unread?: boolean
  sender: User
  body: string
  date: string
}

export type Period = 'daily' | 'weekly' | 'monthly'

export interface Range {
  start: Date
  end: Date
}
