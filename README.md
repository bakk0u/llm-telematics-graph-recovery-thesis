# Prompt Decomposition Strategies for Telematics Graph Recovery

This is the current thesis repository for:

**Prompt Decomposition Strategies for Reliable Telematics-Based Fleet Monitoring Using Llama3 and DeepSeek**

The previous thesis repository is intentionally left untouched. This repository contains the cleaned graph-recovery thesis version, including the LaTeX source, Tesla EV telemetry data copy, validated graph-recovery artifacts, figures, and reproducibility metadata.

## Abstract

Fleet monitoring often depends on relationships between telemetry variables rather than isolated readings. This thesis evaluates whether local open-source LLMs can recover a directed feature graph from Tesla EV telemetry when prompts are decomposed into structured reasoning tasks. Llama3.1 8B and DeepSeek-R1 8B are compared across five prompt strategies, and each output is parsed into a directed adjacency matrix. The predicted matrices are evaluated against a six-edge Tesla EV ground-truth graph using precision, recall, F1, structural Hamming distance, false discovery rate, Pearson correlation, Hamming distance, and Frobenius norm.

## Research Question

How do prompt decomposition strategies affect the reliability of LLM-assisted graph recovery from vehicle telematics data, compared with simpler prompting baselines, when outputs are evaluated as directed adjacency matrices?

## Methodology

The experiment uses a fixed Tesla EV feature set and a fixed ground-truth directed graph. Each model-strategy cell receives the same feature descriptions and dataset fingerprint, generates a proposed edge list, and is evaluated after parsing into a binary adjacency matrix.

Models:

- `llama3.1:8b`
- `deepseek-r1:8b`

Prompting strategies:

- `Strategy_1_Zero_Shot_Prompting`
- `Strategy_23_No_Instruction_Control`
- `Strategy_24_Policy_First_Structured`
- `Strategy_25_Least_to_Most`
- `Strategy_26_Skeleton_of_Thought`

Dataset and task:

- Tesla EV telemetry, stored at `data/tesla.csv`
- Six selected variables: `electricenergyremaining`, `electricremaining`, `speed_kmh`, `acceleration_kmh2`, `mileage`, and `distance_m`
- Task: recover directed feature relationships as an edge list and adjacency matrix
- Ground truth: six-edge Tesla EV energy-consumption DAG in `results/tesla_ev_graph_recovery/`

Evaluation metrics:

- Precision
- Recall
- F1
- Structural Hamming Distance (SHD)
- False Discovery Rate (FDR)
- Hamming Distance
- Frobenius Norm
- Pearson correlation is also retained in the validated result table.

## Repository Structure

```text
.
|-- main.tex
|-- references.bib
|-- chapters/
|-- appendix/
|-- figures/
|-- data/
|   `-- tesla.csv
|-- results/
|   `-- tesla_ev_graph_recovery/
|-- notebooks/
|   `-- tesla_graph_recovery_llama3_deepseek.ipynb
|-- scripts/
|   `-- generate_graph_recovery_figures.ps1
|-- configs/
|   `-- graph_recovery_config.json
|-- requirements.txt
`-- README.md
```

## Compile the Thesis

From the repository root:

```powershell
pdflatex main.tex
biber main
pdflatex main.tex
pdflatex main.tex
```

No shell escape or minted setup is required. The generated `main.pdf` is treated as a build artifact and is ignored by git.

## Reproducibility Notes

The numerical claims in the thesis are artifact-based. The validated result set is stored in `results/tesla_ev_graph_recovery/`, including the evaluation matrices, ground-truth graph files, per-model JSON sidecars, predicted adjacency matrices, and exported edge tables.

The notebook in `notebooks/` documents the experiment source. Rerunning it requires a local Ollama service with `llama3.1:8b` and `deepseek-r1:8b` available. Because the thesis evaluates one validated output per model-strategy cell, the reported results should be interpreted as descriptive rather than repeated-run estimates.

## Current Thesis Version

This repository is the current graph-recovery / prompt-decomposition thesis version. It deliberately excludes obsolete previous-scope thesis artifacts, old QA render files, and implementation modules that do not support the current graph-recovery task.
