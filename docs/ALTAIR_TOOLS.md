# Altair Development Tools Guide

Complete guide for the tools installed on your EndevourOS workstation (altair).

## 📝 LaTeX Document Preparation

### TeXStudio - LaTeX IDE

**Launch**: `texstudio` or from applications menu

**Features**:
- Syntax highlighting and auto-completion
- Integrated PDF viewer with SyncTeX
- Spell checking
- Git integration
- Template management

**Quick Start**:
```bash
# Create a new document
texstudio mydocument.tex

# The basic LaTeX template:
\documentclass{article}
\usepackage[utf8]{inputenc}
\title{My Document}
\author{Your Name}
\date{\today}

\begin{document}
\maketitle
\section{Introduction}
Your content here.
\end{document}
```

**Compile**: Press F5 or F6 for quick build

### LaTeX Command Line Tools

```bash
# Simple compilation
pdflatex document.tex

# With bibliography
pdflatex document.tex
bibtex document
pdflatex document.tex
pdflatex document.tex

# Using latexrun (cleaner output)
latexrun document.tex

# Using rubber (automated builds)
rubber --pdf document.tex
rubber --clean  # Clean auxiliary files
```

### texliveFull Package Contents

Your installation includes:
- All LaTeX packages from CTAN
- Common fonts and styles
- Bibliography tools (BibTeX, BibLaTeX)
- Scientific packages (amsmath, physics, siunitx)
- Graphics packages (TikZ, PGFPlots)
- Presentation tools (Beamer)

**Find packages**:
```bash
# Search for a package
tlmgr search --global <package-name>

# Check if installed
kpsewhich <package>.sty
```

## 📄 PDF Editing and Manipulation

### Xournal++ - PDF Annotation

**Launch**: `xournalpp`

**Best for**:
- Handwritten notes on PDFs
- Tablet/stylus support
- Highlighting and annotations
- Digital signatures

**Usage**:
```bash
# Open PDF for annotation
xournalpp document.pdf

# Export annotated PDF
File → Export as PDF
```

### Okular - Advanced PDF Viewer/Editor

**Launch**: `okular`

**Features**:
- Text highlighting and notes
- Form filling
- Signature support
- Multiple document formats

**Keyboard shortcuts**:
- `Ctrl+F`: Search
- `F6`: Toggle annotations toolbar
- `Ctrl+1-6`: Annotation tools

### PDFArranger - PDF Page Manipulation

**Launch**: `pdfarranger`

**Use cases**:
- Merge multiple PDFs
- Split PDFs
- Rotate pages
- Delete pages
- Reorder pages

**CLI alternative** (using poppler_utils):
```bash
# Merge PDFs
pdfunite file1.pdf file2.pdf output.pdf

# Split PDF (pages 1-5)
pdfseparate -f 1 -l 5 input.pdf output-%d.pdf

# Get PDF info
pdfinfo document.pdf

# Extract text
pdftotext document.pdf output.txt
```

### QPDF - PDF Transformation

```bash
# Decrypt PDF
qpdf --decrypt input.pdf output.pdf

# Encrypt PDF
qpdf --encrypt userpass ownerpass 256 -- input.pdf output.pdf

# Linearize (optimize for web)
qpdf --linearize input.pdf output.pdf

# Compress PDF
qpdf --compress-streams=y input.pdf output.pdf
```

### PDFtk - PDF Toolkit

```bash
# Merge PDFs
pdftk A=file1.pdf B=file2.pdf cat A B output merged.pdf

# Extract pages 1-3 and 5
pdftk input.pdf cat 1-3 5 output output.pdf

# Rotate pages
pdftk input.pdf cat 1-endeast output rotated.pdf

# Add watermark
pdftk input.pdf stamp watermark.pdf output stamped.pdf

# Fill PDF forms
pdftk form.pdf fill_form data.fdf output filled.pdf

# Burst (split into individual pages)
pdftk input.pdf burst output page_%02d.pdf
```

## 📊 Data Analysis

### Python Data Science Stack

**Installed packages**:
- NumPy: Numerical computing
- Pandas: Data manipulation
- Matplotlib/Seaborn: Visualization
- Scipy: Scientific computing
- Scikit-learn: Machine learning
- Polars: Fast dataframes
- Plotly/Bokeh: Interactive viz
- JupyterLab: Interactive notebooks

**Quick Start**:
```bash
# Launch Jupyter Lab
jupyter lab

# Or classic notebook
jupyter notebook

# Run Python script
python analysis.py

# Interactive Python
ipython
```

**Example workflow**:
```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load data
df = pd.read_csv('data.csv')

# Quick analysis
df.describe()
df.info()

# Visualization
sns.pairplot(df)
plt.show()

# Save figure
plt.savefig('plot.png', dpi=300, bbox_inches='tight')
```

### Using Polars (Fast Alternative to Pandas)

```python
import polars as pl

# Read CSV (much faster than pandas)
df = pl.read_csv('large_data.csv')

# Lazy evaluation
lazy_df = pl.scan_csv('huge_data.csv')
result = lazy_df.filter(pl.col('value') > 100).collect()

# Export to Parquet
df.write_parquet('data.parquet')
```

### R and RStudio

**Launch RStudio**: `rstudio`

**R from terminal**:
```bash
# Interactive R
R

# Run script
Rscript analysis.R
```

