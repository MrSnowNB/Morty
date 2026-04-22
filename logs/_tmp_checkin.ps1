$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl
$totalLines = ($lines | Measure-Object).Lines
Write-Output "total_journal_lines: $totalLines"

$entries = foreach ($l in $lines) {
    try { $j = $l | ConvertFrom-Json } catch { $j = $null }
    $j
}
$entries = $entries | Where-Object { $null -ne $_ }

# Last tool_call
$lastToolCall = $entries | Where-Object { $_.kind -eq 'tool_call' } | Select-Object -Last 1
Write-Output "last_tool_call_task_id: $($lastToolCall.task_id)"
Write-Output "last_tool_call_tool: $($lastToolCall.tool)"

# Last task_end
$lastTaskEnd = $entries | Where-Object { $_.kind -eq 'task_end' } | Select-Object -Last 1
Write-Output "last_task_end: task_id=$($lastTaskEnd.task_id) exit_status=$($lastTaskEnd.exit_status)"

# Count opens/closes
$taskBegins = $entries | Where-Object { $_.kind -eq 'task_begin' }
$taskEnds = $entries | Where-Object { $_.kind -eq 'task_end' }
Write-Output "total_begins: $($taskBegins.Count)"
Write-Output "total_ends: $($taskEnds.Count)"

# List all unique task_ids with begin/end
Write-Output "task_summary:"
$allTaskIds = $taskBegins.task_id + $taskEnds.task_id | Select-Object -Unique
foreach ($tid in $allTaskIds) {
    $begCount = ($taskBegins | Where-Object { $_.task_id -eq $tid }).Count
    $endCount = ($taskEnds | Where-Object { $_.task_id -eq $tid }).Count
    Write-Output "  ${tid}: begins=${begCount} ends=${endCount}"
}
