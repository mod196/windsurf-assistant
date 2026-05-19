# ═══════════════════════════════════════════════════════════════════════════
# build_vsix.ps1 · dao-proxy-min vsix 打包脚 · 道法自然 · 反者道之动
# ═══════════════════════════════════════════════════════════════════════════
# 「上善若水」 — 利万物而不争 · 取本地最新源 · 出干净 vsix
#
# 用法:
#   .\build_vsix.ps1                 # 自取 package.json 之 version
#   .\build_vsix.ps1 -Version 9.9.13 # 显指版
#
# 流:
#   1. 读 package.json 之 version
#   2. 立临 staging 目录
#   3. 拷源件 (extension.js, package.json, readme.md, LICENSE.txt, INDEX.md,
#      FINAL_TRUTH_*, media/, vendor/) → staging/extension/
#   4. 立 extension.vsixmanifest (基于 package.json 之 metadata)
#   5. 立 [Content_Types].xml
#   6. 用 .NET ZipFile zip → dao-proxy-min-{version}.vsix
#   7. 验大小 + 内件全
# ═══════════════════════════════════════════════════════════════════════════

[CmdletBinding()]
param(
    [string]$Version = ''
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "═══ 打包 dao-proxy-min vsix · 道法自然 ═══`n" -ForegroundColor Cyan

# 1. 读 package.json
$pkgPath = Join-Path $scriptDir 'package.json'
if (-not (Test-Path $pkgPath)) {
    Write-Host "  ✗ package.json 不存: $pkgPath" -ForegroundColor Red
    exit 1
}
$pkgObj = Get-Content $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $Version) { $Version = $pkgObj.version }
$publisher = $pkgObj.publisher
$name = $pkgObj.name
$displayName = $pkgObj.displayName
$description = $pkgObj.description
if (-not $description) { $description = $displayName }

Write-Host "【源】" -ForegroundColor Yellow
Write-Host "  publisher : $publisher"
Write-Host "  name      : $name"
Write-Host "  version   : $Version"
Write-Host "  displayName: $displayName"
Write-Host ""

# 2. 立临 staging
$staging = Join-Path $env:TEMP "dao-proxy-min-build-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$stagingExt = Join-Path $staging 'extension'
New-Item -ItemType Directory -Path $stagingExt -Force | Out-Null
Write-Host "【staging】 $staging" -ForegroundColor Yellow
Write-Host ""

# 3. 拷源件
Write-Host "【拷源件】" -ForegroundColor Yellow
$srcFiles = @(
    @{ src = 'extension.js'; req = $true }
    # 印 161 · 损 _cleanup_spawn.js (v9.9.28 detached cleanup spawn 之繁本 · 解决不存在的问题)
    @{ src = 'package.json'; req = $true }
    @{ src = 'readme.md'; req = $true }
    @{ src = 'LICENSE.txt'; req = $false }
    @{ src = 'INDEX.md'; req = $false }
    @{ src = 'FINAL_TRUTH_2026-05-08.md'; req = $false }
)
foreach ($f in $srcFiles) {
    $srcPath = Join-Path $scriptDir $f.src
    if (Test-Path $srcPath) {
        Copy-Item -LiteralPath $srcPath -Destination $stagingExt -Force
        Write-Host "  ✓ $($f.src) ($((Get-Item $srcPath).Length) B)"
    } elseif ($f.req) {
        Write-Host "  ✗ 必需件缺: $($f.src)" -ForegroundColor Red
        Remove-Item $staging -Recurse -Force -EA 0
        exit 1
    }
}

# 应 .vscodeignore 之核心规则: 排 _* (除白) + *.bak + *.v9.9.2-MN-bak 等
$ignorePatterns = @('*.bak', '*.bak_*', '*.v9.9.2-MN-bak', '*.log', '*.dump.*', '*.map')
$ignoreFullPaths = @('media/webview-app.js', 'vendor/bundled-origin/_sp_candidates.json', 'vendor/bundled-origin/_custom_sp.json', 'vendor/bundled-origin/_lastinject.json', 'vendor/bundled-origin/_origin_mode.txt', 'vendor/bundled-origin/_dao_81.txt', 'vendor/bundled-origin/_silk_raw.txt', 'vendor/bundled-origin/_silk_text.txt')
# v9.9.20 两经归一 · 白名单损至两经 (帛书《老子》德经+道经 + 道藏《阴符经》)
# 道义: 二十八章「朴散为器·圣人用则为官长·夫大制无割」· 损 4 外典 (yinfu 之外的 heraclitus/liber_al/dao_yuan_jing)
$whiteList = @('vendor/bundled-origin/_silk_de.txt', 'vendor/bundled-origin/_silk_dao.txt', 'vendor/bundled-origin/_yinfu.txt')

function Test-ShouldIgnore {
    param([string]$RelPath, [string]$FileName)
    $relNorm = $RelPath -replace '\\', '/'
    foreach ($w in $whiteList) { if ($relNorm -eq $w) { return $false } }
    foreach ($p in $ignoreFullPaths) { if ($relNorm -eq $p) { return $true } }
    foreach ($p in $ignorePatterns) { if ($FileName -like $p) { return $true } }
    if ($FileName.StartsWith('_')) { return $true }
    return $false
}

