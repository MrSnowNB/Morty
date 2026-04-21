# Appends a single JSON line to the project journal with mutex-protected write.
# Usage: echo '<json>' | pwsh -File append.ps1
param(
  [string]$JournalPath = "$env:MORTY_PROJECT_ROOT\logs\morty-journal.jsonl"
)

# Execution policy bypass scoped to this process only — script is intentionally unsigned.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$payload = [Console]::In.ReadToEnd().Trim()
if (-not $payload) { Write-Error "No payload on stdin"; exit 1 }
try { $null = $payload | ConvertFrom-Json } catch { Write-Error "Invalid JSON: $_"; exit 2 }
$dir = Split-Path $JournalPath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$mutex = New-Object System.Threading.Mutex($false, "Global\MortyJournal")
try {
  $null = $mutex.WaitOne()
  Add-Content -Path $JournalPath -Value $payload -Encoding utf8
} finally {
  $mutex.ReleaseMutex()
  $mutex.Dispose()
}
Write-Output "appended:$JournalPath"
