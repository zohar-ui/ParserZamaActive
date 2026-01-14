# Skills Reference Library

**Purpose:** Reference collection of official Anthropic skills for file generation and manipulation
**Source:** https://github.com/anthropics/skills
**Last Updated:** 2026-01-13

---

## Overview

This directory contains reference copies of official Anthropic skills that provide Python and JavaScript scripts for generating and manipulating various file formats. These skills are NOT active in Claude Code but serve as reference implementations for generating documents, presentations, and PDFs.

---

## Available Skills

### 1. **PDF** (`anthropic/pdf/`)

**Purpose:** Comprehensive PDF manipulation toolkit

**Capabilities:**
- Extract text and tables from PDFs
- Create new PDFs programmatically
- Merge and split PDF documents
- Fill PDF forms with data
- Extract images from PDFs
- Add watermarks and encryption
- Handle scanned PDFs with OCR

**Key Scripts:**
- `scripts/convert_pdf_to_images.py` - Convert PDF pages to images
- `scripts/fill_fillable_fields.py` - Fill PDF form fields
- `scripts/extract_form_field_info.py` - Extract form field metadata
- `scripts/create_validation_image.py` - Generate validation images

**Libraries Used:**
- `pypdf` - Basic PDF operations
- `pdfplumber` - Text and table extraction
- `reportlab` - PDF creation
- `pytesseract` - OCR for scanned PDFs

**Documentation:**
- `SKILL.md` - Main usage guide
- `forms.md` - PDF form filling guide
- `reference.md` - Advanced features and troubleshooting

---

### 2. **DOCX** (`anthropic/docx/`)

**Purpose:** Professional Word document creation and editing

**Capabilities:**
- Create new Word documents from scratch
- Edit existing documents with tracked changes
- Work with comments and formatting
- Extract text and analyze content
- Convert documents to images
- Professional redlining workflow for document review

**Key Scripts:**
- `scripts/document.py` - Document library for OOXML manipulation
- `scripts/utilities.py` - Helper functions
- `ooxml/scripts/unpack.py` - Extract .docx to XML
- `ooxml/scripts/pack.py` - Repack XML to .docx

**Libraries Used:**
- `docx` (npm) - Create new documents (JavaScript/TypeScript)
- `pandoc` - Text extraction and conversion
- Document library - Python for OOXML editing

**Documentation:**
- `SKILL.md` - Main usage guide
- `docx-js.md` - JavaScript document creation API
- `ooxml.md` - OOXML editing and Document library

**Workflow Patterns:**
- **Creating new docs:** Use docx-js (JavaScript)
- **Editing existing docs:** Use Document library (Python) + OOXML
- **Redlining:** Tracked changes workflow for professional review

---

### 3. **PPTX** (`anthropic/pptx/`)

**Purpose:** Presentation creation, editing, and analysis

**Capabilities:**
- Create new presentations from scratch
- Edit existing presentations
- Work with templates and layouts
- Extract text and speaker notes
- Generate thumbnail grids
- Convert slides to images
- Rearrange, duplicate, and delete slides

**Key Scripts:**
- `scripts/html2pptx.js` - Convert HTML to PowerPoint (JavaScript)
- `scripts/inventory.py` - Extract all text shapes from presentation
- `scripts/replace.py` - Replace text in shapes
- `scripts/rearrange.py` - Duplicate, reorder, delete slides
- `scripts/thumbnail.py` - Generate visual thumbnail grids
- `ooxml/scripts/unpack.py` - Extract .pptx to XML
- `ooxml/scripts/pack.py` - Repack XML to .pptx

**Libraries Used:**
- `pptxgenjs` (npm) - Create presentations (JavaScript)
- `markitdown` - Text extraction
- `playwright` - HTML rendering for html2pptx
- `sharp` - Image processing

**Documentation:**
- `SKILL.md` - Main usage guide
- `html2pptx.md` - HTML to PowerPoint conversion
- `ooxml.md` - OOXML editing guide

