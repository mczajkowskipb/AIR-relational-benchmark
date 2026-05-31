#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
import re
from pathlib import Path

import nbformat


ROOT = Path("external/wucc009_gene_pair_methods")
OUT_DIR = Path("results/python_probe")
DOCS = Path("docs")

OUT_DIR.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def extract_imports(code: str) -> list[str]:
    imports: list[str] = []
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return imports

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(alias.name.split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.append(node.module.split(".")[0])

    return sorted(set(imports))


def extract_defs(code: str) -> list[str]:
    defs: list[str] = []
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return defs

    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            defs.append(f"function:{node.name}")
        elif isinstance(node, ast.ClassDef):
            defs.append(f"class:{node.name}")

    return sorted(set(defs))


def summarize_notebook(path: Path) -> dict:
    nb = nbformat.read(path, as_version=4)

    code_cells = []
    md_cells = []

    for i, cell in enumerate(nb.cells):
        source = cell.get("source", "")
        if cell.get("cell_type") == "code":
            code_cells.append((i, source))
        elif cell.get("cell_type") == "markdown":
            md_cells.append((i, source))

    all_code = "\n\n".join(src for _, src in code_cells)

    imports = extract_imports(all_code)
    defs = extract_defs(all_code)

    headings = []
    for _, src in md_cells:
        for line in src.splitlines():
            if line.lstrip().startswith("#"):
                headings.append(re.sub(r"\s+", " ", line.strip()))

    method_keywords = [
        "GER",
        "TSP",
        "k-TSP",
        "KTSP",
        "TSPG",
        "SVM",
        "REO",
        "REOs",
        "ML",
        "gene pair",
        "pair",
    ]

    keyword_hits = []
    lower = (all_code + "\n" + "\n".join(src for _, src in md_cells)).lower()
    for kw in method_keywords:
        if kw.lower() in lower:
            keyword_hits.append(kw)

    return {
        "notebook": str(path),
        "n_cells": len(nb.cells),
        "n_code_cells": len(code_cells),
        "n_markdown_cells": len(md_cells),
        "imports": imports,
        "defs": defs,
        "headings": headings,
        "keyword_hits": keyword_hits,
    }


def main() -> None:
    if not ROOT.exists():
        raise SystemExit(f"Missing repository directory: {ROOT}")

    notebooks = sorted(ROOT.glob("*.ipynb"))

    summaries = [summarize_notebook(p) for p in notebooks]

    (OUT_DIR / "wucc009_notebook_summary.json").write_text(
        json.dumps(summaries, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    md = [
        "# wucc009 gene-pair methods probe",
        "",
        "This file summarizes the external repository probe.",
        "",
        "External source: `wucc009/Implementation-and-comparison-of-gene-pair-methods`.",
        "",
        "The external repository is not vendored into this benchmark repository. It is cloned under `external/` for local inspection only.",
        "",
        "## Notebook summary",
        "",
    ]

    for s in summaries:
        md.extend(
            [
                f"### `{Path(s['notebook']).name}`",
                "",
                f"- Cells: {s['n_cells']}",
                f"- Code cells: {s['n_code_cells']}",
                f"- Markdown cells: {s['n_markdown_cells']}",
                f"- Imports: {', '.join(s['imports']) if s['imports'] else 'none detected'}",
                f"- Function/class definitions: {', '.join(s['defs']) if s['defs'] else 'none detected'}",
                f"- Keyword hits: {', '.join(s['keyword_hits']) if s['keyword_hits'] else 'none detected'}",
                "",
                "Headings:",
                "",
            ]
        )

        if s["headings"]:
            for h in s["headings"][:40]:
                md.append(f"- {h}")
        else:
            md.append("- none detected")

        md.append("")

    md.extend(
        [
            "## Initial method candidates",
            "",
            "| candidate | source notebook | status | next action |",
            "|---|---|---:|---|",
            "| TSP | Python notebook | PROBE_ONLY | Inspect whether code can be converted to callable function. |",
            "| k-TSP+SVM | Python notebook | PROBE_ONLY | Inspect input assumptions and classifier interface. |",
            "| REOs | Python notebook | PROBE_ONLY | Inspect whether method is supervised, diagnostic, or rule-discovery oriented. |",
            "| REOs+ML | Python notebook | PROBE_ONLY | Inspect feature-generation stage and downstream ML model. |",
            "| TSP+ML | Python notebook | PROBE_ONLY | Inspect feature-generation stage and downstream ML model. |",
            "| GERs | R notebook | PROBE_ONLY | Inspect separately; may require R wrapper rather than Python. |",
            "| TSPG | R notebook | PROBE_ONLY | Inspect separately. |",
            "",
            "## Decision rule",
            "",
            "A method should enter the AIR benchmark only if it can be converted into a callable train/predict wrapper without hidden manual notebook state.",
            "",
        ]
    )

    (DOCS / "python_gene_pair_method_probe.md").write_text(
        "\n".join(md),
        encoding="utf-8",
    )

    print("Wrote:", OUT_DIR / "wucc009_notebook_summary.json")
    print("Wrote:", DOCS / "python_gene_pair_method_probe.md")


if __name__ == "__main__":
    main()
