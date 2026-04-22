# chain-seed fix-a: write task_begin with start time
$start = Get-Date
$ts = $start.ToUniversalTime().ToString("o")
$json = @"
{"ts":"$ts","agent_id":"morty","task_id":"journal-health-1","kind":"task_begin","summary":"chain-seed journal-health-1","next_action":null}
"@
Add-Content -Path logs/morty-journal.jsonl -Value $json -Encoding utf8
# Save start time for task_end
$start.ToUniversalTime().ToString("o") | Set-Content logs/.seed-a-start.txt
Write-Output "task_begin written for journal-health-1"
