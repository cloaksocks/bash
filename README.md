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
- Создает разделы на целевой карте в соответствии с конфигурацией из файла partition_table.txt.
- Восстанавливает все разделы, найденные в архивах на карту `/dev/mmcblk0p*.
- Ожидает, что файлы резервных копий находятся в текущем каталоге.
- Использует `gunzip` и `dd` для восстановления разделов.
