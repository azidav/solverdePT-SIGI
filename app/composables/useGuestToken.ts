const STORAGE_KEY = 'room_booking_tokens'

interface TokenEntry {
  token: string
  expires_at: string
  room_id: number
  meeting_title: string
}

export const useGuestToken = () => {
  function _load(): Record<string, TokenEntry> {
    if (!import.meta.client) return {}
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') } catch { return {} }
  }

  function _save(data: Record<string, TokenEntry>) {
    if (import.meta.client) localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  }

  function saveToken(reservationId: number, entry: TokenEntry) {
    const stored = _load()
    stored[String(reservationId)] = entry
    _save(stored)
  }

  function getToken(reservationId: number): string | null {
    const stored = _load()
    const entry = stored[String(reservationId)]
    if (!entry) return null
    if (new Date(entry.expires_at) < new Date()) {
      removeToken(reservationId)
      return null
    }
    return entry.token
  }

  function removeToken(reservationId: number) {
    const stored = _load()
    delete stored[String(reservationId)]
    _save(stored)
  }

  function getValidTokenIds(): number[] {
    const stored = _load()
    const now = new Date()
    return Object.entries(stored)
      .filter(([, entry]) => new Date(entry.expires_at) >= now)
      .map(([id]) => Number(id))
  }

  return { saveToken, getToken, removeToken, getValidTokenIds }
}
