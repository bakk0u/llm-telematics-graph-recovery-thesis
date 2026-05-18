Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$ResultDir = Join-Path $Root "results\tesla_ev_graph_recovery"
$FigureDir = Join-Path $Root "figures"
$GroundTruthPath = Join-Path $ResultDir "Ground_Truth_UC_Tesla_Energy_Consumption_signed.json"
$EvaluationPath = Join-Path $ResultDir "evaluation_matrix_tesla_ev_long.csv"

$Blue = [System.Drawing.Color]::FromArgb(31, 78, 121)
$Accent = [System.Drawing.Color]::FromArgb(184, 101, 27)
$Line = [System.Drawing.Color]::FromArgb(95, 108, 124)
$Light = [System.Drawing.Color]::FromArgb(243, 245, 247)
$Grid = [System.Drawing.Color]::FromArgb(215, 222, 230)
$Text = [System.Drawing.Color]::FromArgb(22, 31, 43)
$Muted = [System.Drawing.Color]::FromArgb(84, 96, 110)
$White = [System.Drawing.Color]::White
$Invariant = [System.Globalization.CultureInfo]::InvariantCulture

function New-Font {
  param([float]$Size, [string]$Style = "Regular")
  $fontStyle = [System.Drawing.FontStyle]::Regular
  if ($Style -eq "Bold") { $fontStyle = [System.Drawing.FontStyle]::Bold }
  New-Object System.Drawing.Font("Segoe UI", $Size, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-Canvas {
  param([int]$Width, [int]$Height)
  $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
  $bmp.SetResolution(240, 240)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $g.Clear($White)
  @($bmp, $g)
}

function Save-Canvas {
  param($Bitmap, $Graphics, [string]$Path)
  $Graphics.Flush()
  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $Graphics.Dispose()
  $Bitmap.Dispose()
}

function Brush([System.Drawing.Color]$Color) { New-Object System.Drawing.SolidBrush($Color) }
function Pen([System.Drawing.Color]$Color, [float]$Width = 2) { New-Object System.Drawing.Pen($Color, $Width) }

function Draw-Text {
  param($G, [string]$TextValue, $Font, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$W, [float]$H, [string]$Align = "Center", [string]$Valign = "Center")
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::$Align
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::$Valign
  $fmt.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
  $box = New-Object System.Drawing.RectangleF -ArgumentList @([single]$X, [single]$Y, [single]$W, [single]$H)
  $G.DrawString($TextValue, $Font, (Brush $Color), $box, $fmt)
  $fmt.Dispose()
}

function Draw-Node {
  param($G, [string]$Label, [float]$X, [float]$Y, [float]$W, [float]$H)
  $rect = New-Object System.Drawing.RectangleF -ArgumentList @([single]$X, [single]$Y, [single]$W, [single]$H)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r = 18
  $path.AddArc($X, $Y, $r, $r, 180, 90)
  $path.AddArc($X + $W - $r, $Y, $r, $r, 270, 90)
  $path.AddArc($X + $W - $r, $Y + $H - $r, $r, $r, 0, 90)
  $path.AddArc($X, $Y + $H - $r, $r, $r, 90, 90)
  $path.CloseFigure()
  $G.FillPath((Brush $Light), $path)
  $G.DrawPath((Pen $Blue 4), $path)
  Draw-Text $G $Label (New-Font 34 "Bold") $Text $X ($Y + 8) $W ($H - 16)
  $path.Dispose()
}

function Draw-Arrow {
  param($G, [float]$X1, [float]$Y1, [float]$X2, [float]$Y2, [System.Drawing.Color]$Color, [string]$Label, [float]$LX, [float]$LY)
  $p = Pen $Color 5
  $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap(8, 11, $true)
  $p.CustomEndCap = $cap
  $G.DrawLine($p, $X1, $Y1, $X2, $Y2)
  $labelFont = New-Font 24 "Regular"
  $size = $G.MeasureString($Label, $labelFont)
  $padX = 18; $padY = 8
  $rect = New-Object System.Drawing.RectangleF -ArgumentList @([single]$LX, [single]$LY, [single]($size.Width + 2*$padX), [single]($size.Height + 2*$padY))
  $G.FillRectangle((Brush ([System.Drawing.Color]::FromArgb(248, 250, 252))), $rect)
  $G.DrawRectangle((Pen $Grid 2), $rect.X, $rect.Y, $rect.Width, $rect.Height)
  Draw-Text $G $Label $labelFont $Muted ($LX + $padX) ($LY + $padY) $size.Width $size.Height
  $labelFont.Dispose()
  $cap.Dispose(); $p.Dispose()
}

function Mix {
  param([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$T)
  $t2 = [Math]::Max(0, [Math]::Min(1, $T))
  [System.Drawing.Color]::FromArgb(
    [int]($A.R + ($B.R - $A.R) * $t2),
    [int]($A.G + ($B.G - $A.G) * $t2),
    [int]($A.B + ($B.B - $A.B) * $t2)
  )
}

function Metric-Normalized {
  param([string]$Metric, [double]$Value)
  switch ($Metric) {
    "Precision" { return $Value }
    "Recall" { return $Value }
    "F1 Score" { return $Value }
    "Pearson Correlation" { return (($Value + 1.0) / 2.0) }
    "SHD" { return 1.0 - ($Value / 12.0) }
    "FDR" { return 1.0 - $Value }
    "Hamming Distance" { return 1.0 - ($Value / 0.35) }
    "Frobenius Norm" { return 1.0 - ($Value / 3.5) }
  }
  return $Value
}

function Short-Strategy {
  param([string]$Strategy)
  switch -Wildcard ($Strategy) {
    "*Zero*" { "S1 Zero-shot" }
    "*No_Instruction*" { "S23 No-instr." }
    "*Policy*" { "S24 Policy" }
    "*Least*" { "S25 Least-to-most" }
    "*Skeleton*" { "S26 Skeleton" }
    default { $Strategy }
  }
}

function Fmt {
  param([string]$Pattern, [double]$Value)
  [string]::Format($Invariant, "{0:$Pattern}", $Value)
}

function Draw-GroundTruth {
  $gt = Get-Content -Raw -LiteralPath $GroundTruthPath | ConvertFrom-Json
  $pair = New-Canvas 2800 1250
  $bmp = $pair[0]; $g = $pair[1]
  Draw-Text $g "Ground-truth Tesla EV graph" (New-Font 58 "Bold") $Text 0 64 2800 74
  Draw-Text $g "Six directed reference edges used for binary adjacency-matrix evaluation" (New-Font 30) $Muted 0 140 2800 44

  $nodes = @{
    "acceleration_kmh2" = @{ x = 220; y = 920; w = 510; h = 150; label = "acceleration`nkmh2" }
    "speed_kmh" = @{ x = 1060; y = 740; w = 400; h = 145; label = "speed`nkmh" }
    "distance_m" = @{ x = 2020; y = 430; w = 380; h = 135; label = "distance`nm" }
    "mileage" = @{ x = 2020; y = 1010; w = 380; h = 135; label = "mileage" }
    "electricenergyremaining" = @{ x = 430; y = 310; w = 560; h = 150; label = "electric energy`nremaining" }
    "electricremaining" = @{ x = 1430; y = 250; w = 500; h = 145; label = "electric`nremaining" }
  }

  Draw-Arrow $g 730 960 1060 825 $Blue "Positive (Strong)" 765 826
  Draw-Arrow $g 1460 772 2020 500 $Blue "Positive (Strong)" 1580 560
  Draw-Arrow $g 1460 835 2020 1068 $Blue "Positive (Strong)" 1580 940
  Draw-Arrow $g 1080 735 880 460 $Accent "Negative (Moderate)" 765 560
  Draw-Arrow $g 465 920 590 460 $Accent "Negative (Strong)" 280 645
  Draw-Arrow $g 990 370 1430 323 $Blue "Positive (Strong)" 1085 246

  foreach ($key in $nodes.Keys) {
    $n = $nodes[$key]
    Draw-Node $g $n.label $n.x $n.y $n.w $n.h
  }
  Save-Canvas $bmp $g (Join-Path $FigureDir "Ground_Truth_UC_Tesla_Energy_Consumption.png")
}

function Draw-EvaluationHeatmap {
  $rows = Import-Csv -LiteralPath $EvaluationPath
  $metrics = @("Precision", "Recall", "F1 Score", "SHD", "FDR", "Pearson Correlation", "Hamming Distance", "Frobenius Norm")
  $pair = New-Canvas 3600 2100
  $bmp = $pair[0]; $g = $pair[1]
  Draw-Text $g "Tesla EV graph-recovery evaluation matrix" (New-Font 58 "Bold") $Text 0 58 3600 76
  Draw-Text $g "Cell values are copied from evaluation_matrix_tesla_ev_long.csv; color intensity indicates better metric direction." (New-Font 30) $Muted 0 132 3600 48

  $left = 500; $top = 320; $cellW = 310; $cellH = 128
  $fontHead = New-Font 25 "Bold"; $fontCell = New-Font 29; $fontSmall = New-Font 24
  for ($c = 0; $c -lt $metrics.Count; $c++) {
    Draw-Text $g $metrics[$c] $fontHead $Text ($left + $c*$cellW) 232 $cellW 78
  }
  for ($r = 0; $r -lt $rows.Count; $r++) {
    $row = $rows[$r]
    $label = (($row.model -replace ":8b","") + "`n" + (Short-Strategy $row.strategy))
    Draw-Text $g $label $fontSmall $Text 40 ($top + $r*$cellH) 425 $cellH "Far" "Center"
    for ($c = 0; $c -lt $metrics.Count; $c++) {
      $metric = $metrics[$c]
      $value = [double]$row.PSObject.Properties[$metric].Value
      $norm = Metric-Normalized $metric $value
      $norm = [Math]::Max(0, [Math]::Min(1, $norm))
      $fill = Mix $White $Blue (0.12 + 0.70*$norm)
      $rect = New-Object System.Drawing.RectangleF -ArgumentList @([single]($left + $c*$cellW), [single]($top + $r*$cellH), [single]$cellW, [single]$cellH)
      $g.FillRectangle((Brush $fill), $rect)
      $g.DrawRectangle((Pen $Grid 2), $rect.X, $rect.Y, $rect.Width, $rect.Height)
      if ($metric -eq "SHD") { $txt = Fmt "0" $value } else { $txt = Fmt "0.0000" $value }
      $txtColor = $Text
      if ($norm -gt 0.62) { $txtColor = $White }
      Draw-Text $g $txt $fontCell $txtColor $rect.X $rect.Y $rect.Width $rect.Height
    }
  }
  Draw-Text $g "Higher is better: Precision, Recall, F1, Pearson. Lower is better: SHD, FDR, Hamming, Frobenius." (New-Font 27) $Muted 0 1830 3600 50
  Save-Canvas $bmp $g (Join-Path $FigureDir "evaluation_matrix_tesla_ev_heatmap.png")
}

function Draw-F1Heatmap {
  $rows = Import-Csv -LiteralPath $EvaluationPath
  $models = @("deepseek-r1:8b", "llama3.1:8b")
  $strategies = @(
    "Strategy_1_Zero_Shot_Prompting",
    "Strategy_23_No_Instruction_Control",
    "Strategy_24_Policy_First_Structured",
    "Strategy_25_Least_to_Most",
    "Strategy_26_Skeleton_of_Thought"
  )
  $pair = New-Canvas 2600 1450
  $bmp = $pair[0]; $g = $pair[1]
  Draw-Text $g "F1 score by model and prompt strategy" (New-Font 56 "Bold") $Text 0 58 2600 76
  Draw-Text $g "Higher values indicate stronger edge-recovery balance in the observed model-strategy cell." (New-Font 29) $Muted 0 132 2600 48

  $left = 760; $top = 330; $cellW = 720; $cellH = 155
  $fontHead = New-Font 31 "Bold"; $fontCell = New-Font 42 "Bold"; $fontRow = New-Font 29
  for ($c = 0; $c -lt $models.Count; $c++) {
    Draw-Text $g $models[$c] $fontHead $Text ($left + $c*$cellW) 240 $cellW 72
  }
  for ($r = 0; $r -lt $strategies.Count; $r++) {
    $strategy = $strategies[$r]
    Draw-Text $g (Short-Strategy $strategy) $fontRow $Text 80 ($top + $r*$cellH) 620 $cellH "Far" "Center"
    for ($c = 0; $c -lt $models.Count; $c++) {
      $model = $models[$c]
      $row = $rows | Where-Object { $_.model -eq $model -and $_.strategy -eq $strategy } | Select-Object -First 1
      $value = [double]$row.PSObject.Properties["F1 Score"].Value
      $norm = [Math]::Min(1, $value / 0.55)
      $fill = Mix $White $Blue (0.12 + 0.78*$norm)
      $rect = New-Object System.Drawing.RectangleF -ArgumentList @([single]($left + $c*$cellW), [single]($top + $r*$cellH), [single]$cellW, [single]$cellH)
      $g.FillRectangle((Brush $fill), $rect)
      $g.DrawRectangle((Pen $Grid 3), $rect.X, $rect.Y, $rect.Width, $rect.Height)
      $txtColor = $Text
      if ($norm -gt 0.58) { $txtColor = $White }
      Draw-Text $g (Fmt "0.0000" $value) $fontCell $txtColor $rect.X $rect.Y $rect.Width $rect.Height
    }
  }
  Draw-Text $g "Values unchanged; color scale is normalized to the strongest observed F1 score." (New-Font 27) $Muted 0 1215 2600 48
  Save-Canvas $bmp $g (Join-Path $FigureDir "f1_strategy_vs_model_tesla_ev.png")
}

Draw-GroundTruth
Draw-EvaluationHeatmap
Draw-F1Heatmap
