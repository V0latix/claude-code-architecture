---
name: document-processing
description: "Traitement de documents bureautiques : lecture et création de PDF, Word (DOCX) et Excel (XLSX) en Python et Node.js. Activer pour manipuler des fichiers PDF, générer des rapports Word/Excel ou extraire des données de documents."
license: MIT
sources: "anthropics/skills (pdf, docx, xlsx)"
---

# Document Processing

## Quand utiliser cette skill

- Lire, extraire ou modifier des fichiers PDF
- Créer ou éditer des documents Word (.docx)
- Générer ou manipuler des feuilles de calcul Excel (.xlsx)
- Extraire des données de documents (tableaux, texte, formulaires)
- Générer des rapports automatiques

## 1. PDF — Python

```python
# Extraction de texte avec pdfplumber (layout préservé)
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    # Texte de toutes les pages
    full_text = "\n\n".join(page.extract_text() for page in pdf.pages if page.extract_text())

    # Extraction de tableaux vers DataFrame
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            df = pd.DataFrame(table[1:], columns=table[0])
            print(df)

# Manipulation PDF avec pypdf (merge, split, metadata)
from pypdf import PdfWriter, PdfReader

# Merge plusieurs PDF
writer = PdfWriter()
for file in ["part1.pdf", "part2.pdf"]:
    reader = PdfReader(file)
    for page in reader.pages:
        writer.add_page(page)

with open("merged.pdf", "wb") as f:
    writer.write(f)

# Créer un PDF depuis zéro avec reportlab
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors

def create_report(data: list[dict], output_path: str):
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    styles = getSampleStyleSheet()
    story = []

    # Titre
    story.append(Paragraph("Monthly Report", styles['Title']))

    # Tableau
    table_data = [['Product', 'Quantity', 'Revenue']] + [
        [row['name'], str(row['qty']), f"${row['revenue']:,.2f}"]
        for row in data
    ]

    table = Table(table_data)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3b82f6')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f0f9ff')]),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
    ]))
    story.append(table)

    doc.build(story)
```

## 2. Word (DOCX) — Node.js

```typescript
import { Document, Paragraph, TextRun, Table, TableRow, TableCell,
         HeadingLevel, AlignmentType, WidthType, Packer } from 'docx'
import { writeFile } from 'fs/promises'

const createReport = async (data: ReportData): Promise<void> => {
  const doc = new Document({
    // Toujours définir la taille de page explicitement (défaut A4 ≠ US Letter)
    sections: [{
      properties: {
        page: { size: { width: 11906, height: 16838 } }  // A4 en twips (DXA)
      },
      children: [
        // Titre
        new Paragraph({
          text: data.title,
          heading: HeadingLevel.HEADING_1,
          alignment: AlignmentType.CENTER,
        }),

        // Tableau — IMPORTANT: utiliser DXA pour les largeurs
        new Table({
          width: { size: 9000, type: WidthType.DXA },  // Jamais WidthType.PERCENTAGE
          columnWidths: [3000, 3000, 3000],              // Somme = width total
          rows: [
            // Header
            new TableRow({
              tableHeader: true,
              children: ['Produit', 'Quantité', 'Total'].map(text =>
                new TableCell({
                  width: { size: 3000, type: WidthType.DXA },
                  children: [new Paragraph({
                    children: [new TextRun({ text, bold: true, color: 'FFFFFF' })],
                  })],
                  shading: { fill: '3B82F6' },
                })
              ),
            }),
            // Lignes de données
            ...data.rows.map(row =>
              new TableRow({
                children: [row.name, String(row.qty), `${row.total}€`].map(text =>
                  new TableCell({
                    width: { size: 3000, type: WidthType.DXA },
                    children: [new Paragraph({ text })],
                  })
                ),
              })
            ),
          ],
        }),
      ],
    }],
  })

  const buffer = await Packer.toBuffer(doc)
  await writeFile('report.docx', buffer)
}
```

**Règles critiques DOCX :**
- Toujours `WidthType.DXA` pour les tableaux — **jamais** les pourcentages (casse Google Docs)
- `PageBreak` doit être dans un `Paragraph`
- Ne pas utiliser de bullets Unicode — utiliser `LevelFormat.BULLET`

## 3. Excel (XLSX) — Python

```python
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, numbers
from openpyxl.utils import get_column_letter
from openpyxl.chart import BarChart, Reference

# Standards de formatage financier professionnel
def style_financial_workbook(wb: openpyxl.Workbook, ws: openpyxl.Worksheet):
    # Couleurs de code standard finance
    COLORS = {
        'input': 'FF4472C4',      # Bleu — inputs hardcodés
        'formula': 'FF000000',    # Noir — formules calculées
        'internal': 'FF00B050',   # Vert — liens internes
        'assumption_bg': 'FFFFFF00',  # Jaune bg — hypothèses clés
    }

    for row in ws.iter_rows():
        for cell in row:
            # Utiliser des FORMULES Excel, pas des valeurs calculées en Python
            # ✅ cell.value = '=SUM(B2:B100)'
            # ❌ cell.value = sum(values)  # pas de formule = pas de recalcul

            if cell.column_letter == 'B':  # Colonne des inputs
                cell.font = Font(color=COLORS['input'], name='Arial')

            # Format numérique standard
            if isinstance(cell.value, str) and cell.value.startswith('='):
                cell.number_format = '#,##0.00'  # Monétaire avec séparateurs

# Générer un graphique
def add_chart(ws, data_range_cols: tuple, title: str):
    chart = BarChart()
    chart.title = title
    chart.grouping = 'clustered'
    chart.style = 10

    data = Reference(ws, min_col=data_range_cols[0], max_col=data_range_cols[1],
                     min_row=1, max_row=ws.max_row)
    chart.add_data(data, titles_from_data=True)
    ws.add_chart(chart, 'E2')
```

## 4. OCR pour PDF scannés (Python)

```python
import pytesseract
from pdf2image import convert_from_path
from PIL import Image

def extract_text_from_scanned_pdf(pdf_path: str) -> str:
    """Extrait le texte d'un PDF scanné via OCR."""
    pages = convert_from_path(pdf_path, dpi=300)  # 300 DPI pour meilleure précision OCR

    texts = []
    for i, page in enumerate(pages):
        text = pytesseract.image_to_string(
            page,
            lang='fra+eng',       # Langues supportées
            config='--psm 3',     # Page Segmentation Mode 3 = auto
        )
        texts.append(f"--- Page {i+1} ---\n{text}")

    return "\n\n".join(texts)
```

## Anti-patterns à éviter

```python
# ❌ Hardcoder des valeurs calculées dans Excel (pas de formules)
ws['C2'] = sum(values)  # L'utilisateur ne peut pas modifier les inputs

# ✅ Formules Excel natives
ws['C2'] = '=SUM(A2:A100)'

# ❌ Ouvrir de très grands PDF entièrement en mémoire
reader = PdfReader("500mb.pdf")
all_text = "".join(page.extract_text() for page in reader.pages)  # OOM

# ✅ Traitement page par page
with pdfplumber.open("500mb.pdf") as pdf:
    for page in pdf.pages:
        process_page(page.extract_text())

# ❌ Ignorer l'encodage dans les documents Word
# ✅ Toujours spécifier A4 et les largeurs en DXA pour les tableaux DOCX
```
