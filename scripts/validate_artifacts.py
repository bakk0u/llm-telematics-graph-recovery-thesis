"""Validate thesis graph-recovery artifacts without changing results."""

from __future__ import annotations

import csv
import json
import math
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

EXPECTED_BEST = {
    "model": "deepseek-r1:8b",
    "strategy": "Strategy_26_Skeleton_of_Thought",
    "F1 Score": 0.5333,
}


def require(path: Path) -> None:
    if not path.exists():
        raise FileNotFoundError(f"Missing required artifact: {path.relative_to(ROOT)}")


def read_csv(path: Path) -> list[dict[str, str]]:
    require(path)
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def read_json(path: Path) -> object:
    require(path)
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def as_float(row: dict[str, str], column: str) -> float:
    try:
        return float(row[column])
    except KeyError as exc:
        raise AssertionError(f"Missing column: {column}") from exc


def validate_required_files() -> None:
    required_files = [
        ROOT / "README.md",
        ROOT / "REPRODUCIBILITY.md",
        ROOT / "CITATION.cff",
        ROOT / "LICENSE",
        ROOT / "docs" / "system_pipeline.svg",
        ROOT / "data" / "tesla.csv",
        ROOT / "configs" / "graph_recovery_config.json",
        RESULTS / "README.md",
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


def validate_config() -> None:
    config = read_json(ROOT / "configs" / "graph_recovery_config.json")
    generation = config.get("generation", {})
    if generation.get("n_runs_per_validated_cell") != 1:
        raise AssertionError("Expected n_runs_per_validated_cell = 1 in graph_recovery_config.json")
    if config.get("dataset", {}).get("path") != "data/tesla.csv":
        raise AssertionError("Unexpected dataset path in graph_recovery_config.json")


def validate_result_matrix() -> list[dict[str, str]]:
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

    for row in rows:
        for metric in METRICS:
            value = as_float(row, metric)
            if not math.isfinite(value):
                raise AssertionError(f"Non-finite {metric} value in {row['row_label']}")
        if row.get("dataset") != "tesla_ev":
            raise AssertionError(f"Unexpected dataset in {row['row_label']}")

    best = max(rows, key=lambda row: as_float(row, "F1 Score"))
    if best["model"] != EXPECTED_BEST["model"] or best["strategy"] != EXPECTED_BEST["strategy"]:
        raise AssertionError("Unexpected best F1 model-strategy cell")
    if abs(as_float(best, "F1 Score") - EXPECTED_BEST["F1 Score"]) > 1e-4:
        raise AssertionError("Unexpected best F1 value")
    return rows


def validate_ground_truth() -> None:
    ground_truth = read_json(RESULTS / "Ground_Truth_UC_Tesla_Energy_Consumption_signed.json")
    features = ground_truth.get("features", [])
    edges = ground_truth.get("edges_signed", [])
    if len(features) != 6 or ground_truth.get("n_edges") != 6 or len(edges) != 6:
        raise AssertionError("Ground-truth graph should contain six features and six directed edges")
    feature_set = set(features)
    for edge in edges:
        if edge.get("source") not in feature_set or edge.get("target") not in feature_set:
            raise AssertionError(f"Ground-truth edge uses an unknown feature: {edge}")


def validate_sidecars() -> None:
    for model, folder in MODELS.items():
        for strategy in STRATEGIES:
            base = RESULTS / "tesla_ev" / folder / strategy
            for suffix in [".json", ".npy", ".png"]:
                require(base.with_suffix(suffix))
            sidecar = read_json(base.with_suffix(".json"))
            if sidecar.get("model") != model or sidecar.get("strategy") != strategy:
                raise AssertionError(f"Metadata mismatch in {base.with_suffix('.json').relative_to(ROOT)}")
            if sidecar.get("n_runs") != 1:
                raise AssertionError(f"Expected n_runs=1 in {base.with_suffix('.json').relative_to(ROOT)}")
            scores = sidecar.get("scores", {})
            for metric in METRICS:
                if metric not in scores:
                    raise AssertionError(f"Missing {metric} in {base.with_suffix('.json').relative_to(ROOT)}")


def validate_consensus() -> None:
    rows = read_csv(RESULTS / "consensus_tesla_ev.csv")
    if len(rows) != 5:
        raise AssertionError(f"Expected five consensus edges, found {len(rows)}")
    top = rows[0]
    if top["source"] != "electricenergyremaining" or top["target"] != "electricremaining":
        raise AssertionError("Unexpected top consensus edge")


def main() -> None:
    validate_required_files()
    validate_config()
    rows = validate_result_matrix()
    validate_ground_truth()
    validate_sidecars()
    validate_consensus()

    print("Validated thesis graph-recovery artifacts")
    print(f"- result rows: {len(rows)}")
    print(f"- models: {', '.join(MODELS)}")
    print(f"- strategies: {len(STRATEGIES)}")
    print("- n_runs per validated cell: 1")
    print("- best F1: deepseek-r1:8b + Strategy_26_Skeleton_of_Thought = 0.5333")


if __name__ == "__main__":
    main()

