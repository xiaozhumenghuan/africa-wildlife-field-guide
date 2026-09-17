param(
  [string]$Owner = "xiaozhumenghuan",
  [string]$Repo = "africa-wildlife-field-guide",
  [string]$Branch = "main",
  [string]$Message = "Publish wildlife field guide"
)

$ErrorActionPreference = "Stop"
$root = (git rev-parse --show-toplevel).Trim()
Push-Location $root

try {
  $credInput = "protocol=https`nhost=github.com`n`n"
  $credLines = $credInput | git credential fill
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read the GitHub credential from Git Credential Manager."
  }

  $token = ($credLines | Where-Object { $_ -like "password=*" } |
    Select-Object -First 1) -replace "^password=", ""
  if (-not $token) {
    throw "GitHub token was not returned by Git Credential Manager."
  }

  $headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent" = "Codex-Wildlife-Guide"
  }
  $apiRoot = "https://api.github.com/repos/$Owner/$Repo"

  $parentSha = $null
  try {
    $ref = Invoke-RestMethod -Uri "$apiRoot/git/ref/heads/$Branch" -Headers $headers
    $parentSha = $ref.object.sha
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -notin @(404, 409)) {
      throw
    }
  }

  if (-not $parentSha) {
    $readmePath = Join-Path $root "README.md"
    $readmeBody = @{
      message = "Initialize repository"
      content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($readmePath))
      branch = $Branch
    } | ConvertTo-Json -Compress
    $null = Invoke-RestMethod `
      -Uri "$apiRoot/contents/README.md" `
      -Headers $headers `
      -Method Put `
      -ContentType "application/json" `
      -Body $readmeBody
    $ref = Invoke-RestMethod -Uri "$apiRoot/git/ref/heads/$Branch" -Headers $headers
    $parentSha = $ref.object.sha
  }

  $treeItems = @()
  foreach ($relativePath in (git ls-files)) {
    $normalizedPath = $relativePath.Replace("\", "/")
    $bytes = [IO.File]::ReadAllBytes((Join-Path $root $relativePath))
    $blobBody = @{
      content = [Convert]::ToBase64String($bytes)
      encoding = "base64"
    } | ConvertTo-Json -Compress
    $blob = Invoke-RestMethod `
      -Uri "$apiRoot/git/blobs" `
      -Headers $headers `
      -Method Post `
      -ContentType "application/json" `
      -Body $blobBody
    $treeItems += @{
      path = $normalizedPath
      mode = "100644"
      type = "blob"
      sha = $blob.sha
    }
  }

  $treeBody = @{ tree = $treeItems } | ConvertTo-Json -Depth 8 -Compress
  $tree = Invoke-RestMethod `
    -Uri "$apiRoot/git/trees" `
    -Headers $headers `
    -Method Post `
    -ContentType "application/json" `
    -Body $treeBody

  $authorName = (git show -s --format=%an HEAD).Trim()
  $authorEmail = (git show -s --format=%ae HEAD).Trim()
  $authorDate = (git show -s --format=%aI HEAD).Trim()
  $committerName = (git show -s --format=%cn HEAD).Trim()
  $committerEmail = (git show -s --format=%ce HEAD).Trim()
  $committerDate = (git show -s --format=%cI HEAD).Trim()

  $commitPayload = @{
    message = $Message
    tree = $tree.sha
    parents = @()
    author = @{
      name = $authorName
      email = $authorEmail
      date = $authorDate
    }
    committer = @{
      name = $committerName
      email = $committerEmail
      date = $committerDate
    }
  }
  if ($parentSha) {
    $commitPayload.parents = @($parentSha)
  }
  $commit = Invoke-RestMethod `
    -Uri "$apiRoot/git/commits" `
    -Headers $headers `
    -Method Post `
    -ContentType "application/json" `
    -Body ($commitPayload | ConvertTo-Json -Depth 5 -Compress)

  if ($parentSha) {
    $refBody = @{ sha = $commit.sha; force = $false } |
      ConvertTo-Json -Compress
    $null = Invoke-RestMethod `
      -Uri "$apiRoot/git/refs/heads/$Branch" `
      -Headers $headers `
      -Method Patch `
      -ContentType "application/json" `
      -Body $refBody
  } else {
    $refBody = @{
      ref = "refs/heads/$Branch"
      sha = $commit.sha
    } | ConvertTo-Json -Compress
    $null = Invoke-RestMethod `
      -Uri "$apiRoot/git/refs" `
      -Headers $headers `
      -Method Post `
      -ContentType "application/json" `
      -Body $refBody
  }

  Write-Output "Published $($commit.sha)"
  Write-Output "https://github.com/$Owner/$Repo/commit/$($commit.sha)"
  $localSha = (git rev-parse HEAD).Trim()
  Write-Output "Local HEAD $localSha"
} finally {
  Pop-Location
}
