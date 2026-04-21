cd C:/work/harness-sandbox
if (Test-Path .claude/skills/chain-miner/scripts/mine.ps1) {
    & .claude/skills/chain-miner/scripts/mine.ps1 -Tail 200
} else {
    Write-Output 'mine.ps1 not found'
    Get-ChildItem .claude/skills/chain-miner/ -Recurse
}
