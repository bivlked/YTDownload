#Requires -Version 7.0

<#
ytdlp.ps1 — безопасный помощник для yt-dlp + ffmpeg в текущей папке (PowerShell 7+)

Ожидает рядом (в текущем каталоге):
  - yt-dlp.exe
  - ffmpeg.exe
  - ffprobe.exe
  - cookies-youtube.txt  (Netscape cookie file для YouTube)

Режимы:
  .\ytdlp.ps1 -Setup [-Force]
  .\ytdlp.ps1 "URL"
  .\ytdlp.ps1 -Mp4 "URL"
  .\ytdlp.ps1 -Video "URL"
  .\ytdlp.ps1 -Audio "URL"
#>

[CmdletBinding(DefaultParameterSetName = 'Help')]
param(
    # Setup mode: download stable binaries into current directory
    [Parameter(ParameterSetName = 'Setup', Mandatory = $true)]
    [switch] $Setup,

    # Download modes
    [Parameter(ParameterSetName = 'Full', Position = 0, Mandatory = $true)]
    [Parameter(ParameterSetName = 'Video', Position = 0, Mandatory = $true)]
    [Parameter(ParameterSetName = 'Audio', Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Url,

    [Parameter(ParameterSetName = 'Video', Mandatory = $true)]
    [switch] $Video,

    [Parameter(ParameterSetName = 'Audio', Mandatory = $true)]
    [switch] $Audio,

    # Output MP4 instead of MKV (limits to H.264+AAC, max 1080p)
    [Parameter(ParameterSetName = 'Full')]
    [switch] $Mp4,

    # Overwrite existing binaries in -Setup
    [Parameter(ParameterSetName = 'Setup')]
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----------------------------
# Console UI helpers
# ----------------------------
function Write-Rule([string]$Title) {
    $line = ('─' * 78)
    Write-Host $line -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkGray
}

function Write-Info([string]$Msg) { Write-Host ("ℹ️  {0}" -f $Msg) -ForegroundColor Gray }
function Write-Ok([string]$Msg)   { Write-Host ("✅ {0}" -f $Msg) -ForegroundColor Green }
function Write-Warn([string]$Msg) { Write-Host ("⚠️  {0}" -f $Msg) -ForegroundColor Yellow }
function Write-Err([string]$Msg)  { Write-Host ("❌ {0}" -f $Msg) -ForegroundColor Red }

function Write-Link([string]$Label, [string]$Url) {
    Write-Host ("    {0}: {1}" -f $Label, $Url) -ForegroundColor DarkCyan
}

# ----------------------------
# Constants / links (stable)
# ----------------------------
$Links = [ordered]@{
    'yt-dlp (stable exe)' = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
    'FFmpeg (release essentials zip)' = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
    'Cookie exporter (Chrome/Edge extension)' = 'https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc'
}

# ----------------------------
# Paths: operate in CURRENT directory
# ----------------------------
$WorkDir = (Get-Location).Path
$YtDlp   = Join-Path $WorkDir 'yt-dlp.exe'
$Ffmpeg  = Join-Path $WorkDir 'ffmpeg.exe'
$Ffprobe = Join-Path $WorkDir 'ffprobe.exe'
$Cookies = Join-Path $WorkDir 'cookies-youtube.txt'

# ----------------------------
# URL Validation
# ----------------------------
function Test-YouTubeUrl {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    # Combined YouTube URL pattern (youtube.com, youtu.be, m.youtube.com, etc.)
    # Matches: /watch?v=, /shorts/, /live/, /embed/, youtu.be/
    $pattern = '^https?://(?:(?:www\.|m\.)?youtube\.com/(?:watch\?v=|shorts/|live/|embed/)|youtu\.be/)[\w-]+'

    return $Url -match $pattern
}

# ----------------------------
# Requirements checks
# ----------------------------
function Get-RequirementsStatus {
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()

    [ordered]@{
        'yt-dlp.exe'          = (Test-Path -LiteralPath $YtDlp)
        'ffmpeg.exe'          = (Test-Path -LiteralPath $Ffmpeg)
        'ffprobe.exe'         = (Test-Path -LiteralPath $Ffprobe)
        'cookies-youtube.txt' = (Test-Path -LiteralPath $Cookies)
    }
}

function Show-AboutAndLinks {
    Write-Rule "📥 ytdlp.ps1 — загрузка YouTube в максимальном качестве (без перекодирования)"
    Write-Info "Текущая папка: $WorkDir"
    Write-Info "yt-dlp загружает потоки, ffmpeg объединяет (mux) видео+аудио без re-encode."
    Write-Info "Для YouTube часто требуются cookies (иначе будет проверка 'not a bot')."
    Write-Host ""

    Write-Rule "📦 Ожидаемые файлы рядом (ровно 4)"
    Write-Host "  1️⃣  yt-dlp.exe          " -ForegroundColor White -NoNewline; Write-Host "— загрузка видео/аудио потоков" -ForegroundColor Gray
    Write-Host "  2️⃣  ffmpeg.exe          " -ForegroundColor White -NoNewline; Write-Host "— склейка (mux) видео+аудио, контейнерные операции" -ForegroundColor Gray
    Write-Host "  3️⃣  ffprobe.exe         " -ForegroundColor White -NoNewline; Write-Host "— анализ медиапотоков" -ForegroundColor Gray
    Write-Host "  4️⃣  cookies-youtube.txt " -ForegroundColor White -NoNewline; Write-Host "— авторизация/антибот для YouTube (Netscape cookie file)" -ForegroundColor Gray
    Write-Host ""

    Write-Rule "🔗 Ссылки на скачивание (stable)"
    Write-Link "yt-dlp.exe"         $Links['yt-dlp (stable exe)']
    Write-Link "FFmpeg zip"         $Links['FFmpeg (release essentials zip)']
    Write-Link "Плагин cookies.txt" $Links['Cookie exporter (Chrome/Edge extension)']
    Write-Host ""
}

function Show-Usage {
    Write-Rule "🚀 Как пользоваться"

    Write-Host ""
    Write-Host "  📦 " -NoNewline -ForegroundColor Cyan
    Write-Host "Установка компонентов:" -ForegroundColor White
    Write-Host "     .\ytdlp.ps1 -Setup" -ForegroundColor Yellow
    Write-Host "        Скачает в текущую папку: yt-dlp.exe, ffmpeg.exe, ffprobe.exe (stable), без мусора." -ForegroundColor Gray
    Write-Host "        Затем попросит добавить cookies-youtube.txt (через плагин)." -ForegroundColor Gray
    Write-Host ""

    Write-Host "  📥 " -NoNewline -ForegroundColor Cyan
    Write-Host "Скачать видео + аудио (полный файл):" -ForegroundColor White
    Write-Host "     .\ytdlp.ps1 ""https://youtube.com/watch?v=...""" -ForegroundColor Yellow
    Write-Host "        Скачает максимально возможное видео+аудио и объединит в downloaded.mkv без перекодирования." -ForegroundColor Gray
    Write-Host "        Имя файла: downloaded.mkv, downloaded000.mkv, downloaded001.mkv, ..." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  🎬 " -NoNewline -ForegroundColor Cyan
    Write-Host "Скачать только видео (без звука):" -ForegroundColor White
    Write-Host "     .\ytdlp.ps1 -Video ""https://youtube.com/watch?v=...""" -ForegroundColor Yellow
    Write-Host "        Скачает максимально возможное видео (без аудио) в video.EXT (расширение автоматически)." -ForegroundColor Gray
    Write-Host "        Имя файла: video.webm, video001.mp4, video002.webm, ..." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  🎵 " -NoNewline -ForegroundColor Cyan
    Write-Host "Скачать только аудио (без видео):" -ForegroundColor White
    Write-Host "     .\ytdlp.ps1 -Audio ""https://youtube.com/watch?v=...""" -ForegroundColor Yellow
    Write-Host "        Скачает максимально возможное аудио (без видео). Приоритет: формат 251 (Opus), fallback на best." -ForegroundColor Gray
    Write-Host "        Имя файла: audio.webm, audio001.opus, audio002.m4a, ..." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  📼 " -NoNewline -ForegroundColor Cyan
    Write-Host "Скачать в формате MP4 (совместимость):" -ForegroundColor White
    Write-Host "     .\ytdlp.ps1 -Mp4 ""https://youtube.com/watch?v=...""" -ForegroundColor Yellow
    Write-Host "        Скачает H.264 видео + AAC аудио в downloaded.mp4 (макс. 1080p)." -ForegroundColor Gray
    Write-Host "        Для ТВ, телефонов и устройств, не поддерживающих MKV/VP9/Opus." -ForegroundColor DarkGray
    Write-Host ""
}

# ----------------------------
# Unique naming
# ----------------------------
function Get-NextNameFixedExt {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Base,

        [Parameter(Mandatory)]
        [string]$Ext,

        [Parameter(Mandatory)]
        [ValidateSet('Full', 'Video', 'Audio')]
        [string]$Kind
    )

    $maxIterations = 10000
    $ext = $Ext.TrimStart('.')

    if ($Kind -eq 'Full') {
        # downloaded.mkv, then downloaded000.mkv, downloaded001.mkv ...
        $first = Join-Path $WorkDir ("{0}.{1}" -f $Base, $ext)
        if (-not (Test-Path -LiteralPath $first)) { return $first }

        for ($i = 0; $i -lt $maxIterations; $i++) {
            $cand = Join-Path $WorkDir ("{0}{1}.{2}" -f $Base, $i.ToString('000'), $ext)
            if (-not (Test-Path -LiteralPath $cand)) { return $cand }
        }
        throw "Не удалось найти свободное имя файла после $maxIterations попыток"
    } else {
        # video.%(ext)s or video001.%(ext)s ...
        $anyFirst = @(Get-ChildItem -LiteralPath $WorkDir -File -Filter ($Base + '.*') -ErrorAction SilentlyContinue)
        if ($anyFirst.Count -eq 0) {
            return Join-Path $WorkDir ("{0}.%(ext)s" -f $Base)
        }

        for ($i = 1; $i -lt $maxIterations; $i++) {
            $prefix = "{0}{1}" -f $Base, $i.ToString('000')
            $any = @(Get-ChildItem -LiteralPath $WorkDir -File -Filter ($prefix + '.*') -ErrorAction SilentlyContinue)
            if ($any.Count -eq 0) {
                return Join-Path $WorkDir ("{0}.%(ext)s" -f $prefix)
            }
        }
        throw "Не удалось найти свободное имя файла после $maxIterations попыток"
    }
}

# ----------------------------
# Setup helpers
# ----------------------------
function Download-File {
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile
    )

    Write-Info "Скачиваю: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    }
    catch {
        $errorMsg = $_.Exception.Message
        throw "Ошибка скачивания $Url : $errorMsg"
    }

    $len = (Get-Item -LiteralPath $OutFile).Length
    if ($len -lt 1024) {
        throw "Скачанный файл слишком мал ($len bytes). Похоже, скачалось не то (например, HTML/ошибка)."
    }
    Write-Ok ("Готово: {0} ({1:N0} bytes)" -f (Split-Path -Leaf $OutFile), $len)
}

function Test-YtDlpVersion {
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$YtDlpPath
    )

    if (-not (Test-Path -LiteralPath $YtDlpPath)) {
        return
    }

    try {
        Write-Info "Проверка версии yt-dlp..."
        $localVersion = & $YtDlpPath --version 2>$null
        if (-not $localVersion) {
            Write-Warn "Не удалось определить локальную версию yt-dlp."
            return
        }

        Write-Info "Локальная версия yt-dlp: $localVersion"

        # Получаем последнюю версию с GitHub API (быстрее чем весь HTML)
        try {
            $response = Invoke-RestMethod -Uri 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest' -TimeoutSec 5
            $latestVersion = $response.tag_name

            if ($latestVersion) {
                Write-Info "Последняя версия на GitHub: $latestVersion"

                if ($localVersion -eq $latestVersion) {
                    Write-Ok "Версия yt-dlp актуальна!"
                } else {
                    Write-Warn "Доступна новая версия: $latestVersion (у вас: $localVersion)"
                    Write-Info "Для обновления запустите: .\ytdlp.ps1 -Setup -Force"
                }
            }
        } catch {
            Write-Warn "Не удалось проверить последнюю версию на GitHub (возможно, проблемы с сетью)."
        }
    } catch {
        Write-Warn "Ошибка при проверке версии: $($_.Exception.Message)"
    }
}

