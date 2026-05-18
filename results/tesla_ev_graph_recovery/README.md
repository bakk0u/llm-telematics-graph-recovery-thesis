# Tesla EV Graph-Recovery Results

This folder contains the validated artifact set used by the thesis.

## Primary Files

| File | Purpose |
| --- | --- |
| `evaluation_matrix_tesla_ev.csv` | Wide result matrix used for thesis tables. |
| `evaluation_matrix_tesla_ev_long.csv` | Long result matrix with model and strategy metadata. |
| `Ground_Truth_UC_Tesla_Energy_Consumption_signed.json` | Six-edge directed reference graph. |
| `Ground_Truth_UC_Tesla_Energy_Consumption_adjacency_matrix.npy` | Reference adjacency matrix. |
| `consensus_tesla_ev.csv` | Edges recurring across model-strategy outputs. |
| `edges_kg.csv` and `edges_kg.jsonld` | Parsed edge exports for downstream inspection. |
| `tesla_ev/` | Per-model JSON sidecars, predicted matrices, and graph figures. |

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

The best observed result is DeepSeek-R1 8B with skeleton-of-thought prompting. This recovers more true graph structure than the baselines, but still contains false positives and should be interpreted as a graph proposal.
