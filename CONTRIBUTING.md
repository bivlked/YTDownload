# Как внести вклад / Contributing

Спасибо за интерес к проекту! / Thank you for your interest! English speakers: issues and PRs in English are welcome.

## 🐛 Сообщить о баге

Лучший способ - открыть [Issue по шаблону «Сообщение об ошибке»](https://github.com/bivlked/YTDownload/issues/new/choose). Чтобы баг можно было воспроизвести и починить, обязательно укажите:

1. **Версию PowerShell**: вывод `$PSVersionTable.PSVersion` (нужна 7.2+; запуск через `pwsh.exe`, не `powershell.exe`)
2. **Версию yt-dlp**: вывод `.\yt-dlp.exe --version`
3. **Точную команду**, которую вы запускали (URL можно заменить на похожий публичный ролик)
4. **Полный текст ошибки** - весь вывод скрипта, не только последнюю строку

Перед созданием Issue полезно проверить два самых частых случая:

- Устаревший yt-dlp: `.\ytdlp.ps1 -Setup -Force` решает большинство ошибок скачивания
- Устаревшие cookies: переэкспортируйте `cookies-youtube.txt` (инструкция в [README](README.md#-шаг-2-настройте-cookies))

## 💡 Предложить улучшение

Откройте Issue с описанием: какую задачу решает предложение и как вы видите поведение. Обсудить идею до написания кода - быстрее для всех.

## 🔀 Pull Request

1. Форкните репозиторий и создайте ветку от `main`
2. Один PR - одно логическое изменение
3. Скрипт должен проходить [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) без новых предупреждений (существующие осознанные исключения: `PSAvoidUsingWriteHost` - цветной UI, `PSReviewUnusedParameter` для `Video`/`Audio` - ложное срабатывание ParameterSetName)
4. Проверьте изменения реальным запуском: `-Setup` в чистой папке и хотя бы один режим скачивания
5. Обновите README (обе языковые версии) и CHANGELOG.md, если меняется поведение

## 📏 Стиль кода

- PowerShell 7.2+, `Set-StrictMode -Version Latest`
- Одобренные глаголы в именах функций (`Get-`, `Test-`, `Save-`, `Initialize-`)
- Кодировка файла: UTF-8 с BOM
- Пунктуация в строках вывода: обычный дефис `-`, не длинное тире
