
CloudFlare ECH scripts README.

Этот набор скриптов и файлов предназначен для работы с настройками ECH (Encrypted Client Hello) для доменов в аккаунтах Cloudflare.

1. **cf_creds.csv** — файл для хранения учетных данных аккаунтов Cloudflare (email и API ключ).
2. **cf_ech_accounts.log** — лог-файл для записи действий и ошибок при проверке или изменении настроек ECH.
3. **cf_ech_check_status.sh** — скрипт для проверки статуса ECH на доменах аккаунта Cloudflare.
4. **cf_ech_disable_account.sh** — скрипт для отключения ECH на доменах одного аккаунта.
5. **cf_ech_disable_bulk.sh** — скрипт для отключения ECH на доменах всех аккаунтов, указанных в `cf_creds.csv`.
6. **reports/** — директория для хранения отчетов, генерируемых скриптами.

### Инструкция по использованию:

1. **Проверка статуса ECH на доменах в аккаунте:**
   - Запустите скрипт `cf_ech_check_status.sh`, указав ваш email и API ключ для Cloudflare.
   - Статус ECH будет записан в файл отчета в директории `reports`.

2. **Отключение ECH на доменах одного аккаунта:**
   - Запустите скрипт `cf_ech_disable_account.sh`, указав ваш email и API ключ.
   - Скрипт отключит ECH для всех доменов в указанном аккаунте.
   - Статус ECH будет записан в файл отчета в директории `reports`.

3. **Добавление нового аккаунта в `cf_creds.csv`:**
   - Откройте `cf_creds.csv` в текстовом редакторе.
   - Добавьте строку с вашим email и API ключом в формате:
     ```
     email@example.com,API_KEY
     ```

4. **Изменение параметров автоматического запуска по крону:**
   - Откройте файл crontab для редактирования:
     ```
     crontab -e
     ```
   - Добавьте или отредактируйте строку для выполнения скрипта:
     ```
     # Automated ECH disabling in all CloudFlare accounts
     0 8,20 * * * /srv/tools/CF/cf_ech_disable/cf_ech_disable_bulk.sh > /srv/tools/CF/cf_ech_disable/cf_ech_accounts.log 2>&1
     ```