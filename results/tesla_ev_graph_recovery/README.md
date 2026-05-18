# Tesla EV Graph-Recovery Results

This folder contains the validated graph-recovery artifact set used by the thesis. Numeric values in the thesis and repository README come from the CSV and JSON files in this directory.

## Scope and Boundary

- Dataset: Tesla EV telemetry.
- Feature set: six selected telemetry variables.
- Models: `llama3.1:8b` and `deepseek-r1:8b`.
- Strategies: five prompt strategies.
- Validated cells: ten model-strategy outputs.
- Runs per validated cell: `n_runs = 1`.

The result set supports artifact-level validation and figure regeneration. It should not be read as a repeated-run benchmark.

## Primary Result Sources

| Artifact | Role |
| --- | --- |
| `evaluation_matrix_tesla_ev.csv` | Wide result table used for summary reporting. |
| `evaluation_matrix_tesla_ev_long.csv` | Long-format result table with dataset, model, strategy, and metric metadata. |
| `Ground_Truth_UC_Tesla_Energy_Consumption_signed.json` | Six-edge directed reference graph with signed edge labels. |
| `Ground_Truth_UC_Tesla_Energy_Consumption_adjacency_matrix.npy` | Binary reference adjacency matrix. |
| `tesla_ev/<model>/<strategy>.json` | Per-cell sidecar with parsed edges, raw output, scores, latency, and `n_runs`. |
| `tesla_ev/<model>/<strategy>.npy` | Predicted adjacency matrix for one model-strategy cell. |
| `tesla_ev/<model>/<strategy>.png` | Predicted graph visualization for one model-strategy cell. |
| `consensus_tesla_ev.csv` | Edges that recur across at least half of the ten model-strategy cells. |
| `edges_kg.csv` | Parsed edge-level export with true/false labels for inspection. |
| `edges_kg.jsonld` | JSON-LD edge export for downstream graph tooling. |

## Metrics

| Metric | Direction | Interpretation |
| --- | --- | --- |
| Precision | Higher is better | Share of predicted edges that are ground-truth edges. |
| Recall | Higher is better | Share of ground-truth edges recovered by the prediction. |
| F1 Score | Higher is better | Harmonic mean of precision and recall. |
| SHD | Lower is better | Structural Hamming Distance between predicted and reference graph. |
| FDR | Lower is better | False discovery rate among predicted edges. |
| Pearson Correlation | Higher is better | Correlation between flattened predicted and reference adjacency matrices. |
| Hamming Distance | Lower is better | Normalized adjacency-matrix cell disagreement. |
| Frobenius Norm | Lower is better | Matrix-distance measure between predicted and reference adjacency matrices. |

## Result Summary

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

## Best Observed Cell

The best reported result is supported by `evaluation_matrix_tesla_ev_long.csv` and the per-cell sidecar:

```text
results/tesla_ev_graph_recovery/tesla_ev/deepseek_r1_8b/Strategy_26_Skeleton_of_Thought.json
```

It reports:

```text
model: deepseek-r1:8b
strategy: Strategy_26_Skeleton_of_Thought
F1 Score: 0.5333
Precision: 0.4444
Recall: 0.6667
SHD: 7
n_runs: 1
```

This indicates the strongest observed graph-recovery balance in the committed artifacts. It still contains false positives and should be treated as a graph proposal.

## Validation

From the repository root:

```powershell
python scripts\validate_artifacts.py
```

The validator checks required files, matrix dimensions, metric columns, ground-truth graph size, per-cell sidecar metadata, `n_runs = 1`, consensus-edge count, and the best F1 cell.
