# Prompt Decomposition Strategies for Reliable Telematics-Based Fleet Monitoring Using Llama3 and DeepSeek

This repository is the current thesis repository for the graph-recovery and prompt-decomposition thesis. It is intentionally separate from the earlier thesis repository and contains only the source, data sample, configuration, scripts, and validated artifacts needed for the Tesla EV graph-recovery study.

## Overview

Fleet monitoring is often relational: speed, acceleration, distance, mileage, and remaining electric energy become useful when their directed dependencies can be inspected. This thesis evaluates whether local open-source large language models can propose such directed feature graphs from Tesla EV telemetry when prompts are decomposed into structured graph-recovery tasks.

The experiment compares `llama3.1:8b` and `deepseek-r1:8b` across five prompting strategies. Each model output is parsed into a directed edge list, converted into a binary adjacency matrix, and evaluated against a six-edge Tesla EV reference graph. The work treats LLM outputs as graph proposals, not as validated causal discoveries.

## Research Question

How do prompt decomposition strategies affect the reliability of LLM-assisted graph recovery from vehicle telematics data, compared with simpler prompting baselines, when outputs are evaluated as directed adjacency matrices?

## Methodology Pipeline

```text
Tesla EV telemetry
  -> feature selection and dataset fingerprint
  -> prompt template for one model-strategy cell
  -> local Ollama generation with Llama3.1 8B or DeepSeek-R1 8B
  -> parse allowed directed edges over six telemetry features
  -> build predicted adjacency matrix
  -> compare with six-edge Tesla EV reference graph
  -> report Precision, Recall, F1, SHD, FDR, Hamming Distance, Frobenius Norm
```

The selected features are `electricenergyremaining`, `electricremaining`, `speed_kmh`, `acceleration_kmh2`, `mileage`, and `distance_m`.

## Prompting Strategies

| Strategy | Role in the experiment |
| --- | --- |
| `Strategy_1_Zero_Shot_Prompting` | Direct graph-recovery baseline. |
| `Strategy_23_No_Instruction_Control` | Minimal-instruction control. |
| `Strategy_24_Policy_First_Structured` | Structured constraints before graph output. |
| `Strategy_25_Least_to_Most` | Decomposes the graph task from simpler relations to accumulated-state relations. |
| `Strategy_26_Skeleton_of_Thought` | Groups the graph by energy-state, driving-behavior, cross-group, and integrity checks. |

## Results Summary

Primary result table: `results/tesla_ev_graph_recovery/evaluation_matrix_tesla_ev.csv`.

| Model | Strategy | Precision | Recall | F1 | SHD | FDR | Hamming | Frobenius |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| DeepSeek-R1 8B | Zero-shot | 0.0000 | 0.0000 | 0.0000 | 6 | 0.0000 | 0.1667 | 2.4495 |
| DeepSeek-R1 8B | No-instruction control | 0.3333 | 0.5000 | 0.4000 | 9 | 0.6667 | 0.2500 | 3.0000 |
| DeepSeek-R1 8B | Policy-first structured | 0.0000 | 0.0000 | 0.0000 | 6 | 0.0000 | 0.1667 | 2.4495 |
| DeepSeek-R1 8B | Least-to-most | 0.0000 | 0.0000 | 0.0000 | 6 | 0.0000 | 0.1667 | 2.4495 |
| DeepSeek-R1 8B | Skeleton-of-thought | **0.4444** | **0.6667** | **0.5333** | 7 | 0.5556 | 0.1944 | 2.6458 |
| Llama3.1 8B | Zero-shot | 0.3333 | 0.5000 | 0.4000 | 9 | 0.6667 | 0.2500 | 3.0000 |
| Llama3.1 8B | No-instruction control | 0.2857 | 0.3333 | 0.3077 | 9 | 0.7143 | 0.2500 | 3.0000 |
| Llama3.1 8B | Policy-first structured | 0.1667 | 0.1667 | 0.1667 | 10 | 0.8333 | 0.2778 | 3.1623 |
| Llama3.1 8B | Least-to-most | 0.2222 | 0.3333 | 0.2667 | 11 | 0.7778 | 0.3056 | 3.3166 |
| Llama3.1 8B | Skeleton-of-thought | 0.2222 | 0.3333 | 0.2667 | 11 | 0.7778 | 0.3056 | 3.3166 |

