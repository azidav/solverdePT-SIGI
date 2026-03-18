interface User {
  id: number
  name: string
  email: string
  permission: number
}

export const useSessionFilter = () => {
  const selectedUserId = useState<number | null>('session-filter-user-id', () => null)
  const users = useState<User[]>('session-filter-users', () => [])
  const usersLoaded = useState<boolean>('session-filter-users-loaded', () => false)

  const userOptions = computed(() => [
    { label: 'Todos os utilizadores', value: null },
    ...users.value.map(u => ({
      label: u.name,
      value: u.id
    }))
  ])

  async function loadUsers() {
    if (usersLoaded.value) return

    try {
      const usersResp = await useApiFetch('/api/users', { method: 'GET' }) as User[]
      users.value = usersResp
      usersLoaded.value = true
    } catch (error) {
      console.error('Erro ao carregar utilizadores:', error)
    }
  }

  return {
    selectedUserId,
    users,
    userOptions,
    loadUsers
  }
}
