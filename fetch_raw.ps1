# Fetch raw JSON from the API with PowerShell only (no Python needed).
# API_KEY and API_BASE_URL are read from parameters, environment variables,
# or the .env file next to this script (in that order of precedence).
param(
  [string]$BaseUrl,
  [string]$ApiKey,
  [int]$Limit = 5,
  [int]$Offset = 0,
  [string]$OutFile = "raw.json"
)

$DefaultBaseUrl = "https://zlegl6sgdl.execute-api.eu-central-1.amazonaws.com/prod"

# Load .env (KEY=VALUE per line); Get-Content handles UTF-8 and UTF-16 files
$dotenv = @{}
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
  foreach ($line in Get-Content $envFile) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) { continue }
    $key, $value = $line.Split("=", 2)
    $dotenv[$key.Trim()] = $value.Trim().Trim('"').Trim("'")
  }
}

function Resolve-Setting([string]$Explicit, [string]$Name, [string]$Default) {
  if ($Explicit) { return $Explicit }
  $fromEnv = [Environment]::GetEnvironmentVariable($Name)
  if ($fromEnv) { return $fromEnv }
  if ($dotenv.ContainsKey($Name) -and $dotenv[$Name]) { return $dotenv[$Name] }
  return $Default
}

$BaseUrl = Resolve-Setting $BaseUrl "API_BASE_URL" $DefaultBaseUrl
$ApiKey  = Resolve-Setting $ApiKey  "API_KEY" ""

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  Write-Error "API key is missing. Add API_KEY=... to .env, set `$env:API_KEY, or pass -ApiKey."
  exit 1
}

$url = "$($BaseUrl.TrimEnd('/'))/v1/topics/export?limit=$Limit&offset=$Offset"

try {
  $response = Invoke-WebRequest -Uri $url -Headers @{ "x-api-key" = $ApiKey } -Method GET -UseBasicParsing -ErrorAction Stop
} catch {
  Write-Error "Request failed: $($_.Exception.Message) $($_.ErrorDetails.Message)"
  Write-Host "$OutFile was NOT modified."
  exit 1
}

$response.Content | Set-Content -Encoding utf8 $OutFile
Write-Host "Saved raw response to $OutFile"
