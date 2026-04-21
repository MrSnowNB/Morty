$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl
$count = ($lines | Measure-Object).Count
Write-Output "Total journal lines: $count"
foreach ($line in $lines) {
    try {
        $j = $line | ConvertFrom-Json
        if ($j -and ($j.kind -eq 'anchor' -or $j.kind -eq 'checkpoint')) {
            Write-Output "$($j.ts) | kind=$($j.kind)"
        }
    } catch {}
}
