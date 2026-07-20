export const useVacationUtils = () => {
  const STATUS_LABELS: Record<string, string> = {
    pending: 'Pendente',
    approved: 'Aprovado',
    rejected: 'Rejeitado',
    cancelled: 'Cancelado'
  }

  const STATUS_COLORS: Record<string, 'warning' | 'success' | 'error' | 'neutral'> = {
    pending: 'warning',
    approved: 'success',
    rejected: 'error',
    cancelled: 'neutral'
  }

  const TYPE_LABELS: Record<string, string> = {
    annual: 'Férias Anuais',
    sick: 'Baixa Médica',
    birthday: 'Aniversário',
    other: 'Outro'
  }

  // Strip any time/timezone from a date string so new Date() always gets local midnight
  function datePart(d: string): string {
    return d.split('T')[0] ?? d
  }

  function formatDate(d: string | null | undefined): string {
    if (!d) return '—'
    const parsed = new Date(datePart(d) + 'T00:00:00')
    if (isNaN(parsed.getTime())) return '—'
    return new Intl.DateTimeFormat('pt-PT').format(parsed)
  }

  function formatDateTime(d: string | null | undefined): string {
    if (!d) return '—'
    const parsed = new Date(d)
    if (isNaN(parsed.getTime())) return '—'
    return new Intl.DateTimeFormat('pt-PT', { dateStyle: 'short', timeStyle: 'short' }).format(parsed)
  }

  function localDateStr(d = new Date()) {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  // Format a day count: 0.5 → "½", 1.5 → "1½", 2 → "2"
  // (days_count chega da API como string — o driver devolve NUMERIC como texto)
  function formatDays(n: number | string): string {
    const num = Number(n)
    if (num % 1 === 0) return String(num)
    const whole = Math.floor(num)
    return whole > 0 ? `${whole}½` : '½'
  }

  // "morning" → "manhã", "afternoon" → "tarde"
  function formatHalfDayPeriod(period: string | null | undefined): string {
    if (period === 'morning') return 'manhã'
    if (period === 'afternoon') return 'tarde'
    return ''
  }

  // Full label: 0.5 → "meio dia", 1 → "1 dia útil", 2 → "2 dias úteis"
  // Optional period appends "(manhã)"/"(tarde)" to half days
  function formatDaysLabel(n: number | string, period?: string | null): string {
    const num = Number(n)
    if (num === 0.5) {
      const p = formatHalfDayPeriod(period)
      return p ? `meio dia (${p})` : 'meio dia'
    }
    if (num === 1) return '1 dia útil'
    return `${formatDays(num)} dias úteis`
  }

  return { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate, formatDateTime, localDateStr, formatDays, formatDaysLabel, formatHalfDayPeriod }
}