**Workflow Patterns:**
- **Creating without template:** Use html2pptx (HTML → PowerPoint)
- **Creating with template:** Use rearrange.py + inventory.py + replace.py
- **Editing existing:** Use OOXML editing + pack/unpack

---

## Common Patterns

### File Structure

All three skills use similar OOXML patterns:

```
.pptx / .docx / .xlsx (ZIP archive)
├── [Content]Types.xml
├── _rels/
│   └── .rels
├── ppt/ or word/ or xl/
│   ├── presentation.xml or document.xml or workbook.xml
│   ├── slides/ or paragraphs/ or worksheets/
│   ├── media/
│   └── _rels/
└── docProps/
    ├── app.xml
    └── core.xml
```

### Unpack → Edit → Pack Workflow

```bash
# 1. Unpack (all skills use same script)
python ooxml/scripts/unpack.py input.pptx unpacked/

# 2. Edit XML files
# (skill-specific editing logic)

# 3. Pack back to Office format
python ooxml/scripts/pack.py unpacked/ output.pptx
```

### Image Conversion Pattern

```bash
# All three skills support conversion to images via LibreOffice + poppler

# Step 1: Convert to PDF
soffice --headless --convert-to pdf document.docx

# Step 2: Convert PDF to images
pdftoppm -jpeg -r 150 document.pdf page
# Creates: page-1.jpg, page-2.jpg, etc.
```

---

## Usage in ParserZamaActive

These skills are **reference-only** - they are not active Claude Code skills. Use them when you need to:

1. **Generate workout reports** as PDF/DOCX
2. **Create training presentations** from workout data
3. **Export structured data** to professional documents
4. **Fill PDF forms** programmatically (e.g., athlete waivers)
5. **Batch process documents** using Python scripts

### Example: Generate Workout Report

```python
# Using reportlab from pdf skill
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, Paragraph
from reportlab.lib.styles import getSampleStyleSheet

# Query workout data from database
workout_data = fetch_workout_from_db(workout_id)

# Create PDF report
doc = SimpleDocTemplate("workout_report.pdf", pagesize=letter)
story = []

# Add workout details
styles = getSampleStyleSheet()
title = Paragraph(f"Workout Report: {workout_data['date']}", styles['Title'])
story.append(title)

# Add workout table
data = [
    ['Exercise', 'Sets', 'Reps', 'Weight'],
    ...
]
table = Table(data)
story.append(table)

doc.build(story)
```

### Example: Fill Athlete Waiver PDF

```python
# Using pypdf from pdf skill
from pypdf import PdfReader, PdfWriter

# Load form template
reader = PdfReader("waiver_template.pdf")
writer = PdfWriter()

# Fill form fields
writer.add_page(reader.pages[0])
writer.update_page_form_field_values(
    writer.pages[0],
    {
        "athlete_name": "John Doe",
        "date": "2026-01-13",
        "signature": "John Doe"
    }
)

# Save filled form
with open("filled_waiver.pdf", "wb") as output:
    writer.write(output)
```

---

## Dependencies

### Python
```bash
pip install pypdf pdfplumber reportlab pytesseract pdf2image defusedxml
pip install "markitdown[pptx]"
```

### Node.js
```bash
npm install -g docx pptxgenjs playwright react-icons react react-dom sharp
```

### System
```bash
sudo apt-get install pandoc libreoffice poppler-utils
```

---

## License

All skills from the Anthropic repository are **Proprietary**. See individual `LICENSE.txt` files in each skill directory for complete terms.

---

## References

- **Source Repository:** https://github.com/anthropics/skills
- **Claude Code Documentation:** https://code.claude.com/docs/en/skills
- **Anthropic Blog:** Skills announcement and usage guides

---

**Last Updated:** 2026-01-13
**Maintained By:** ParserZamaActive Team
