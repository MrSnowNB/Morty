$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl -Tail 100
foreach ($line in $lines) {
    $j = $line | ConvertFrom-Json
    if ($j -and ($j.kind -eq 'checkpoint' -or $j.kind -eq 'anchor')) {
        Write-Output "$($j.ts) | kind=$($j.kind)"
    }
}