function Ensure-Setup {
    param([switch]$ForceOverwrite)

    Write-Rule "Режим -Setup: установка stable компонентов в текущую папку"
    Write-Info "Папка установки: $WorkDir"
    Write-Host ""

    $existing = @()
    if (Test-Path -LiteralPath $YtDlp)   { $existing += 'yt-dlp.exe' }
    if (Test-Path -LiteralPath $Ffmpeg)  { $existing += 'ffmpeg.exe' }
    if (Test-Path -LiteralPath $Ffprobe) { $existing += 'ffprobe.exe' }

    if ($existing.Count -gt 0 -and -not $ForceOverwrite) {
        Write-Warn "Уже существуют файлы: $($existing -join ', ')"
        Write-Warn "По умолчанию я НЕ перезаписываю их (безопасный режим)."
        Write-Info "Для принудительной перезаписи/обновления: .\ytdlp.ps1 -Setup -Force"
        Write-Host ""
    }

    $tmp = Join-Path $WorkDir "_tmp_ytdlp_setup"
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path $tmp | Out-Null

    try {
        # yt-dlp.exe
        if (-not (Test-Path -LiteralPath $YtDlp) -or $ForceOverwrite) {
            $tmpYt = Join-Path $tmp "yt-dlp.exe"
            Download-File -Url $Links['yt-dlp (stable exe)'] -OutFile $tmpYt
            Move-Item -LiteralPath $tmpYt -Destination $YtDlp -Force
            Write-Ok "Установлен yt-dlp.exe"
        } else {
            Write-Ok "yt-dlp.exe уже есть — пропускаю"
        }

        # ffmpeg/ffprobe
        $needFfmpeg  = (-not (Test-Path -LiteralPath $Ffmpeg))  -or $ForceOverwrite
        $needFfprobe = (-not (Test-Path -LiteralPath $Ffprobe)) -or $ForceOverwrite

        if ($needFfmpeg -or $needFfprobe) {
            $zip = Join-Path $tmp "ffmpeg-release-essentials.zip"
            Download-File -Url $Links['FFmpeg (release essentials zip)'] -OutFile $zip

            $unpack = Join-Path $tmp "ffmpeg_unpack"
            New-Item -ItemType Directory -Path $unpack | Out-Null
            Expand-Archive -LiteralPath $zip -DestinationPath $unpack -Force

            $foundFfmpeg  = Get-ChildItem -LiteralPath $unpack -Recurse -File -Filter "ffmpeg.exe"  | Select-Object -First 1
            $foundFfprobe = Get-ChildItem -LiteralPath $unpack -Recurse -File -Filter "ffprobe.exe" | Select-Object -First 1

            if (-not $foundFfmpeg -or -not $foundFfprobe) {
                throw "Не удалось найти ffmpeg.exe/ffprobe.exe внутри архива. Проверьте источник или структуру архива."
            }

            if ($needFfmpeg) {
                Copy-Item -LiteralPath $foundFfmpeg.FullName -Destination $Ffmpeg -Force
                Write-Ok "Установлен ffmpeg.exe"
            } else {
                Write-Ok "ffmpeg.exe уже есть — пропускаю"
            }

            if ($needFfprobe) {
                Copy-Item -LiteralPath $foundFfprobe.FullName -Destination $Ffprobe -Force
                Write-Ok "Установлен ffprobe.exe"
            } else {
                Write-Ok "ffprobe.exe уже есть — пропускаю"
            }
        } else {
            Write-Ok "ffmpeg.exe и ffprobe.exe уже есть — пропускаю"
        }

        Write-Host ""
        Write-Rule "🔍 Проверка версий"
        if (Test-Path -LiteralPath $YtDlp)   { & $YtDlp --version | ForEach-Object { Write-Info ("yt-dlp: " + $_) } }
        if (Test-Path -LiteralPath $Ffmpeg)  { & $Ffmpeg -version | Select-Object -First 1 | ForEach-Object { Write-Info ("ffmpeg: " + $_) } }
        if (Test-Path -LiteralPath $Ffprobe) { & $Ffprobe -version | Select-Object -First 1 | ForEach-Object { Write-Info ("ffprobe: " + $_) } }

        Write-Host ""
        # Проверка актуальности yt-dlp
        if (Test-Path -LiteralPath $YtDlp) {
            Test-YtDlpVersion -YtDlpPath $YtDlp
        }

        Write-Host ""
        Write-Rule "Следующий шаг: добавьте cookies-youtube.txt"
        Write-Warn "Для YouTube часто требуется cookies-файл, иначе будет проверка 'not a bot'."
        Write-Info "Положите в эту папку файл Netscape cookies с именем:"
        Write-Host "    cookies-youtube.txt" -ForegroundColor White
        Write-Info "Плагин для экспорта cookies.txt:"
        Write-Link "Get cookies.txt LOCALLY" $Links['Cookie exporter (Chrome/Edge extension)']
        Write-Host ""
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# ----------------------------
# Cookie health checks
# ----------------------------
function Get-CookieLines {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Get-Content -LiteralPath $Path -ErrorAction Stop |
        Where-Object { $_ -and ($_ -notmatch '^\s*#') }
}

function ConvertFrom-NetscapeCookieLine {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Line
    )

    # Netscape format: domain \t flag \t path \t secure \t expiry \t name \t value
    $parts = $Line -split "`t", 7
    if ($parts.Count -lt 7) { return $null }

    [pscustomobject]@{
        Domain = $parts[0]
        Flag   = $parts[1]
        Path   = $parts[2]
        Secure = $parts[3]
        Expiry = $parts[4]
        Name   = $parts[5]
        Value  = $parts[6]
    }
}

function Test-CookiesFileLocalHealth {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $result = [ordered]@{
        Exists = $false
        HasHeader = $false
        HasAnyCookieLines = $false
        HasKeyCookies = $false
        KeyCookiesExpired = $false
        Notes = @()
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        $result.Notes += "Файл cookies-youtube.txt не найден."
        return [pscustomobject]$result
    }
    $result.Exists = $true

    $head = @(Get-Content -LiteralPath $Path -TotalCount 3 -ErrorAction SilentlyContinue)
    if ($head.Count -gt 0 -and ($head[0] -match 'Netscape')) {
        $result.HasHeader = $true
    } else {
        $result.Notes += "Заголовок не похож на Netscape cookies.txt."
    }

    $lines = @(Get-CookieLines -Path $Path)
    if ($lines.Count -gt 0) { 
        $result.HasAnyCookieLines = $true 
    } else {
        $result.Notes += "В cookie-файле нет ни одной строки cookies (кроме комментариев)."
        return [pscustomobject]$result
    }

    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    $keyNames = @(
        'SID','HSID','SSID','APISID','SAPISID','SIDCC','LOGIN_INFO',
        '__Secure-1PSID','__Secure-3PSID','__Secure-1PSIDCC','__Secure-3PSIDCC',
        '__Secure-1PSIDTS','__Secure-3PSIDTS','__Secure-YEC','__Secure-ROLLOUT_TOKEN'
    )

    $parsed = @()
    foreach ($l in $lines) {
        $p = ConvertFrom-NetscapeCookieLine -Line $l
        if ($null -ne $p) { $parsed += $p }
    }

    # Force arrays so .Count always exists
    $key = @($parsed | Where-Object { $keyNames -contains $_.Name })

    if ($key.Count -gt 0) {
        $result.HasKeyCookies = $true

        # Expiry can be "0" for session cookies in some exports; treat 0 as "unknown/session"
        $expirable = @($key | Where-Object { $_.Expiry -match '^\d+$' -and [int64]$_.Expiry -gt 0 })

        if ($expirable.Count -gt 0) {
            $expired = @($expirable | Where-Object { [int64]$_.Expiry -lt $now })
            if ($expired.Count -eq $expirable.Count) {
                $result.KeyCookiesExpired = $true
                $result.Notes += "Похоже, все ключевые cookies уже истекли по expiry (UTC epoch)."
            }
        }
    } else {
        $result.Notes += "Не найдены ожидаемые ключевые cookies (SID/SAPISID/HSID/SSID/...); возможно, экспорт сделан не с youtube.com или не из залогиненной сессии."
    }

    return [pscustomobject]$result
}

function Show-CookieHealthSummary {
    param([Parameter(Mandatory=$true)][pscustomobject]$Health)

    Write-Rule "Проверка cookies-youtube.txt (быстрая локальная)"
    if (-not $Health.Exists) {
        Write-Warn "cookies-youtube.txt отсутствует."
        return
    }

    if ($Health.HasHeader)        { Write-Ok   "Формат: заголовок похож на Netscape cookies.txt" } else { Write-Warn "Формат: заголовок НЕ похож на Netscape cookies.txt" }
    if ($Health.HasAnyCookieLines){ Write-Ok   "Содержимое: cookie-строки присутствуют" } else { Write-Warn "Содержимое: cookie-строк нет" }
    if ($Health.HasKeyCookies)    { Write-Ok   "Ключевые cookies: обнаружены" } else { Write-Warn "Ключевые cookies: не обнаружены" }
    if ($Health.KeyCookiesExpired){ Write-Warn "Срок действия: ключевые cookies выглядят истекшими" } else { Write-Ok "Срок действия: явных истекших ключевых cookies не обнаружено (или cookies session/без expiry)" }

    foreach ($n in @($Health.Notes)) { if ($n) { Write-Warn $n } }
    Write-Host ""
}

function Show-CookieFixGuidance {
    Write-Rule "Cookies выглядят нерабочими — что делать"
    Write-Warn "YouTube отклоняет авторизацию: cookies могли быть ротированы/инвалидированы."
    Write-Info "Рекомендуемый надёжный способ:"
    Write-Info "  1) Откройте InPrivate/Incognito окно браузера."
    Write-Info "  2) Войдите в YouTube."
    Write-Info "  3) В ЭТОЙ ЖЕ вкладке откройте: https://www.youtube.com/robots.txt"
    Write-Info "  4) Экспортируйте cookies для youtube.com в Netscape cookies.txt и сохраните как cookies-youtube.txt"
    Write-Info "  5) Закройте InPrivate окно и не используйте эту сессию дальше."
    Write-Host ""
    Write-Link "Плагин cookies.txt" $Links['Cookie exporter (Chrome/Edge extension)']
    Write-Host ""
}

function Test-CookiesOnlineForUrl {
    param(
        [Parameter(Mandatory=$true)][string]$UrlToTest
    )

    Write-Rule "Проверка cookies на работоспособность (онлайн, без скачивания)"
    Write-Info "URL для проверки: $UrlToTest"
    Write-Info "Проверка выполняется без загрузки медиа (skip-download)."
    Write-Host ""

    $probeArgs = @(
        '--ffmpeg-location', $WorkDir,
        '--cookies', $Cookies,
        '--no-playlist',
        '--skip-download',
        '--print', '%(id)s',
        $UrlToTest
    )

    $output = $null
    $exit = 0
    try {
        $output = (& $YtDlp @probeArgs 2>&1 | Out-String)
        $exit = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $exit = 1
    }

    $badPatterns = @(
        'cookies are no longer valid',
        'rotated',
        'LOGIN_REQUIRED',
        'Sign in to confirm you',
        'not a bot',
        'Use --cookies-from-browser or --cookies',
        'account cookies.*no longer valid'
    )

    $isBad = $false
    foreach ($p in $badPatterns) {
        if ($output -match $p) { $isBad = $true; break }
    }

    if ($exit -ne 0 -or $isBad) {
        Write-Err "Проверка cookies НЕ пройдена."
        if ($output) {
            $lines = @(($output -split "`r?`n") | Where-Object { $_ } | Select-Object -First 20)
            Write-Warn "Фрагмент вывода yt-dlp (первые строки):"
            foreach ($l in $lines) { Write-Host ("    " + $l) -ForegroundColor DarkYellow }
            Write-Host ""
        }
        Show-CookieFixGuidance
        return $false
    }

    Write-Ok "Проверка cookies пройдена — можно скачивать."
    Write-Host ""
    return $true
}

# ----------------------------
# Main
# ----------------------------
Show-AboutAndLinks

$status = Get-RequirementsStatus
$missing = @($status.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })

