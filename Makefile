.PHONY: thesis figures validate clean

PYTHON ?= python
PDFLATEX ?= pdflatex
BIBER ?= biber
POWERSHELL ?= powershell

thesis:
	$(PDFLATEX) -interaction=nonstopmode main.tex
	$(BIBER) main
	$(PDFLATEX) -interaction=nonstopmode main.tex
	$(PDFLATEX) -interaction=nonstopmode main.tex

figures:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/generate_graph_recovery_figures.ps1

validate:
	$(PYTHON) scripts/validate_artifacts.py

clean:
	rm -f main.aux main.bbl main.bcf main.blg main.fdb_latexmk main.fls main.log main.out main.pdf main.run.xml main.toc

