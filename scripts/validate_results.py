"""Validate the committed graph-recovery result artifacts."""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results" / "tesla_ev_graph_recovery"

MODELS = {
    "deepseek-r1:8b": "deepseek_r1_8b",
    "llama3.1:8b": "llama3_1_8b",
}

STRATEGIES = [
    "Strategy_1_Zero_Shot_Prompting",
    "Strategy_23_No_Instruction_Control",
    "Strategy_24_Policy_First_Structured",
    "Strategy_25_Least_to_Most",
    "Strategy_26_Skeleton_of_Thought",
]

METRICS = [
    "Precision",
    "Recall",
    "F1 Score",
    "SHD",
    "FDR",
    "Pearson Correlation",
    "Hamming Distance",
    "Frobenius Norm",
]


def require(path: Path) -> None:
    if not path.exists():
        raise FileNotFoundError(f"Missing required artifact: {path.relative_to(ROOT)}")


def read_csv(path: Path) -> list[dict[str, str]]:
    require(path)
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def main() -> None:
    required_files = [
        ROOT / "data" / "tesla.csv",
        ROOT / "configs" / "graph_recovery_config.json",
        RESULTS / "evaluation_matrix_tesla_ev.csv",
        RESULTS / "evaluation_matrix_tesla_ev_long.csv",
        RESULTS / "consensus_tesla_ev.csv",
        RESULTS / "edges_kg.csv",
        RESULTS / "edges_kg.jsonld",
        RESULTS / "evaluation_matrix_tesla_ev_heatmap.png",
        RESULTS / "evaluation_per_llm_tesla_ev.png",
        RESULTS / "f1_strategy_vs_model_tesla_ev.png",
        RESULTS / "Ground_Truth_UC_Tesla_Energy_Consumption.png",
        RESULTS / "Ground_Truth_UC_Tesla_Energy_Consumption_adjacency_matrix.npy",
        RESULTS / "Ground_Truth_UC_Tesla_Energy_Consumption_signed.json",
    ]
    for path in required_files:
        require(path)

    rows = read_csv(RESULTS / "evaluation_matrix_tesla_ev_long.csv")
    if len(rows) != len(MODELS) * len(STRATEGIES):
        raise AssertionError(f"Expected 10 result rows, found {len(rows)}")

    missing_metrics = [metric for metric in METRICS if metric not in rows[0]]
    if missing_metrics:
        raise AssertionError(f"Missing metric columns: {missing_metrics}")

    seen = {(row["model"], row["strategy"]) for row in rows}
    expected = {(model, strategy) for model in MODELS for strategy in STRATEGIES}
    if seen != expected:
        raise AssertionError(f"Unexpected model-strategy cells: {sorted(seen ^ expected)}")

    with (RESULTS / "Ground_Truth_UC_Tesla_Energy_Consumption_signed.json").open(encoding="utf-8") as handle:
        ground_truth = json.load(handle)
    if len(ground_truth.get("features", [])) != 6 or ground_truth.get("n_edges") != 6:
        raise AssertionError("Ground-truth graph should contain six features and six edges")

    for model, folder in MODELS.items():
        for strategy in STRATEGIES:
            base = RESULTS / "tesla_ev" / folder / strategy
            for suffix in [".json", ".npy", ".png"]:
                require(base.with_suffix(suffix))
            with base.with_suffix(".json").open(encoding="utf-8") as handle:
                sidecar = json.load(handle)
            if sidecar.get("model") != model or sidecar.get("strategy") != strategy:
                raise AssertionError(f"Metadata mismatch in {base.with_suffix('.json').relative_to(ROOT)}")
            if sidecar.get("n_runs") != 1:
                raise AssertionError(f"Expected n_runs=1 in {base.with_suffix('.json').relative_to(ROOT)}")

    best = max(rows, key=lambda row: float(row["F1 Score"]))
    if best["model"] != "deepseek-r1:8b" or best["strategy"] != "Strategy_26_Skeleton_of_Thought":
        raise AssertionError("Unexpected best F1 model-strategy cell")
    if abs(float(best["F1 Score"]) - 0.5333) > 1e-4:
        raise AssertionError("Unexpected best F1 value")

    print("Validated graph-recovery artifacts")
    print(f"- result rows: {len(rows)}")
    print(f"- models: {', '.join(MODELS)}")
    print(f"- strategies: {len(STRATEGIES)}")
    print("- best F1: deepseek-r1:8b + Strategy_26_Skeleton_of_Thought = 0.5333")


if __name__ == "__main__":
    main()
