$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl
$count = ($lines | Measure-Object).Count
Write-Output "Total lines: $count"
$found = 0
foreach ($line in $lines) {
    try {
        $j = $line | ConvertFrom-Json
        if ($j -and ($j.kind -eq 'checkpoint' -or $j.kind -eq 'anchor')) {
            Write-Output "$($j.ts) | kind=$($j.kind) | summary=$($j.summary)"
            $found++
        }
    } catch {}
}
Write-Output "Total anchors/checkpoints: $found"
