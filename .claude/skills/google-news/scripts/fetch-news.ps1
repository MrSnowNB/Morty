# Google News RSS Fetcher
# Fetches top 5 news stories from Google News RSS feed
# Usage: .\fetch-news.ps1 [--json]
#
# Output: clean headlines with source, time, and link.
# Agent generates summaries from the headlines.

param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function ConvertFrom-Html {
    param([string]$Html)
    $html = $Html -replace '<[^>]+>', ''
    $html = [System.Net.WebUtility]::HtmlDecode($html)
    $html = $html -replace '&nbsp;', ' '
    $html = $html -replace '\s+', ' '
    return $html.Trim()
}

function Format-Description {
    param([string]$Description)
    # Google News RSS descriptions: <ol><li><a href="...">Headline</a> <font>Source</font></li>...
    $liMatch = [regex]::Match($Description, '<li[^>]*>(.*?)</li>')
    if ($liMatch.Success) {
        $firstLi = $liMatch.Groups[1].Value
        $titleMatch = [regex]::Match($firstLi, '<a[^>]*>([^<]+)</a>')
        $sourceMatch = [regex]::Match($firstLi, '<font[^>]*color="[^"]*"[^>]*>([^<]+)</font>')
        if ($titleMatch.Success) {
            $title = $titleMatch.Groups[1].Value.Trim()
            $source = if ($sourceMatch.Success) { $sourceMatch.Groups[1].Value.Trim() } else { '' }
            return @{ Title = $title; Source = $source }
        }
        return @{ Title = ConvertFrom-Html $firstLi; Source = '' }
    }
    return @{ Title = ConvertFrom-Html $Description; Source = '' }
}

# --- Main ---

$feedUrl = 'https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en'

try {
    $response = Invoke-RestMethod -Uri $feedUrl -Method Get -TimeoutSec 15
}
catch {
    Write-Error "Failed to fetch Google News RSS feed: $_"
    exit 1
}

$items = $response
if (-not $items) {
    Write-Error "RSS feed returned no items."
    exit 1
}

$top5 = $items | Select-Object -First 5

if ($Json) {
    $output = $top5 | ForEach-Object {
        $fmt = Format-Description $_.description
        $source = if ($_.source.'#text') { $_.source.'#text' } else { 'Unknown' }
        [PSCustomObject]@{
            title       = $fmt.Title
            link        = $_.link
            description = $fmt.Source
            source      = $source
            published   = $_.pubDate
        }
    } | ConvertTo-Json -Depth 4
    Write-Output $output
}
else {
    Write-Output "TOP_STORY_START"
    $i = 1
    foreach ($item in $top5) {
        $fmt = Format-Description $item.description
        $source = if ($item.source.'#text') { $item.source.'#text' } else { 'Unknown' }
        Write-Output "$i| $($fmt.Title) | $source | $($item.pubDate) | $($item.link)"
        $i++
    }
    Write-Output "TOP_STORY_END"
}
