// Gera o PDF de um pedido de ausência aprovado no layout oficial MOD005
// (réplica do modelo Excel "Pedido_ferias.xls" usado pelos RH).

interface PdfRequest {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number | string
  half_day: boolean
  half_day_period: string | null
  status: string
  reason: string | null
  employee_name: string
  employee_no?: string | null
  department: string | null
  created_at: string
  approved_at?: string | null
}

const TYPE_LABELS: Record<string, string> = {
  annual: 'Férias',
  sick: 'Baixa Médica',
  birthday: 'Aniversário',
  other: 'Outro'
}

// Unidade organizacional (solverde.pt — vertente digital do Grupo Solverde)
const UNIT = 'Casino Online'

function datePart(d: string): string {
  return d.split('T')[0] ?? d
}

function fmtDate(d: string | null | undefined): string {
  if (!d) return ''
  const parsed = new Date(datePart(d) + 'T00:00:00')
  if (isNaN(parsed.getTime())) return ''
  return new Intl.DateTimeFormat('pt-PT').format(parsed)
}

function fmtDays(n: number | string, period: string | null): string {
  const num = Number(n)
  if (num === 0.5) {
    const p = period === 'morning' ? 'manhã' : period === 'afternoon' ? 'tarde' : ''
    return p ? `0,5 (${p})` : '0,5'
  }
  return String(num).replace('.', ',')
}

// Carrega o logo (PNG em public/) como dataURL para o jsPDF
async function loadLogo(): Promise<string | null> {
  try {
    const res = await fetch('/pedido-ferias-logo.png')
    if (!res.ok) return null
    const blob = await res.blob()
    return await new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result as string)
      reader.onerror = reject
      reader.readAsDataURL(blob)
    })
  } catch {
    return null
  }
}