Best observed cell: `deepseek-r1:8b` with `Strategy_26_Skeleton_of_Thought`, with F1 = 0.5333 and recall = 0.6667. The result still has false positives, so the thesis conclusion is deliberately bounded: prompt decomposition can improve graph proposals, but the predicted graphs require explicit validation.

## Repository Structure

```text
.
|-- main.tex                         # LaTeX thesis entry point
|-- references.bib                   # Bibliography
|-- chapters/                        # Thesis chapters
|-- appendix/                        # Artifact inventory appendix
|-- figures/                         # Figures referenced by the thesis
|-- data/
|   `-- tesla.csv                    # Tesla EV telemetry dataset copy used by the thesis
|-- results/
|   |-- README.md
|   `-- tesla_ev_graph_recovery/     # Validated graph-recovery artifacts
|-- notebooks/
|   `-- tesla_graph_recovery_llama3_deepseek.ipynb
|-- scripts/
|   |-- generate_graph_recovery_figures.ps1
|   |-- validate_results.ps1
|   `-- validate_results.py
|-- configs/
|   `-- graph_recovery_config.json
|-- REPRODUCIBILITY.md
|-- requirements.txt
|-- .gitattributes
|-- .gitignore
`-- README.md
```

## Compile the Thesis

Recommended PowerShell commands on this MiKTeX setup:

```powershell
& "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\miktex-pdftex.exe" "&pdflatex" -interaction=nonstopmode main.tex
& "$env:LOCALAPPDATA\Programs\MiKTeX\executables\windows-x64\biber\biber.exe" main
& "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\miktex-pdftex.exe" "&pdflatex" -interaction=nonstopmode main.tex
& "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\miktex-pdftex.exe" "&pdflatex" -interaction=nonstopmode main.tex
```

Generic LaTeX installations can use:

```bash
pdflatex -interaction=nonstopmode main.tex
biber main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

Generated files such as `main.pdf`, `main.aux`, `main.bbl`, and `main.log` are build artifacts and are ignored by git.

## Reproduce and Validate Results

Install the analysis dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Validate the committed artifact set:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate_results.ps1
```

Or, on systems with Python installed:

```powershell
python scripts\validate_results.py
```

Regenerate result figures from the validated matrices:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\generate_graph_recovery_figures.ps1
```

Rerunning the notebook requires a local Ollama service with `llama3.1:8b` and `deepseek-r1:8b` available. The thesis results are artifact-based: each validated model-strategy cell contains one saved output, so the repository supports traceable evaluation rather than a repeated-run statistical benchmark.

## Dataset and Configuration

- Dataset: `data/tesla.csv`
- Result root: `results/tesla_ev_graph_recovery/`
- Experiment configuration: `configs/graph_recovery_config.json`
- Runtime assumed by the experiment notebook: Ollama at `http://localhost:11434/api/generate`
- Decoding settings recorded in config: temperature `0.2`, top-p `0.9`, context length `8192`

## Limitations

The graph reference is a physics-informed evaluation target, not an interventionally identified causal graph. The primary artifacts contain one output per model-strategy cell, so the results do not estimate stochastic variance or self-consistency. The benchmark covers one Tesla EV dataset and two local 8B-class models; broader fleet settings require additional datasets, repeated runs, and comparison with statistical graph-learning methods.

## Citation

```bibtex
@thesis{bakkoury2026prompt,
  title  = {Prompt Decomposition Strategies for Reliable Telematics-Based Fleet Monitoring Using Llama3 and DeepSeek},
  author = {Bakkoury, Anas},
  school = {Constructor University},
  type   = {Bachelor Thesis},
  year   = {2026}
}
```

## Current Thesis Version

This repository is the current graph-recovery thesis version. It deliberately excludes obsolete previous-scope artifacts and files that do not support the Tesla EV directed-graph recovery task.
