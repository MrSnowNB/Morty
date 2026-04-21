$ErrorActionPreference = "Stop"
$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl
$all = foreach ($l in $lines) { try { $l | ConvertFrom-Json } catch { $null } }
$all = $all | Where-Object { $_ -ne $null }

$begins = $all | Where-Object { $_.kind -eq 'task_begin' }
$successes = $all | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' }
Write-Output "task_begins: $($begins.Count)"
Write-Output "task_successes: $($successes.Count)"
if ($begins.Count -gt 0) { $tcr = [math]::Round($successes.Count / $begins.Count, 4) } else { $tcr = 'N/A' }
Write-Output "task_completion_rate: $tcr"