if ($Setup) {
    Ensure-Setup -ForceOverwrite:$Force
    exit 0
}

if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Write-Rule "Статус компонентов в текущей папке"
    foreach ($k in $status.Keys) {
        if ($status[$k]) { Write-Ok "$k — найден" } else { Write-Warn "$k — отсутствует" }
    }
    Write-Host ""

    if (Test-Path -LiteralPath $Cookies) {
        $health = Test-CookiesFileLocalHealth -Path $Cookies
        Show-CookieHealthSummary -Health $health
        Write-Info "Важно: даже корректный cookie-файл может быть ротирован YouTube. Реальная онлайн-проверка выполняется при скачивании по URL."
        Write-Host ""
    }

    if ($missing.Count -gt 0) {
        Write-Warn "Не хватает компонентов: $($missing -join ', ')"
        Write-Info "Положите нужные файлы в текущую папку или запустите: .\ytdlp.ps1 -Setup"
        Write-Host ""
    } else {
        Write-Ok "Все необходимые файлы присутствуют. Можно скачивать."
        Write-Host ""
    }

    Show-Usage
    exit 0
}

if (-not (Test-Path -LiteralPath $YtDlp) -or -not (Test-Path -LiteralPath $Ffmpeg) -or -not (Test-Path -LiteralPath $Ffprobe)) {
    Write-Err "Не найдены yt-dlp.exe / ffmpeg.exe / ffprobe.exe в текущей папке."
    Write-Info "Запустите: .\ytdlp.ps1 -Setup  (или положите файлы вручную)"
    exit 2
}

