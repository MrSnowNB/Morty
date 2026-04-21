cd C:/work/harness-sandbox
$output = & .claude/skills/chain-miner/scripts/mine.ps1 -Tail 200
Write-Output $output
$currentContent = Get-Content C:/work/harness-sandbox/SCRATCH.md -Raw
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$reportJson = $output | ConvertFrom-Json
$candidateCount = $reportJson.candidates.Count
$tasksClosed = $reportJson.tasks_closed
$summaryText = "$tasksClosed tasks closed, $candidateCount candidates at threshold"
$mineBlock = @"

## MINE [$timestamp] (journal-health seed pair)

```json
$($output | ConvertTo-Json -Depth 6)
```

**Summary:** $summaryText
"@
Add-Content C:/work/harness-sandbox/SCRATCH.md -Value $mineBlock
