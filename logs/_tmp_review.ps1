$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl -Tail 300
$entries = foreach ($l in $lines) {
    try { $j = $l | ConvertFrom-Json } catch { $null }
    if ($null -ne $j) { $j }
}
$toolCalls = $entries | Where-Object { $_.kind -eq 'tool_call' }
Write-Output "Total tool_calls in last 300 lines: $($toolCalls.Count)"
Write-Output ""
Write-Output "Tools used (count):"
$toolCalls | Group-Object tool | ForEach-Object {
    Write-Output "  $($_.Name): $($_.Count)"
}
Write-Output ""
Write-Output "Task distribution:"
$toolCalls | Group-Object task_id | ForEach-Object {
    $tid = if ($_.Name) { $_.Name } else { '(empty)' }
    Write-Output "  ${tid}: $($_.Count)"
}
Write-Output ""
Write-Output "Recent tool_calls (last 20):"
$toolCalls | Select-Object -Last 20 | ForEach-Object {
    $sum = if ($_.summary.Length -gt 80) { $_.summary.Substring(0,80) + '...' } else { $_.summary }
    $tid = if ($_.task_id) { $_.task_id } else { '(empty)' }
    Write-Output "  $($_.ts) | $tid | $($_.tool) | $sum"
}