if (-not (Test-Path -LiteralPath $Cookies)) {
    Write-Err "Не найден cookies-youtube.txt — для YouTube это часто обязательно."
    Write-Info "Положите cookies-youtube.txt в текущую папку и повторите."
    Write-Link "Плагин cookies.txt" $Links['Cookie exporter (Chrome/Edge extension)']
    exit 3
}

# Local cookie health summary (fast)
$health = Test-CookiesFileLocalHealth -Path $Cookies
Show-CookieHealthSummary -Health $health

if (-not $health.HasAnyCookieLines -or -not $health.HasKeyCookies -or $health.KeyCookiesExpired) {
    Write-Warn "Локальная проверка показывает потенциальную проблему с cookies. Пытаюсь онлайн-проверку по указанному URL."
    Write-Host ""
}

# ----------------------------
# Validate YouTube URL
# ----------------------------
if (-not (Test-YouTubeUrl -Url $Url)) {
    Write-Rule "❌ Ошибка валидации URL"
    Write-Err "Указанный URL не похож на действительную ссылку YouTube."
    Write-Info "Поддерживаемые форматы:"
    Write-Info "  • https://www.youtube.com/watch?v=VIDEO_ID"
    Write-Info "  • https://youtu.be/VIDEO_ID"
    Write-Info "  • https://www.youtube.com/shorts/VIDEO_ID"
    Write-Info "  • https://www.youtube.com/live/VIDEO_ID"
    Write-Info "  • https://m.youtube.com/watch?v=VIDEO_ID"
    Write-Host ""
    Write-Info "Ваш URL: $Url"
    Write-Warn "Если это действительно YouTube видео, пожалуйста, скопируйте полный URL из адресной строки браузера."
    exit 5
}