$srcDirs = @('media', 'vendor')
foreach ($d in $srcDirs) {
    $srcDir = Join-Path $scriptDir $d
    if (-not (Test-Path $srcDir)) { continue }
    $inc = 0; $exc = 0
    foreach ($file in (Get-ChildItem $srcDir -Recurse -File)) {
        $rel = $file.FullName.Substring($scriptDir.Length + 1)
        if (Test-ShouldIgnore -RelPath $rel -FileName $file.Name) {
            $exc++
            continue
        }
        $tgt = Join-Path $stagingExt $rel
        $tgtDir = Split-Path -Parent $tgt
        if (-not (Test-Path $tgtDir)) { New-Item -ItemType Directory -Path $tgtDir -Force | Out-Null }
        Copy-Item -LiteralPath $file.FullName -Destination $tgt -Force
        $inc++
    }
    Write-Host "  ✓ $d/ ($inc 件入 · $exc 排)"
}
Write-Host ""

# 4. 立 extension.vsixmanifest
$desc = $description -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
$manifestXml = @"
<?xml version="1.0" encoding="utf-8"?>
	<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
		<Metadata>
			<Identity Language="en-US" Id="$name" Version="$Version" Publisher="$publisher" />
			<DisplayName>$displayName</DisplayName>
			<Description xml:space="preserve">$desc</Description>
			<Tags>dao,agent,proxy,sp,inject,override,plus,vsix</Tags>
			<Categories>Other</Categories>
			<GalleryFlags>Public</GalleryFlags>
			<Properties>
				<Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.74.0" />
				<Property Id="Microsoft.VisualStudio.Services.Links.Source" Value="" />
				<Property Id="Microsoft.VisualStudio.Code.ExtensionDependencies" Value="" />
				<Property Id="Microsoft.VisualStudio.Code.ExtensionPack" Value="" />
				<Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="ui,workspace" />
			</Properties>
		</Metadata>
		<Installation>
			<InstallationTarget Id="Microsoft.VisualStudio.Code"/>
		</Installation>
		<Dependencies/>
		<Assets>
			<Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
		</Assets>
	</PackageManifest>
"@
$manifestPath = Join-Path $staging 'extension.vsixmanifest'
[System.IO.File]::WriteAllText($manifestPath, $manifestXml, [System.Text.UTF8Encoding]::new($false))
Write-Host "  ✓ extension.vsixmanifest ($($manifestXml.Length) B)"

# 5. 立 [Content_Types].xml
$ctXml = @"
<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="vsixmanifest" ContentType="text/xml"/><Default Extension="json" ContentType="application/json"/><Default Extension="js" ContentType="application/javascript"/><Default Extension="md" ContentType="text/markdown"/><Default Extension="txt" ContentType="text/plain"/><Default Extension="png" ContentType="image/png"/><Default Extension="svg" ContentType="image/svg+xml"/><Default Extension="xml" ContentType="text/xml"/></Types>
"@
$ctPath = Join-Path $staging '[Content_Types].xml'
[System.IO.File]::WriteAllText($ctPath, $ctXml, [System.Text.UTF8Encoding]::new($false))
Write-Host "  ✓ [Content_Types].xml ($($ctXml.Length) B)"
Write-Host ""

# 6. 用 .NET ZipFile zip
$vsixOut = Join-Path $scriptDir "dao-proxy-min-$Version.vsix"
if (Test-Path $vsixOut) {
    $bakOut = "$vsixOut.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Move-Item -LiteralPath $vsixOut -Destination $bakOut -Force
    Write-Host "【备旧】 $vsixOut → $bakOut" -ForegroundColor Gray
}

Add-Type -AssemblyName System.IO.Compression.FileSystem -EA 0
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $vsixOut, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$vsixSize = (Get-Item $vsixOut).Length
Write-Host "【出】" -ForegroundColor Green
Write-Host "  vsix : $vsixOut"
Write-Host "  大小  : $vsixSize B ($([math]::Round($vsixSize/1KB,1)) KB)"
Write-Host ""

# 7. 验内件全
Write-Host "【验内件】" -ForegroundColor Yellow
$z = [System.IO.Compression.ZipFile]::OpenRead($vsixOut)
$entries = $z.Entries | Sort-Object FullName
$entryCount = @($entries).Count
Write-Host "  内件数: $entryCount"
foreach ($e in $entries) {
    Write-Host "    · $($e.FullName) ($($e.Length) B)"
}
$z.Dispose()
Write-Host ""

# 8. 清 staging
Remove-Item $staging -Recurse -Force -EA 0

Write-Host "═══ 打包毕 · dao-proxy-min-$Version.vsix · 道法自然 ═══" -ForegroundColor Green
Write-Host ""
Write-Host "「上善若水. 水善利万物而不争」 — 道经第八章" -ForegroundColor Cyan
exit 0
