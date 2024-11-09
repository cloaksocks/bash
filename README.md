# bash
**bash скрипты здесь.**

[**fstab_auto.sh**](https://github.com/cloaksocks/bash/blob/main/fstab_auto.sh) -- Скрипт отключает сетевые диски, очищает fstab, запрашивает учетные данные, создает каталоги и файлы, добавляет новые монтирования и монтирует сетевые диски. / The script disables network disks, clears fstab, requests credentials, creates directories and files, adds new mounts, and mounts network disks.

[**postgresql_db_backup.sh**](https://github.com/cloaksocks/bash/blob/main/postgresql_db_backup.sh) -- Этот скрипт автоматизирует процесс создания ежедневных и еженедельных резервных копий базы данных Postgresql, в соответствии с заданной политикой хранения. / This script automates the process of creating daily and weekly backups of the Postgresql database, according to the specified storage policy.

[**dd_mmcblk_to_gz_backup.sh**](https://github.com/cloaksocks/bash/blob/main/dd_mmcblk_to_gz_backup.sh) -- Скрипт создает сжатые резервные копии всех разделов на карте SD.
- Сохраняет информацию о разметке разделов в файл `partition_table.txt`.
- Резервное копирование всех разделов, найденных по пути `/dev/mmcblk0p*`.
- Сохраняет сжатые файлы резервных копий в текущем каталоге.
- Использует `dd` с `conv=sparse` для пропуска пустых блоков.

[**dd_mmcblk_from_gz_restore.sh**](https://github.com/cloaksocks/bash/blob/main/dd_mmcblk_from_gz_restore.sh) -- Скрипт восстанавливает разделы из сжатых файлов резервных копий.
- Создает разделы на целевой карте в соответствии с конфигурацией из файла  `partition_table.txt`.
- Восстанавливает все разделы, найденные в архивах на карту `/dev/mmcblk0p*.
- Ожидает, что файлы резервных копий находятся в текущем каталоге.
- Использует `gunzip` и `dd` для восстановления разделов.


### Cloudflare disable ECH scripts

Скрипты для работы с настройками ECH (Encrypted Client Hello) для доменов в аккаунтах Cloudflare.

1. [**cf_creds.csv**](https://github.com/cloaksocks/bash/blob/main/cf_creds.csv) — CloudFlare credentials в формате `email,GlobalAPI_ключ`.
2. [**cf_ech_check_status.sh**](https://github.com/cloaksocks/bash/blob/main/cf_ech_check_status.sh) — скрипт для проверки статуса ECH на доменах аккаунта Cloudflare.
3. [**cf_ech_disable_account.sh**](https://github.com/cloaksocks/bash/blob/main/cf_ech_disable_account.sh) — скрипт для отключения ECH на доменах одного аккаунта.
4. [**cf_ech_disable_bulk.sh**](https://github.com/cloaksocks/bash/blob/main/cf_ech_disable_bulk.sh) — скрипт для отключения ECH на доменах всех аккаунтов, указанных в `cf_creds.csv`.
5. **reports/** — отчёты об аккаунтах, создаётся скриптом.

**Инструкция по использованию**

1. **Проверка статуса ECH на доменах в аккаунте:**
   - Запустите скрипт `cf_ech_check_status.sh`, поочерёдно введите email и Global API ключ для Cloudflare.
   - Статус ECH будет записан в файл отчета в директории `reports`.

2. **Отключение ECH на доменах одного аккаунта:**
   - Запустите скрипт `cf_ech_disable_account.sh`, поочерёдно введите email и Global API ключ для Cloudflare.
   - Скрипт отключит ECH для всех доменов в указанном аккаунте.
   - Статус ECH будет записан в файл отчета в директории `reports`.

3. **Добавление нового аккаунта в `cf_creds.csv`:**
   - Откройте или создайте `cf_creds.csv` в текстовом редакторе.
   - Добавьте строки с email и Global API ключом в формате:
     ```
     email@example.com,API_KEY
     email2@example.com,API_KEY2
     ```

4. **Изменение параметров автоматического запуска по крону:**
   - Откройте файл crontab для редактирования:
     ```
     crontab -e
     ```
   - Добавьте или отредактируйте строку для выполнения скрипта:
     ```
     # Automated ECH disabling in all CloudFlare accounts
     0 8,20 * * * /path-to/cf_ech_disable_bulk.sh > /path-to/cf_ech_accounts.log 2>&1
