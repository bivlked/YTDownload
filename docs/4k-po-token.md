# 📺 Скачивание в 4K и PO Token

Практический гайд на случай, когда вместо 4K приходит 1080p или загрузка обрывается с `HTTP Error 403: Forbidden`.

## TL;DR

В большинстве случаев достаточно **обновить yt-dlp**:

```powershell
.\ytdlp.ps1 -Setup -Force
.\ytdlp.ps1 "https://www.youtube.com/watch?v=VIDEO_ID"
```

YouTube регулярно меняет защиту, а yt-dlp за ней следует. Отставшая версия - самая частая причина 403 и «только 1080p».

## Почему 4K иногда не скачивается

- 4K и 1440p на YouTube отдаются только в DASH-потоках (VP9/AV1). Режим `-Mp4` их не берёт (H.264 ограничен 1080p), поэтому для 4K нужен **дефолтный режим** (`.\ytdlp.ps1 "URL"`, контейнер MKV).
- В последние годы YouTube закрывает высокое качество за **PO Token** (Proof of Origin) и переводит часть клиентов на **SABR**. Без корректного токена сервер отдаёт около 90 МБ данных и разрывает соединение с `403 Forbidden`.
- yt-dlp обходит это, подбирая клиент и токен. Когда YouTube меняет правила, yt-dlp выпускает обновления вслед за этими изменениями. Пример: в версии `2026.08.19` из набора клиентов по умолчанию убрали `android_vr` - именно он отдавал 4K-поток, чей токен не совпадал с запросом, и загрузка падала в 403. После обновления ролик, который раньше обрывался на 403, скачался целиком в 4K (AV1 3840x2160, Opus, около 9.76 ГБ) - без смены IP.

## Шаг 1. Обновите yt-dlp (решает большинство случаев)

```powershell
.\ytdlp.ps1 -Setup -Force
.\ytdlp.ps1 "https://www.youtube.com/watch?v=VIDEO_ID"
```

Проверить, что скачалось именно 4K:

```powershell
.\ffprobe.exe -v error -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1 downloaded.mkv
```

`height=2160` - это 4K, `height=1440` - это 1440p. Если там `1080` - смотрите шаги ниже.

## Шаг 2. Убедитесь, что у ролика вообще есть 4K

```powershell
.\yt-dlp.exe -F "https://www.youtube.com/watch?v=VIDEO_ID"
```

Ищите строки с `2160` (4K) или `4320` (8K). Если их нет - автор просто не загрузил ролик в 4K, и взять его неоткуда.

## Шаг 3. Упорный 403 - локальный PO Token провайдер (bgutil)

Если после обновления yt-dlp 4K всё равно обрывается в 403, поднимите локальный генератор PO-токенов **bgutil**. Нужен Docker (проще всего) или Node.js.

**Сервер (Docker):**

```powershell
docker run --name bgutil-provider -d --restart unless-stopped --init -p 4416:4416 brainicism/bgutil-ytdlp-pot-provider
```

**Плагин для yt-dlp (PowerShell):**

```powershell
$pd = "$env:APPDATA\yt-dlp\plugins"
New-Item -ItemType Directory -Force -Path $pd | Out-Null
Invoke-WebRequest "https://github.com/Brainicism/bgutil-ytdlp-pot-provider/releases/latest/download/bgutil-ytdlp-pot-provider.zip" -OutFile "$pd\bgutil-ytdlp-pot-provider.zip"
```

**Проверка, что плагин подхватился:**

```powershell
.\yt-dlp.exe -v --simulate -f 251 "https://www.youtube.com/watch?v=VIDEO_ID" | Select-String "PO Token Providers"
```

В выводе должна быть строка вида `bgutil:http`. После этого скачивайте обычной командой скрипта - токен подставится автоматически.

> ⚠️ Первая (холодная) генерация токена может занять больше 20 секунд, и yt-dlp по таймауту её не дождётся. Integrity-токен при этом кэшируется примерно на 12 часов, поэтому просто повторите команду: при повторном запуске yt-dlp сможет использовать уже закэшированный токен.

Документация провайдера: <https://github.com/Brainicism/bgutil-ytdlp-pot-provider>
Гайд yt-dlp по PO Token: <https://github.com/yt-dlp/yt-dlp/wiki/PO-Token-Guide>

## Региональный доступ (DPI, VPN)

Если YouTube режется провайдером на уровне DPI (актуально для некоторых регионов) - это **отдельная** проблема доступа к YouTube вообще, а не к 4K:

- **Обход DPI на домашнем канале** (например [zapret](https://github.com/Flowseal/zapret-discord-youtube)) сохраняет ваш домашний IP и открывает доступ к YouTube. Это удобно, потому что для 4K важнее корректный PO Token (шаги 1-3), чем тип IP.
- **VPN** тоже открывает доступ. На саму возможность 4K он не влияет - её определяют шаги 1-3.

## Честные оговорки

- PO Token помогает, но не гарантирует обход 403 на 100% (об этом честно пишут и авторы bgutil).
- Это игра в догонялки: YouTube меняет защиту, yt-dlp её обходит. Лучшая профилактика - держать yt-dlp свежим (`.\ytdlp.ps1 -Setup -Force`).
