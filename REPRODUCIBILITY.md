# Reproducibility

This repository supports artifact-level reproducibility for the thesis results. The validated result files are committed, and the validation script checks that the metrics, ground-truth graph, model-strategy sidecars, predicted matrices, and figures are internally consistent.

## Dataset

The dataset used by the thesis is included at:

```text
data/tesla.csv
```

The thesis uses six telemetry features:

```text
electricenergyremaining
electricremaining
speed_kmh
acceleration_kmh2
mileage
distance_m
```

The experiment configuration records 65,261 rows and excludes `timestamp` and `vehiclespeed` from the graph prompt task.

## Models and Runtime

The experiment uses local Ollama models:

```text
llama3.1:8b
deepseek-r1:8b
```

The recorded runtime settings are in `configs/graph_recovery_config.json`:

```text
temperature: 0.2
top_p: 0.9
num_ctx: 8192
deepseek_num_predict_override: 1024
n_runs_per_validated_cell: 1
```

Because `n_runs_per_validated_cell` is 1, the thesis reports descriptive graph-recovery results. It does not claim repeated-run stability or statistical significance.

## Artifact Validation

Install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Validate the committed results:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate_results.ps1
```

Python equivalent:

```powershell
python scripts\validate_results.py
```

The validator checks:

- required result files exist;
- evaluation matrices contain the expected ten model-strategy cells;
- required graph metrics are present;
- the ground-truth graph contains six features and six directed edges;
- every model-strategy cell has a JSON sidecar, predicted adjacency matrix, and graph figure;
- the best F1 cell is `deepseek-r1:8b` with `Strategy_26_Skeleton_of_Thought`.

## Figure Regeneration

The committed figures can be regenerated from the result matrices:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\generate_graph_recovery_figures.ps1
```

## Full Rerun Boundary

The notebook `notebooks/tesla_graph_recovery_llama3_deepseek.ipynb` documents the experiment source. A full rerun requires local Ollama availability and may produce different individual outputs because LLM generation is stochastic. New reruns should be stored separately and compared with the committed artifact set before replacing thesis results.
