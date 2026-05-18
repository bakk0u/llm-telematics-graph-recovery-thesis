# Scripts

Run commands from the repository root.

## Artifact Validation

`validate_artifacts.py` checks the committed graph-recovery artifact set without changing any result files.

```powershell
python scripts\validate_artifacts.py
```

`validate_results.py` is retained as a backward-compatible wrapper around the same validator.

## Figure Regeneration

`generate_graph_recovery_figures.ps1` regenerates the graph-recovery figures from `results/tesla_ev_graph_recovery/`.

```powershell
PowerShell -ExecutionPolicy Bypass -File scripts\generate_graph_recovery_figures.ps1
```

## Optional Experiment Rerun

The notebook in `notebooks/` documents the experiment source. A full rerun requires local Ollama models and should write new outputs separately before replacing the validated artifact set.
