$lines = Get-Content C:/work/harness-sandbox/logs/morty-journal.jsonl
$entries = foreach ($l in $lines) {
    try { $j = $l | ConvertFrom-Json } catch { $null }
    if ($null -ne $j) { $j }
}

$toolCalls = $entries | Where-Object { $_.kind -eq 'tool_call' }

Write-Output "=== TOOL USAGE SUMMARY ==="
$toolCalls | Group-Object tool | Sort-Object Count -Descending | ForEach-Object {
    Write-Output "  $($_.Name): $($_.Count)"
}

Write-Output ""
Write-Output "=== TASK DISTRIBUTION ==="
$taskIds = $toolCalls | Where-Object { $_.task_id } | Select-Object -ExpandProperty task_id -Unique
$taskIds | Sort-Object | ForEach-Object {
    $count = ($toolCalls | Where-Object { $_.task_id -eq $_ }).Count
    # Fix: use explicit variable
    $tid = $_
    $cnt = ($toolCalls | Where-Object { $_.task_id -eq $tid }).Count
    Write-Output "  $tid: $cnt tool_calls"
}

Write-Output ""
Write-Output "=== REPEATED SINGLE TOOLS ==="
$toolCalls | Group-Object tool | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Output "  $($_.Name): $($_.Count) calls"
}

Write-Output ""
Write-Output "=== COMMON COMMAND PATTERNS (Bash) ==="
$bashCalls = $toolCalls | Where-Object { $_.tool -eq 'Bash' }
$bashCalls | ForEach-Object {
    $sum = $_.summary
    # Normalize: extract command pattern
    if ($sum -match '"command"\s*:\s*"([^"]+)"') {
        $cmd = $matches[1]
        # Normalize paths and timestamps
        $cmd = $cmd -replace '[A-Za-z]:\\[^",\s]+', '<path>'
        $cmd = $cmd -replace '\d{4}-\d{2}-\d{2}T[\d:.Z+\-]+', '<ts>'
        if ($cmd.Length -gt 120) { $cmd = $cmd.Substring(0,120) + '...' }
        Write-Output "  $cmd"
    }
} | Sort-Object | Group-Object | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Output "  COUNT=$($_.Count): $($_.Name)"
}

Write-Output ""
Write-Output "=== COMMON READ PATTERNS ==="
$readCalls = $toolCalls | Where-Object { $_.tool -eq 'Read' }
$readCalls | ForEach-Object {
    if ($_.summary -match '"file_path"\s*:\s*"([^"]+)"') {
        $path = $matches[1]
        $path = $path -replace 'C:\\work\\harness-sandbox\\', ''
        Write-Output "  Read: $path"
    }
} | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Output "  COUNT=$($_.Count): $($_.Name)"
}
