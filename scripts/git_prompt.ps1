param(
  [string]$DefaultMessage = "Update"
)

$status = git status --porcelain
if (-not $status) {
  Write-Host "No changes detected."
  exit 0
}

Write-Host "Changes detected:"
$status | ForEach-Object { Write-Host $_ }

$answer = Read-Host "Commit and push now? (y/N)"
if ($answer -match '^(y|yes)$') {
  git add -A
  $message = Read-Host "Commit message (default: $DefaultMessage)"
  if ([string]::IsNullOrWhiteSpace($message)) {
    $message = $DefaultMessage
  }
  git commit -m $message
  git push
} else {
  Write-Host "Skipped."
}
