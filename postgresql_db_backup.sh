#!/bin/bash

# скрипт автоматизирует процесс создания резервных копий базы данных и управляет их хранением в соответствии
# с заданной политикой. В нем предусмотрено создание новых директорий для резервных копий, создание резервной
# копии базы данных в сжатом виде, а также управление сохранением и удалением ежедневных и еженедельных резервных копий.
# скрипт требует добавления задачи в cron для запуска резервного копирования с регулярными интервалами.

# Установка префикса имени файла резервной копии, имени базы данных, директории для резервных копий,
# а также поддиректории для ежедневных и еженедельных резервных копий:
FILE_PREFIX="db_backup_"
DB_NAME="financial_exchange"
BACKUP_DIR="backups"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
BACKUP_FILE="$BACKUP_DIR/$FILE_PREFIX$(date +'%Y-%m-%d_%H:%M').tar"

# Функция для создания директорий для хранения резервных копий, если они не существуют.
create_backup_dirs() {
    local DIRS=("$BACKUP_DIR" "$DAILY_DIR" "$WEEKLY_DIR")
    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -m 700 -p "$dir"  # Создание директории с правами доступа 700
        fi
    done
}

# Функция для создания резервной копии базы данных в сжатом виде.
backup_database() {
    pg_dump -d $DB_NAME -Ft | gzip > $BACKUP_FILE.gz
}

# Функция для сохранения ежедневной резервной копии, если она еще не была сохранена сегодня.
retain_daily_backup() {
    if ! find "$DAILY_DIR" -type f -name "$FILE_PREFIX$(date +'%Y-%m-%d')*.tar.gz" -print -quit | grep -q .; then
        cp -p $BACKUP_FILE.gz $DAILY_DIR
    fi
}

# Функция для удаления ежедневных резервных копий старше двух дней.
delete_old_daily_backups() {
    find $DAILY_DIR -type f -mtime +2 -delete
}

# Функция для сохранения еженедельной резервной копии, если она еще не была сохранена на текущей неделе.
retain_weekly_backup() {
    if ! find "$WEEKLY_DIR" -type f -newermt "last sunday" -print -quit | grep -q .; then
        cp -p $BACKUP_FILE.gz $WEEKLY_DIR
    fi
}

# Функция для сохранения последних пяти резервных копий, удаляя более старые.
retain_latest_backups() {
    ls -dt $BACKUP_DIR/*| grep $FILE_PREFIX | tail -n +6 | xargs rm -f
}

# Основной поток выполнения скрипта:
create_backup_dirs       # Создаем необходимые директории
backup_database          # Создаем резервную копию базы данных
retain_daily_backup      # Сохраняем ежедневную резервную копию
delete_old_daily_backups # Удаляем старые ежедневные копии
retain_weekly_backup     # Сохраняем еженедельную резервную копию
retain_latest_backups    # Удаляем старые резервные копии, оставляя только последние пять