# Online cookie validation for the given URL (fast, no media download)
if (-not (Test-CookiesOnlineForUrl -UrlToTest $Url)) {
    exit 4
}

# ----------------------------
# Execute yt-dlp with strict naming rules
# ----------------------------
Write-Rule "📥 Старт загрузки"
Write-Info "URL: $Url"
Write-Info "Папка: $WorkDir"
Write-Host ""

if ($PSCmdlet.ParameterSetName -eq 'Full') {
    if ($Mp4) {
        # MP4 mode: H.264 video + AAC audio (max 1080p, but universal compatibility)
        $outFile = Get-NextNameFixedExt -Base 'downloaded' -Ext 'mp4' -Kind 'Full'
        Write-Info "📁 Файл вывода: $(Split-Path -Leaf $outFile)"
        Write-Info "🎬 Режим: видео+аудио (MP4-совместимый, H.264+AAC)"
        Write-Info "🎵 Аудио: формат 140 (AAC 128k)"
        Write-Warn "⚠️  MP4 режим: макс. 1080p, только H.264 видео"
        Write-Host ""

        # H.264 video + AAC audio (format 140), fallback to best mp4
        $format = 'bv*[vcodec^=avc1]+140/bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]'
        $mergeFormat = 'mp4'
    } else {
        # Default MKV mode: best quality (VP9/AV1 + Opus)
        $outFile = Get-NextNameFixedExt -Base 'downloaded' -Ext 'mkv' -Kind 'Full'
        Write-Info "📁 Файл вывода: $(Split-Path -Leaf $outFile)"
        Write-Info "🎬 Режим: видео+аудио (макс. качество) + объединение без перекодирования"
        Write-Info "🎵 Аудио-приоритет: 251 (Opus), иначе best audio"
        Write-Host ""

        $format = 'bv*+251/bv*+ba/b'
        $mergeFormat = 'mkv'
    }

    & $YtDlp --ffmpeg-location $WorkDir --cookies $Cookies `
        --no-playlist `
        -f $format `
        --merge-output-format $mergeFormat `
        -o $outFile `
        $Url

    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Ok "Скачивание завершено успешно: $(Split-Path -Leaf $outFile)"
    } else {
        Write-Host ""
        Write-Err "Скачивание завершилось с ошибкой (код: $exitCode)"
    }
    exit $exitCode
}

if ($PSCmdlet.ParameterSetName -eq 'Video') {
    $outTemplate = Get-NextNameFixedExt -Base 'video' -Ext 'auto' -Kind 'Video'
    Write-Info "📁 Вывод-шаблон: $(Split-Path -Leaf $outTemplate)"
    Write-Info "🎬 Режим: только видео (без аудио), макс. качество"
    Write-Host ""

    & $YtDlp --ffmpeg-location $WorkDir --cookies $Cookies `
        --no-playlist `
        -f 'bv*' `
        -o $outTemplate `
        $Url

    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host ""
        $actualFile = @(Get-ChildItem -LiteralPath $WorkDir -File -Filter "video*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        if ($actualFile) {
            Write-Ok "Скачивание завершено успешно: $($actualFile.Name)"
        } else {
            Write-Ok "Скачивание завершено успешно"
        }
    } else {
        Write-Host ""
        Write-Err "Скачивание завершилось с ошибкой (код: $exitCode)"
    }
    exit $exitCode
}

if ($PSCmdlet.ParameterSetName -eq 'Audio') {
    $outTemplate = Get-NextNameFixedExt -Base 'audio' -Ext 'auto' -Kind 'Audio'
    Write-Info "📁 Вывод-шаблон: $(Split-Path -Leaf $outTemplate)"
    Write-Info "🎵 Режим: только аудио (без видео), приоритет: 251 (Opus)"
    Write-Host ""

    & $YtDlp --ffmpeg-location $WorkDir --cookies $Cookies `
        --no-playlist `
        -f '251/ba/bestaudio' `
        -o $outTemplate `
        $Url

    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host ""
        $actualFile = @(Get-ChildItem -LiteralPath $WorkDir -File -Filter "audio*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        if ($actualFile) {
            Write-Ok "Скачивание завершено успешно: $($actualFile.Name)"
        } else {
            Write-Ok "Скачивание завершено успешно"
        }
    } else {
        Write-Host ""
        Write-Err "Скачивание завершилось с ошибкой (код: $exitCode)"
    }
    exit $exitCode
}

Write-Err "Неизвестный режим запуска."
exit 10
