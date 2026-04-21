$ErrorActionPreference = "Stop"
$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl -Tail 300
$all = foreach ($l in $lines) { try { $l | ConvertFrom-Json } catch { $null } }
$all = $all | Where-Object { $_ -ne $null }

$calls = $all | Where-Object { $_.kind -eq 'tool_call' }
$errors = $calls | Where-Object { $_.exit_status -eq 'error' }
$totalCalls = $calls.Count
$errorCount = $errors.Count
if ($totalCalls -gt 0) { $errorRate = [math]::Round($errorCount / $totalCalls, 4) } else { $errorRate = 'N/A' }
Write-Output "session_tool_calls: $totalCalls"
Write-Output "session_errors: $errorCount"
Write-Output "session_error_rate: $errorRate"

$begins = $all | Where-Object { $_.kind -eq 'task_begin' }
$successes = $all | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' }
Write-Output "session_begins: $($begins.Count)"
Write-Output "session_successes: $($successes.Count)"
if ($begins.Count -gt 0) { $tcr = [math]::Round($successes.Count / $begins.Count, 4) } else { $tcr = 'N/A' }
Write-Output "session_tcr: $tcr"

# Also list task IDs for context
Write-Output "task_begins_list:"
$begins | ForEach-Object { Write-Output "  task_begin: $($_.task_id)" }
Write-Output "task_ends_list:"
$all | Where-Object { $_.kind -eq 'task_end' } | ForEach-Object { Write-Output "  task_end: task_id=$($_.task_id) exit=$($_.exit_status)" }
