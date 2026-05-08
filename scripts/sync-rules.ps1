param(
  [string]$Ref = 'release'
)

$ErrorActionPreference = 'Stop'

$geoipBase = "https://raw.githubusercontent.com/runetfreedom/russia-blocked-geoip/$Ref/srs"
$geositeBase = "https://raw.githubusercontent.com/runetfreedom/russia-v2ray-rules-dat/$Ref/sing-box/rule-set-geosite"

# Route intent:
# Direct: ru-whitelist, ru, yandex
# Proxy: ru-blocked, ru-blocked-community + selected providers/social/video

$directGeoip = @('ru-whitelist','ru','yandex')
$proxyGeoip = @('ru-blocked','ru-blocked-community','cloudflare','cloudfront','ddos-guard','facebook','fastly','google','netflix','telegram','tor','twitter','re-filter','xk','youtube','tiktok','instagram','whatsapp')

# Geosite names that actually exist in sing-box geosite repo.
$directGeosite = @('yandex','category-ru')
$proxyGeosite = @('ru-blocked','cloudflare','facebook','fastly','google','netflix','telegram','tor','twitter','youtube','tiktok','instagram','whatsapp','meta')

$directGeoipDir = Join-Path $PSScriptRoot '..\\rules\\Direct\\geoip'
$directGeositeDir = Join-Path $PSScriptRoot '..\\rules\\Direct\\geosite'
$proxyGeoipDir = Join-Path $PSScriptRoot '..\\rules\\Proxy\\geoip'
$proxyGeositeDir = Join-Path $PSScriptRoot '..\\rules\\Proxy\\geosite'

function Download-IfExists([string]$url,[string]$outPath) {
  try {
    Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing
    return $true
  } catch {
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) { return $false }
    throw
  }
}

function Sync-Group([string[]]$names,[string]$prefix,[string]$base,[string]$target,[string]$kind) {
  Get-ChildItem $target -File -ErrorAction SilentlyContinue | Remove-Item -Force
  foreach($n in $names){
    $file = if ($prefix) { "$prefix$n.srs" } else { "$n.srs" }
    $url = "$base/$file"
    $out = Join-Path $target $file
    if(Download-IfExists -url $url -outPath $out){
      Write-Host "Synced $kind/$file"
    } else {
      Write-Warning "Missing $kind file upstream: $file"
    }
  }
}

Sync-Group -names $directGeoip -prefix '' -base $geoipBase -target $directGeoipDir -kind 'geoip'
Sync-Group -names $proxyGeoip -prefix '' -base $geoipBase -target $proxyGeoipDir -kind 'geoip'
Sync-Group -names $directGeosite -prefix 'geosite-' -base $geositeBase -target $directGeositeDir -kind 'geosite'
Sync-Group -names $proxyGeosite -prefix 'geosite-' -base $geositeBase -target $proxyGeositeDir -kind 'geosite'

$manifest = [ordered]@{
  source_ref = $Ref
  source_geoip = 'runetfreedom/russia-blocked-geoip/release/srs'
  source_geosite = 'runetfreedom/russia-v2ray-rules-dat/release/sing-box/rule-set-geosite'
  generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
  intent = [ordered]@{
    direct = 'ru-whitelist, ru, yandex + geosite category-ru/yandex'
    proxy = 'ru-blocked, ru-blocked-community + selected providers/social/video'
    fallback = 'direct'
  }
  direct = [ordered]@{
    geoip = (Get-ChildItem $directGeoipDir -File | Sort-Object Name | Select-Object -ExpandProperty Name)
    geosite = (Get-ChildItem $directGeositeDir -File | Sort-Object Name | Select-Object -ExpandProperty Name)
  }
  proxy = [ordered]@{
    geoip = (Get-ChildItem $proxyGeoipDir -File | Sort-Object Name | Select-Object -ExpandProperty Name)
    geosite = (Get-ChildItem $proxyGeositeDir -File | Sort-Object Name | Select-Object -ExpandProperty Name)
  }
}

$manifest | ConvertTo-Json -Depth 8 | Out-File (Join-Path $PSScriptRoot '..\\rules\\manifest.json') -Encoding utf8
Write-Host 'Manifest updated.'
