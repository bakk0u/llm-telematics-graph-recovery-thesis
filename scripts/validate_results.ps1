$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Results = Join-Path $Root "results\tesla_ev_graph_recovery"

$Models = @{
    "deepseek-r1:8b" = "deepseek_r1_8b"
    "llama3.1:8b" = "llama3_1_8b"
}

$Strategies = @(
    "Strategy_1_Zero_Shot_Prompting",
    "Strategy_23_No_Instruction_Control",
    "Strategy_24_Policy_First_Structured",
    "Strategy_25_Least_to_Most",
    "Strategy_26_Skeleton_of_Thought"
)

$Metrics = @(
    "Precision",
    "Recall",
    "F1 Score",
    "SHD",
    "FDR",
    "Pearson Correlation",
    "Hamming Distance",
    "Frobenius Norm"
)

function Require-Path {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required artifact: $Path"
    }
}

$RequiredFiles = @(
    "README.md",
    "REPRODUCIBILITY.md",
    "CITATION.cff",
    "LICENSE",
    "docs\system_pipeline.svg",
    "data\tesla.csv",
    "configs\graph_recovery_config.json",
    "results\tesla_ev_graph_recovery\README.md",
    "results\tesla_ev_graph_recovery\evaluation_matrix_tesla_ev.csv",
    "results\tesla_ev_graph_recovery\evaluation_matrix_tesla_ev_long.csv",
    "results\tesla_ev_graph_recovery\consensus_tesla_ev.csv",
    "results\tesla_ev_graph_recovery\edges_kg.csv",
    "results\tesla_ev_graph_recovery\edges_kg.jsonld",
    "results\tesla_ev_graph_recovery\evaluation_matrix_tesla_ev_heatmap.png",
    "results\tesla_ev_graph_recovery\evaluation_per_llm_tesla_ev.png",
    "results\tesla_ev_graph_recovery\f1_strategy_vs_model_tesla_ev.png",
    "results\tesla_ev_graph_recovery\Ground_Truth_UC_Tesla_Energy_Consumption.png",
    "results\tesla_ev_graph_recovery\Ground_Truth_UC_Tesla_Energy_Consumption_adjacency_matrix.npy",
    "results\tesla_ev_graph_recovery\Ground_Truth_UC_Tesla_Energy_Consumption_signed.json"
)

foreach ($File in $RequiredFiles) {
    Require-Path (Join-Path $Root $File)
}

$Config = Get-Content -LiteralPath (Join-Path $Root "configs\graph_recovery_config.json") -Raw | ConvertFrom-Json
if ($Config.generation.n_runs_per_validated_cell -ne 1) {
    throw "Expected n_runs_per_validated_cell=1 in configs\graph_recovery_config.json"
}
if ($Config.dataset.path -ne "data/tesla.csv") {
    throw "Unexpected dataset path in configs\graph_recovery_config.json"
}

$Rows = Import-Csv -LiteralPath (Join-Path $Results "evaluation_matrix_tesla_ev_long.csv")
if ($Rows.Count -ne ($Models.Count * $Strategies.Count)) {
    throw "Expected 10 result rows, found $($Rows.Count)"
}

$Columns = $Rows[0].PSObject.Properties.Name
foreach ($Metric in $Metrics) {
    if ($Columns -notcontains $Metric) {
        throw "Missing metric column: $Metric"
    }
}

$Seen = @{}
foreach ($Row in $Rows) {
    $Seen["$($Row.model)|$($Row.strategy)"] = $true
}

foreach ($Model in $Models.Keys) {
    foreach ($Strategy in $Strategies) {
        $Key = "$Model|$Strategy"
        if (-not $Seen.ContainsKey($Key)) {
            throw "Missing model-strategy cell: $Key"
        }
    }
}

$GroundTruth = Get-Content -LiteralPath (Join-Path $Results "Ground_Truth_UC_Tesla_Energy_Consumption_signed.json") -Raw | ConvertFrom-Json
if ($GroundTruth.features.Count -ne 6 -or $GroundTruth.n_edges -ne 6) {
    throw "Ground-truth graph should contain six features and six edges"
}

$Consensus = Import-Csv -LiteralPath (Join-Path $Results "consensus_tesla_ev.csv")
if ($Consensus.Count -ne 5) {
    throw "Expected five consensus edges, found $($Consensus.Count)"
}

foreach ($Model in $Models.Keys) {
    $Folder = $Models[$Model]
    foreach ($Strategy in $Strategies) {
        $Base = Join-Path $Results "tesla_ev\$Folder\$Strategy"
        foreach ($Suffix in @(".json", ".npy", ".png")) {
            Require-Path "$Base$Suffix"
        }
        $Sidecar = Get-Content -LiteralPath "$Base.json" -Raw | ConvertFrom-Json
        if ($Sidecar.model -ne $Model -or $Sidecar.strategy -ne $Strategy) {
            throw "Metadata mismatch in $Base.json"
        }
        if ($Sidecar.n_runs -ne 1) {
            throw "Expected n_runs=1 in $Base.json"
        }
    }
}

$Best = $Rows | Sort-Object {[double]($_."F1 Score")} -Descending | Select-Object -First 1
if ($Best.model -ne "deepseek-r1:8b" -or $Best.strategy -ne "Strategy_26_Skeleton_of_Thought") {
    throw "Unexpected best F1 model-strategy cell"
}
if ([math]::Abs([double]($Best."F1 Score") - 0.5333) -gt 0.0001) {
    throw "Unexpected best F1 value"
}

Write-Output "Validated graph-recovery artifacts"
Write-Output "- result rows: $($Rows.Count)"
Write-Output "- models: $($Models.Keys -join ', ')"
Write-Output "- strategies: $($Strategies.Count)"
Write-Output "- best F1: deepseek-r1:8b + Strategy_26_Skeleton_of_Thought = 0.5333"