export async function generateVacationRequestPdf(request: PdfRequest): Promise<void> {
  const { jsPDF } = await import('jspdf')
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' })

  const logo = await loadLogo()

  const black: [number, number, number] = [0, 0, 0]
  const border: [number, number, number] = [128, 128, 128]
  const greyBox: [number, number, number] = [242, 242, 242] // De/Para
  const greyTable: [number, number, number] = [248, 248, 248] // tabela

  doc.setLineWidth(0.2)
  doc.setDrawColor(...border)
  doc.setTextColor(...black)

  // ── Logo (canto superior esquerdo) ──
  if (logo) {
    doc.addImage(logo, 'PNG', 14.5, 30.0, 50.8, 13.4)
  }

  // ── Caixa De / Para (canto superior direito) ──
  const boxL = 71.3
  const boxR = 187.0
  const boxT = 30.7
  const boxSep = 35.6
  const boxB = 42.3
  doc.setFillColor(...greyBox)
  doc.rect(boxL, boxT, boxR - boxL, boxB - boxT, 'F') // fundo cinza
  doc.rect(boxL, boxT, boxR - boxL, boxB - boxT) // contorno
  doc.line(boxL, boxSep, boxR, boxSep) // separador das duas linhas
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(9)
  doc.text(`De: ${request.employee_name}`, boxL + 1.5, 34.2)
  doc.text('Para:', boxL + 1.5, 39.8)
  doc.setFont('helvetica', 'normal')
  doc.text('Departamento de Recursos Humanos', boxL + 1.5 + doc.getTextWidth('Para: '), 39.8)

  // ── MOD005 ──
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(9)
  doc.text('MOD005', 13.1, 51.0)

  // ── Título (tipo de ausência) ──
  doc.setFontSize(14)
  doc.text(TYPE_LABELS[request.type] ?? request.type, boxR, 56.8, { align: 'right' })

  // ── Tabela principal (5 linhas) ──
  const tabL = 12.4
  const tabR = 187.0
  const colDiv = 70.9 // divisor entre rótulos e valores
  const dateDiv = 118.2 // divisor "De/Até" na linha de datas
  const rowH = 5.11
  const tabT = 58.9
  const rows = 5 // Nº, Nome, Unidade, Dias, Data a Gozar
  const tabB = tabT + rows * rowH
  const dateRow = 4 // índice da linha "Data a Gozar"

  // Fundo cinza da tabela + célula "Data do documento"
  doc.setFillColor(...greyTable)
  doc.rect(tabL, tabT, tabR - tabL, tabB - tabT, 'F')
  doc.rect(dateDiv, tabB, tabR - dateDiv, rowH, 'F')

  // Linhas horizontais + verticais
  for (let i = 0; i <= rows; i++) {
    doc.line(tabL, tabT + i * rowH, tabR, tabT + i * rowH)
  }
  doc.line(tabL, tabT, tabL, tabB)
  doc.line(colDiv, tabT, colDiv, tabB)
  doc.line(tabR, tabT, tabR, tabB)
  // Divisor De/Até na linha de datas
  doc.line(dateDiv, tabT + dateRow * rowH, dateDiv, tabB)
  // Célula "Data do documento" (pendurada à direita, por baixo da tabela)
  doc.line(dateDiv, tabB + rowH, tabR, tabB + rowH)
  doc.line(dateDiv, tabB, dateDiv, tabB + rowH)
  doc.line(tabR, tabB, tabR, tabB + rowH)

  doc.setFontSize(9)
  const baseline = (row: number) => tabT + row * rowH + 3.6
  const valueCenter = (colDiv + tabR) / 2

  // Rótulos (alinhados à direita na coluna esquerda)
  doc.setFont('helvetica', 'normal')
  const labelR = colDiv - 1.5
  doc.text('Nº Funcionário:', labelR, baseline(0), { align: 'right' })
  doc.text('Nome:', labelR, baseline(1), { align: 'right' })
  doc.text('Unidade:', labelR, baseline(2), { align: 'right' })
  doc.text('Dias Úteis a Gozar:', labelR, baseline(3), { align: 'right' })
  doc.text('Data a Gozar', labelR, baseline(dateRow), { align: 'right' })

  // Valores (centrados na coluna direita)
  doc.text(request.employee_no ?? '—', valueCenter, baseline(0), { align: 'center' })
  doc.text(request.employee_name, valueCenter, baseline(1), { align: 'center' })
  doc.text(UNIT, valueCenter, baseline(2), { align: 'center' })
  doc.text(fmtDays(request.days_count, request.half_day_period), valueCenter, baseline(3), { align: 'center' })

  // Linha de datas (período do pedido)
  doc.text('De:', colDiv + 1.5, baseline(dateRow))
  doc.text(fmtDate(request.start_date), dateDiv - 1.5, baseline(dateRow), { align: 'right' })
  doc.text('Até:', dateDiv + 1.5, baseline(dateRow))
  doc.text(fmtDate(request.end_date), tabR - 1.5, baseline(dateRow), { align: 'right' })

  // Data do documento = data de aceitação (aprovação) das férias
  doc.setFont('helvetica', 'bold')
  doc.text(`Data do documento: ${fmtDate(request.approved_at ?? request.created_at)}`, dateDiv + 1.5, tabB + 3.6)

  // ── Notas ──
  doc.setFont('helvetica', 'bold')
  doc.text('Notas', 13.1, 103.5)
  doc.rect(tabL, 104.8, tabR - tabL, 15.6)
  if (request.reason) {
    doc.setFont('helvetica', 'normal')
    doc.setFontSize(8.5)
    const wrapped = doc.splitTextToSize(request.reason, tabR - tabL - 4)
    doc.text(wrapped.slice(0, 4), tabL + 2, 108.6)
  }

  // ── Assinaturas ──
  const sigL = 30.7
  const sigR = 160.2
  const sigCenter = (sigL + sigR) / 2
  doc.setDrawColor(...border)

  // Nome completo do colaborador por cima da linha de assinatura do funcionário
  doc.setFont('helvetica', 'italic')
  doc.setFontSize(11)
  doc.text(request.employee_name, sigCenter, 133.0, { align: 'center' })

  doc.setFont('helvetica', 'bold')
  doc.setFontSize(9)
  const signatures: [number, string][] = [
    [135.5, 'Assinatura do Funcionário'],
    [156.3, 'Assinatura da Direcção'],
    [177.1, 'Assinatura do Responsável de Recursos Humanos']
  ]
  for (const [y, label] of signatures) {
    doc.line(sigL, y, sigR, y)
    doc.text(label, sigCenter, y + 4, { align: 'center' })
  }

  doc.save(`pedido-ferias-${request.id}-${datePart(request.start_date)}.pdf`)
}
