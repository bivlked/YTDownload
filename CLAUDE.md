# CLAUDE.md - YTDownload

> Инструкции для сессий Claude Code в этой папке.

YouTube downloader (PowerShell). Репозиторий: `bivlked/YTDownload`.

## Навигация по коду (Serena + ast-grep)

- **Serena MCP** подключён в этой папке (символьная навигация через LSP). Для понимания и рефакторинга кода предпочитай его инструменты обычным Read/Grep: `get_symbols_overview` (оглавление файла), `find_symbol` (определение по имени), `find_referencing_symbols` (кто вызывает), `replace_symbol_body` / `rename_symbol` (точечная правка). Проверка: `/mcp` -> serena connected.
- **ast-grep** (`ast-grep` / `sg`, в PATH) - структурный поиск/замена по AST, когда нужна синтаксис-осведомлённость (точнее regex-Grep).
- Обычный Grep - для первичного текстового поиска.