**Example R workflow**:
```r
# Load data
data <- read.csv('data.csv')

# Quick summary
summary(data)
str(data)

# ggplot visualization
library(ggplot2)
ggplot(data, aes(x=var1, y=var2)) +
  geom_point() +
  theme_minimal()

# Save plot
ggsave('plot.pdf', width=8, height=6)
```

### Julia

**Launch Julia REPL**:
```bash
julia
```

**Install packages** (in Julia REPL):
```julia
using Pkg
Pkg.add("DataFrames")
Pkg.add("Plots")
Pkg.add("CSV")
```

**Example**:
```julia
using DataFrames, CSV, Plots

# Load data
df = CSV.read("data.csv", DataFrame)

# Quick plot
plot(df.x, df.y, label="Data")
savefig("plot.pdf")
```

## 📈 Data Formats

### Excel Files

```python
import pandas as pd

# Read Excel
df = pd.read_excel('data.xlsx', sheet_name='Sheet1')

# Write Excel
df.to_excel('output.xlsx', index=False, sheet_name='Results')
```

### Parquet Files

```python
import pandas as pd
import pyarrow.parquet as pq

# Read Parquet
df = pd.read_parquet('data.parquet')

# Write Parquet (compressed)
df.to_parquet('data.parquet', compression='snappy')
```

### HDF5 Files

```python
import h5py
import pandas as pd

# With pandas
df.to_hdf('data.h5', key='dataset', mode='w')
df_read = pd.read_hdf('data.h5', 'dataset')

# With h5py
with h5py.File('data.h5', 'r') as f:
    data = f['dataset'][:]
```

## 🔧 Development Workflow Tips

### LaTeX + Git

```bash
# Create .latexmkrc for automated builds
cat > .latexmkrc << 'EOF'
$pdf_mode = 1;
$pdflatex = 'pdflatex -interaction=nonstopmode';
@default_files = ('main.tex');
EOF

# Use latexmk for continuous compilation
latexmk -pvc main.tex
```

### Jupyter + Version Control

```bash
# Strip output from notebooks before committing
jupyter nbconvert --clear-output --inplace notebook.ipynb

# Or use nbstripout (install via pip)
pip install nbstripout
nbstripout --install  # Sets up git filter
```

### Virtual Environments

**Python (recommended)**:
```bash
# Create venv
python -m venv .venv

# Activate
source .venv/bin/activate

# Install packages
pip install -r requirements.txt

# Deactivate
deactivate
```

**Using direnv** (already installed in dev profile):
```bash
# Create .envrc in project directory
echo "layout python" > .envrc
direnv allow

# Auto-activates venv when you cd into directory
```

## 🖨️ Printing Workflows

### Print from LaTeX

**Direct**:
```bash
lp main.pdf
```

**From TeXStudio**: File → Print (Ctrl+P)

### Print from Jupyter

```bash
# Convert notebook to PDF
jupyter nbconvert --to pdf notebook.ipynb

# Print
lp notebook.pdf
```

### Print from R/RStudio

```r
# Save plot as PDF
pdf("plot.pdf", width=11, height=8.5)
plot(data)
dev.off()

# Print from terminal
system("lp plot.pdf")
```

### Print from Python

```python
import matplotlib.pyplot as plt

# Save as PDF
plt.savefig('figure.pdf')

# Print directly
import subprocess
subprocess.run(['lp', 'figure.pdf'])
```

## 🚀 Performance Tips

### Large Dataset Handling

1. **Use Polars instead of Pandas** for files > 1GB
2. **Use Parquet format** for storage (10x smaller, 100x faster)
3. **Use chunking** for very large files:
```python
# Process in chunks
for chunk in pd.read_csv('huge.csv', chunksize=10000):
    process(chunk)
```

### LaTeX Compilation Speed

1. **Use latexrun** for cleaner, faster builds
2. **Enable draft mode** while editing:
```latex
\documentclass[draft]{article}
```
3. **Use \includeonly** for multi-file documents:
```latex
\includeonly{chapter1,chapter2}  % Only compile these
```

### Jupyter Performance

1. **Use %time and %timeit** magic for profiling
2. **Clear output regularly** to reduce file size
3. **Use Jupyter Lab** instead of classic notebook (faster)

## 📚 Learning Resources

### LaTeX
- Overleaf tutorials: https://www.overleaf.com/learn
- LaTeX Wikibook: https://en.wikibooks.org/wiki/LaTeX
- TeXStudio manual: Built-in Help menu

### Data Science
- Pandas documentation: https://pandas.pydata.org/docs/
- Matplotlib gallery: https://matplotlib.org/stable/gallery/
- Seaborn tutorials: https://seaborn.pydata.org/tutorial.html
- Polars book: https://pola-rs.github.io/polars-book/

### R
- R for Data Science: https://r4ds.had.co.nz/
- RStudio cheatsheets: Help → Cheat Sheets

### Julia
- Julia documentation: https://docs.julialang.org/
- JuliaAcademy: https://juliaacademy.com/

## 🔍 Quick Reference

### Most Common Tasks

```bash
# LaTeX: Compile document
pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex

# PDF: Merge two PDFs
pdfunite file1.pdf file2.pdf merged.pdf

# PDF: Annotate with stylus
xournalpp document.pdf

# Data: Start Jupyter
jupyter lab

# Data: Quick Python analysis
ipython -i script.py

# R: Start RStudio
rstudio &

# Print document
lp -o sides=two-sided-long-edge document.pdf
```
