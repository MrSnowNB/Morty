param(
  [Parameter(Mandatory=$true)][string]$Path,
  [switch]$Ocr
)
$py = "$env:USERPROFILE\.claude\.venv\Scripts\python.exe"
if (-not (Test-Path $py)) { Write-Error "Morty venv missing. Run install\bootstrap-mcp.ps1."; exit 1 }
if ($Ocr) {
  & $py -c @"
import sys, subprocess, tempfile, os, pypdf
pdf=sys.argv[1]
out=tempfile.mktemp(suffix='.pdf')
subprocess.check_call(['ocrmypdf','--skip-text',pdf,out])
r=pypdf.PdfReader(out)
for i,p in enumerate(r.pages):
    print(f'\n\n## Page {i+1}\n')
    print(p.extract_text() or '')
os.unlink(out)
"@ $Path
} else {
  & $py -c @"
import sys, pypdf
r=pypdf.PdfReader(sys.argv[1])
for i,p in enumerate(r.pages):
    print(f'\n\n## Page {i+1}\n')
    print(p.extract_text() or '')
"@ $Path
}
