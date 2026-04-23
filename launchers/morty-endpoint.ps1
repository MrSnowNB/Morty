# morty-endpoint.ps1
# Probes common Lemonade router ports and returns the first one that answers
# with a model list containing Qwen3.6-30B-A3B.
# Usage: $url = & .\launchers\morty-endpoint.ps1
# Exit 0 = found, Exit 1 = not found

$candidates = @(8000, 8001, 8004, 8080)
$modelPattern = 'Qwen3\.6-30B-A3B'

foreach ($port in $candidates) {
  try {
    $uri = "http://127.0.0.1:$port/api/v1/models"
    $r = Invoke-WebRequest -Uri $uri -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    if ($r.StatusCode -eq 200 -and $r.Content -match $modelPattern) {
      Write-Output "http://127.0.0.1:$port"
      exit 0
    }
  } catch {
    continue
  }
}

Write-Error "[morty-endpoint] No Lemonade endpoint serving '$modelPattern' found on ports: $($candidates -join ', ')."
Write-Error "Start Lemonade Server and ensure user.Qwen3.6-30B-A3B-GGUF is loaded."
exit 1
