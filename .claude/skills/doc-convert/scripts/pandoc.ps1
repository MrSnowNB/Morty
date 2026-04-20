param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$Out
)
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
  Write-Error "pandoc not found. Install via: winget install JohnMacFarlane.Pandoc"
  exit 1
}
if (-not (Test-Path $In))  { Write-Error "Input not found: $In"; exit 2 }
if (Test-Path $Out) { Write-Error "Output exists, refusing to overwrite: $Out"; exit 3 }
& pandoc $In -o $Out
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$size = (Get-Item $Out).Length
Write-Output "wrote:$Out size:$size"
