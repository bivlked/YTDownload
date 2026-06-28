# 📥 YTDownload

**Простой и безопасный PowerShell скрипт для скачивания видео с YouTube в максимальном качестве**

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)

## ✨ Особенности

- ✅ **Максимальное качество** — скачивает лучшие доступные видео и аудио потоки без перекодирования
- 🔒 **Безопасность** — работает только в текущей папке, не изменяет системные файлы
- 🎯 **Простота** — один скрипт, никаких системных зависимостей кроме PowerShell 7+
- 🚀 **Автоматическая установка** — скачивает все необходимые компоненты одной командой
- 📦 **Портативность** — все файлы в одной папке, легко переносить
- 🎨 **Красивый вывод** — цветные информативные сообщения с эмодзи
- 🍪 **Поддержка cookies** — обход проверок "не робот ли вы" от YouTube
- ⚡ **Быстрая проверка** — валидация cookies и URL перед скачиванием

## 📋 Требования

- **Windows 10/11**
- **PowerShell 7+** ([скачать](https://github.com/PowerShell/PowerShell/releases))
- **cookies-youtube.txt** — файл cookies для авторизации (см. Шаг 2)

Компоненты yt-dlp, ffmpeg, ffprobe скрипт скачает автоматически!

## 🚀 Быстрый старт

**TL;DR для опытных:** скачайте скрипт, разблокируйте, запустите Setup, добавьте cookies:

```powershell
Unblock-File .\ytdlp.ps1
.\ytdlp.ps1 -Setup
# + добавьте cookies-youtube.txt
.\ytdlp.ps1 "https://youtube.com/watch?v=VIDEO_ID"
```

---

### 📦 Шаг 1: Скачайте и установите

<details>
<summary>Нужен PowerShell 7? Проверьте версию...</summary>

Откройте PowerShell и выполните:
```powershell
$PSVersionTable.PSVersion
```
Если версия ниже 7.0, [скачайте PowerShell 7](https://github.com/PowerShell/PowerShell/releases/latest) (файл `PowerShell-7.x.x-win-x64.msi`).

</details>

**1.** [📥 **Скачайте ytdlp.ps1**](https://github.com/bivlked/YTDownload/releases/latest/download/ytdlp.ps1) в новую папку (например, `C:\YTDownload\`)

**2.** Откройте **PowerShell 7** и выполните:

```powershell
cd C:\YTDownload
Unblock-File .\ytdlp.ps1
.\ytdlp.ps1 -Setup
```

Скрипт автоматически скачает yt-dlp, ffmpeg и ffprobe.

<details>
<summary>❓ Ошибка "not digitally signed" или "scripts is disabled"?</summary>

Windows блокирует скрипты из интернета. Решение:

```powershell
# Вариант 1: Разблокировать файл
Unblock-File .\ytdlp.ps1

# Вариант 2: Через GUI
# ПКМ на файл → Свойства → ☑ Разблокировать → ОК

# Вариант 3: Разрешить все скрипты в текущей сессии
Set-ExecutionPolicy Bypass -Scope Process
```

</details>

---

### 🍪 Шаг 2: Настройте cookies

> ⚠️ **Cookies обязательны** — без файла `cookies-youtube.txt` скрипт не запустится

| Шаг | Действие |
|:---:|----------|
| 1️⃣ | Установите расширение [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) |
| 2️⃣ | Откройте **InPrivate/Incognito** окно и войдите в YouTube |
| 3️⃣ | Перейдите на `youtube.com/robots.txt` и экспортируйте cookies |
| 4️⃣ | Сохраните как `cookies-youtube.txt` в папку со скриптом |
| 5️⃣ | **Сразу закройте** InPrivate окно (важно!) |

<details>
<summary>🔄 Cookies перестали работать?</summary>

YouTube периодически ротирует cookies. Просто повторите шаги 2-5 выше.
Ключевой момент: экспортируйте с `youtube.com/robots.txt`, не с главной страницы.

</details>

---

### 🎬 Шаг 3: Скачивайте!

```powershell
# Видео + аудио в максимальном качестве
.\ytdlp.ps1 "https://www.youtube.com/watch?v=VIDEO_ID"

# Только видео (без звука)
.\ytdlp.ps1 -Video "https://www.youtube.com/watch?v=VIDEO_ID"

# Только аудио (без видео)
.\ytdlp.ps1 -Audio "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Готово!** Файлы сохраняются в текущей папке как `downloaded.mkv`, `video.webm`, `audio.webm` и т.д.

## 📖 Подробная инструкция

### Режимы работы

| Режим | Команда | Что делает | Формат |
|-------|---------|------------|--------|
| **Полное видео** | `.\ytdlp.ps1 "URL"` | Видео + аудио | `.mkv` |
| **Только видео** | `.\ytdlp.ps1 -Video "URL"` | Видео без звука | `.webm`/`.mp4` |
| **Только аудио** | `.\ytdlp.ps1 -Audio "URL"` | Аудио без видео | `.webm`/`.m4a` |
| **MP4 формат** | `.\ytdlp.ps1 -Mp4 "URL"` | Видео + аудио (H.264) | `.mp4` |
| **Установка** | `.\ytdlp.ps1 -Setup` | Скачивает компоненты | — |
| **Диагностика** | `.\ytdlp.ps1` | Статус компонентов и справка | — |

---

#### 📦 Режим установки: `-Setup`

Автоматически скачивает и устанавливает все необходимые компоненты в текущую папку.

```powershell
# Первичная установка
.\ytdlp.ps1 -Setup

# Принудительное обновление (перезапись существующих файлов)
.\ytdlp.ps1 -Setup -Force
```

**Что делает:**
- Скачивает последние стабильные версии yt-dlp, ffmpeg, ffprobe
- Проверяет актуальность версии yt-dlp
- Показывает информацию о версиях установленных компонентов
- Напоминает о необходимости добавить cookies

#### 📥 Режим "Полное видео" (по умолчанию)

Скачивает видео и аудио в максимальном качестве и объединяет их в один файл MKV без перекодирования.

```powershell
.\ytdlp.ps1 "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Формат выбора потоков:** `bv*+251/bv*+ba/b`
- Лучшее видео + аудио формат 251 (Opus)
- Если 251 недоступен — лучшее видео + лучшее аудио
- Fallback на лучший комбинированный поток

**Имена файлов:**
- `downloaded.mkv` (первый файл)
- `downloaded000.mkv`, `downloaded001.mkv`, ... (последующие)

#### 🎬 Режим "Только видео": `-Video`

Скачивает только видео в максимальном качестве (без звука).

```powershell
.\ytdlp.ps1 -Video "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Формат выбора потоков:** `bv`
- Лучший видео поток **без аудио** (best video-only)
- `bv` (а не `bv*`) гарантирует поток без звуковой дорожки

**Имена файлов:**
- `video.webm`, `video.mp4`, ... (первый файл, расширение зависит от формата)
- `video001.webm`, `video002.mp4`, ... (последующие)

#### 🎵 Режим "Только аудио": `-Audio`

Скачивает только аудио в максимальном качестве (без видео).

```powershell
.\ytdlp.ps1 -Audio "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Формат выбора потоков:** `251/ba/b`
- Формат 251 (Opus, обычно лучшее качество для YouTube)
- Если 251 недоступен — лучший аудио поток (`ba`)
- Если нет отдельного аудио — лучший комбинированный поток (`b`)

**Имена файлов:**
- `audio.webm`, `audio.m4a`, ... (первый файл, расширение зависит от формата)
- `audio001.webm`, `audio002.m4a`, ... (последующие)

### Поддерживаемые форматы URL

Скрипт поддерживает следующие типы YouTube ссылок:

- ✅ `https://www.youtube.com/watch?v=VIDEO_ID`
- ✅ `https://youtu.be/VIDEO_ID`
- ✅ `https://www.youtube.com/shorts/VIDEO_ID`
- ✅ `https://www.youtube.com/live/VIDEO_ID`
- ✅ `https://www.youtube.com/clip/CLIP_ID`
- ✅ `https://www.youtube.com/embed/VIDEO_ID`
- ✅ `https://www.youtube.com/@Channel/live`
- ✅ `https://www.youtube.com/@Channel/shorts/VIDEO_ID`
- ✅ `https://m.youtube.com/watch?v=VIDEO_ID`
- ✅ `https://music.youtube.com/watch?v=VIDEO_ID`
- ✅ `https://www.youtube-nocookie.com/embed/VIDEO_ID`

**Важно:** Скрипт НЕ скачивает плейлисты целиком (флаг `--no-playlist` включен). Для скачивания из плейлиста нужно указывать URL каждого видео отдельно.

## 🔍 Проверки и валидация

Скрипт автоматически выполняет несколько проверок перед скачиванием:

### 1. Проверка компонентов
- Обязательны для скачивания: `yt-dlp.exe`, `ffmpeg.exe`, `cookies-youtube.txt`
- `ffprobe.exe` — опционален (нужен только для анализа медиа); при отсутствии скрипт выдаёт предупреждение, но продолжает работу
- Если обязательного компонента нет — выдается понятное сообщение с инструкцией

### 2. Локальная проверка cookies
- Формат файла (Netscape cookies.txt)
- Наличие cookie-строк
- Наличие ключевых cookies для YouTube (SID, SAPISID, HSID, и т.д.)
- Проверка срока действия cookies

### 3. Онлайн-проверка cookies (условная)
- Выполняется **только если** локальная проверка выявила потенциальные проблемы
- Если cookies выглядят корректно — онлайн-проверка пропускается для ускорения
- Быстрая проверка работоспособности cookies на указанном URL (флаг `--skip-download`)
- Если cookies не работают — показывает детальную инструкцию по их обновлению

### 4. Валидация URL
- Проверка, что URL действительно ведет на YouTube
- Если URL не похож на YouTube — выдается ошибка с примерами правильных форматов

## 🔄 Обновление

Для обновления yt-dlp и ffmpeg до последних версий:

```powershell
.\ytdlp.ps1 -Setup -Force
```

Скрипт покажет текущую и последнюю версию yt-dlp, а также предупредит, если доступно обновление.

---

## 🛠️ Устранение неполадок

<details>
<summary><b>🍪 Проблемы с cookies</b> — "Sign in to confirm you're not a bot", "cookies rotated"</summary>

**Причина:** Cookies отсутствуют, устарели или ротированы YouTube.

**Решение:** Экспортируйте свежие cookies:
1. Откройте **InPrivate/Incognito** окно → войдите в YouTube
2. Перейдите на `youtube.com/robots.txt` → экспортируйте cookies
3. Сохраните как `cookies-youtube.txt` → **сразу закройте** InPrivate окно

> 💡 Всегда экспортируйте с `/robots.txt`, не с главной страницы!

</details>

<details>
<summary><b>🔒 Скрипт не запускается</b> — "not digitally signed", "scripts is disabled"</summary>

**Причина:** Windows блокирует скрипты из интернета.

**Решение:**
```powershell
# Способ 1: Разблокировать файл
Unblock-File .\ytdlp.ps1

# Способ 2: Через GUI
# ПКМ на файл → Свойства → ☑ Разблокировать → ОК

# Способ 3: Разрешить в текущей сессии
Set-ExecutionPolicy Bypass -Scope Process
```

</details>

<details>
<summary><b>⚡ Старая версия PowerShell</b> — странные ошибки, "не распознано имя cmdlet"</summary>

**Причина:** Используется Windows PowerShell 5.x вместо PowerShell 7+.

**Проверка:** `$PSVersionTable.PSVersion` — должно быть 7.0+

**Решение:**
1. [Скачайте PowerShell 7](https://github.com/PowerShell/PowerShell/releases/latest)
2. Запускайте через **pwsh.exe**, не powershell.exe
3. В Windows Terminal выберите профиль "PowerShell" (не "Windows PowerShell")

</details>

<details>
<summary><b>📺 Качество ниже ожидаемого</b></summary>

**Возможные причины:**
- Cookies не работают — обновите их
- Видео недоступно в высоком качестве в вашем регионе
- Используйте `-Mp4` — он ограничен 1080p

**Проверка:** Откройте видео в браузере и проверьте доступные качества.

</details>

<details>
<summary><b>😀 Эмодзи отображаются некорректно</b></summary>

**Причина:** Старый терминал или кодировка.

**Решение:**
- Используйте [Windows Terminal](https://aka.ms/terminal)
- Или PowerShell 7+ напрямую (не Git Bash)

</details>

## 📁 Структура файлов

После установки в папке будут следующие файлы:

```
📁 YourFolder/
├── 📄 ytdlp.ps1              # Основной скрипт
├── 🔧 yt-dlp.exe             # Загрузчик видео (~18 MB)
├── 🔧 ffmpeg.exe             # Инструмент обработки видео (~100-200 MB)
├── 🔧 ffprobe.exe            # Анализатор медиа (~2-10 MB)
├── 🍪 cookies-youtube.txt    # Ваши cookies для YouTube
├── 📥 downloaded.mkv         # Скачанные видео (пример)
└── 📥 downloaded000.mkv      # Последующие скачивания
```

**Важно:** Все файлы остаются в этой папке. Скрипт НЕ устанавливает ничего в систему!

## ⚙️ Технические детали

### Почему MKV для полных видео?

MKV (Matroska) — это контейнер, который:
- Поддерживает любые кодеки (VP9, AV1, H.264, Opus, AAC, и т.д.)
- Не требует перекодирования (fast, lossless muxing)
- Сохраняет 100% качества оригинальных потоков
- Универсально поддерживается плеерами (VLC, MPC-HC, и др.)

### Нужен MP4 вместо MKV?

Если ваше устройство не поддерживает MKV (некоторые ТВ, старые телефоны), используйте параметр `-Mp4`:

```powershell
.\ytdlp.ps1 -Mp4 "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Ограничения режима MP4:**
- Максимальное разрешение **1080p** (нет 1440p/4K)
- Используется H.264 видео + AAC аудио (не VP9/Opus)
- Качество чуть ниже при том же размере файла

Это связано с тем, что контейнер MP4 не поддерживает кодеки VP9 и Opus, которые YouTube использует для лучшего качества.

### Формат селектор yt-dlp

Скрипт использует умные форматные селекторы:

```
Полное видео (MKV):  bv*+251/bv*+ba/b
Полное видео (MP4):  bv*[vcodec^=avc1][height<=1080]+140/bv*[vcodec^=avc1][height<=1080]+ba[ext=m4a]/b[ext=mp4][vcodec^=avc1][height<=1080]
Только видео:        bv
Только аудио:        251/ba/b
```

Где:
- `bv*` — best video (формат, **содержащий** видео; может включать аудио)
- `bv` — best video-only (видео **без** аудио)
- `ba` — best audio (лучшее аудио, алиас `bestaudio`)
- `b` — best (лучший комбинированный поток видео+аудио)
- `251` — формат 251 (Opus, обычно высокое качество)
- `[height<=1080]` — ограничение разрешения для совместимости MP4
- `/` — fallback (если первый вариант недоступен)

### Безопасность

Скрипт спроектирован с акцентом на безопасность:

- ✅ Работает **только** в текущей папке (не трогает систему)
- ✅ Не перезаписывает файлы без флага `-Force`
- ✅ Проверяет размер скачанных компонентов в режиме `-Setup` (защита от неполных загрузок)
- ✅ Не скачивает плейлисты целиком (флаг `--no-playlist`)
- ✅ Валидирует URL перед запуском yt-dlp
- ✅ Использует `Set-StrictMode -Version Latest`
- ✅ Все ошибки обрабатываются с понятными сообщениями

## 🤝 Вклад в проект

Нашли баг или хотите предложить улучшение? Создайте Issue или Pull Request!

## 📜 Лицензия

MIT License — используйте свободно, на свой риск.

## ⚠️ Дисклеймер

Этот скрипт предназначен для личного использования. Убедитесь, что скачивание видео не нарушает авторские права и условия использования YouTube.

---

**Автор:** [bivlked](https://github.com/bivlked)
**Репозиторий:** [YTDownload](https://github.com/bivlked/YTDownload)

Если этот скрипт оказался полезным, поставьте ⭐ на GitHub!
