# Quarto Academic Paper Template

A reusable template for academic papers in [Quarto](https://quarto.org/) with multi-format output (PDF, HTML, Word). Uses the [hikmah](https://github.com/andrewheiss/hikmah-academic-quarto) extensions by Andrew Heiss.

## Structure

```
my-quarto-paper-template/
├── working-paper.qmd        # Working paper (PDF/HTML/Word)
├── manuscript.qmd           # Journal submission (PDF/HTML/Word)
├── response.qmd             # Response to reviewers (PDF/HTML/Word)
├── _content.qmd             # Shared body (included by both .qmd above)
├── _paper.yml               # Title, short title, abstract, keywords (shared)
├── _authors.yml             # Author block (shared by all three documents)
├── new-paper.sh             # Starts a new paper from this template
├── references.bib           # BibTeX bibliography
├── figure/                  # Figures referenced by the paper
├── tables/                  # LaTeX .tex tables (for PDF)
└── _extensions/             # Quarto extensions (hikmah)
    └── andrewheiss/
        ├── hikmah/                # Working paper PDF template
        ├── hikmah-manuscript/     # Manuscript submission PDF template
        └── hikmah-response/       # Response to reviewers (Typst)
```

## Starting a new paper

Run the script from anywhere (VS Code's terminal works):

```bash
~/Projects/GiT/my-quarto-paper-template/new-paper.sh ~/Projects/GiT/my-new-paper "Paper Title" "Short Title"
```

It copies the template's committed files into the new folder, fills in the title, fills your name and email from `git config` (or copies `~/.config/quarto-paper/_authors.yml` if you saved a full author block there), starts a fresh git repo, and opens the folder in VS Code. Leave out the title and it asks for one.

To call it as `new-paper` from any terminal, add an alias to `~/.zshrc`:

```bash
alias new-paper="$HOME/Projects/GiT/my-quarto-paper-template/new-paper.sh"
```

The script copies the latest *commit*, so commit any changes to the template before starting a paper.

Alternatively, Quarto's built-in command copies the template into the current folder (no git init, title, or authors):

```bash
quarto use template hhadah/my-quarto-paper-template
```

### Where to edit paper details

Title, abstract, keywords, and acknowledgments live in `_paper.yml`; authors live in `_authors.yml`. `working-paper.qmd`, `manuscript.qmd`, and `response.qmd` read them through `metadata-files:`, so you edit each detail once. A field set in a document's own front matter overrides the shared value (that is how `response.qmd` keeps its own title).

## Prerequisites

Install [Quarto](https://quarto.org/docs/get-started/) (v1.3+) and [R](https://cran.r-project.org/) (v4.1+).

Required R packages:

```r
install.packages(c("knitr", "kableExtra"))
```

For PDF output, install a LaTeX distribution:

```bash
quarto install tinytex
```

## Rendering

### All formats at once

```bash
quarto render working-paper.qmd    # working paper
quarto render manuscript.qmd       # journal submission
quarto render response.qmd         # response to reviewers
```

### One specific format

```bash
# ── PDF ────────────────────────────────────────────────
quarto render working-paper.qmd --to hikmah-pdf
quarto render manuscript.qmd    --to hikmah-manuscript-pdf
quarto render response.qmd      --to hikmah-response-typst

# ── HTML ───────────────────────────────────────────────
quarto render working-paper.qmd --to html
quarto render manuscript.qmd    --to html

# ── Word (.docx) ──────────────────────────────────────
quarto render working-paper.qmd --to docx
quarto render manuscript.qmd    --to docx
```

Output files appear next to the `.qmd` source (e.g. `working-paper.pdf`, `working-paper.html`, `working-paper.docx`).

## How Tables Work

All tables are powered by a single function — `cross_format_table()` — defined once in the setup chunk at the top of `_content.qmd`. It is available to every subsequent chunk in the document.

### What it does

It detects the render target and produces the right table automatically:

| Render target | What it produces | Features |
|:---|:---|:---|
| PDF (`hikmah-pdf`) | `kableExtra` LaTeX table | booktabs, threeparttable footnotes, `\label{}` for cross-refs |
| HTML | `kableExtra` HTML table | striped rows, hover, condensed, centered |
| Word (docx) | Pandoc pipe table | native Word table via knitr::kable() default |

### How to use it

In any R chunk, build a data frame and pass it to the function:

````r
```{r}
#| label: tbl-my-table

my_df <- data.frame(
  Group = c("A", "B", "C"),
  Mean  = c("1.23", "4.56", "7.89"),
  SD    = c("0.10", "0.20", "0.30")
)

cross_format_table(
  my_df,
  caption = "Descriptive Statistics",
  label   = "tab:descriptive",
  align   = "lcc",
  notes   = c("Source: Your data.", "Full sample.")
)
```
````

Then cross-reference it in text with `@tbl-my-table`.

### Important: do NOT set `tbl-cap` in chunk options

The function handles captions internally. Setting `tbl-cap` in the chunk YAML *and* passing `caption` to the function will produce duplicate captions or errors. Just use `#| label: tbl-xxx` for cross-referencing.

### For regression tables with real models

Use `modelsummary` directly — it auto-detects the output format:

```r
library(modelsummary)
modelsummary(
  list("(1)" = m1, "(2)" = m2),
  stars   = c('*' = .10, '**' = .05, '***' = .01),
  title   = "Main Results",
  notes   = c("Standard errors in parentheses.")
)
```

### For pre-generated LaTeX tables (PDF only)

If you build `.tex` tables externally, put them in `tables/` and include them in a raw LaTeX block:

````
```{=latex}
\input{tables/my-table.tex}
```
````

This only appears in PDF output. For HTML/Word, use `cross_format_table()` instead.

## Using This Template

1. Copy the entire folder into a new project
2. Edit the YAML header in `working-paper.qmd` and/or `manuscript.qmd` (title, author, abstract, etc.)
3. Replace the placeholder content in `_content.qmd` with your paper
4. Add bibliography entries to `references.bib`
5. Render with `quarto render`

## License

Freely available for academic use. The hikmah extensions are by [Andrew Heiss](https://github.com/andrewheiss).
