#!/bin/bash

# Проверка на выполнение скрипта с правами root
if [ "$(id -u)" -ne "0" ]; then
    echo "Этот скрипт нужно выполнять с правами root (используйте sudo)." 1>&2
    exit 1
fi

# Файл для хранения конфигурации разделов
PARTITION_CONFIG="partition_table.txt"

# Путь для сохранения резервных копий (текущий каталог)
BACKUP_DIR="."

# Создание директории для резервных копий, если она не существует
mkdir -p "$BACKUP_DIR"

# Сохранение конфигурации разделов
echo "Сохранение конфигурации разделов..."
sfdisk -d "$SOURCE_DEVICE" > "$PARTITION_CONFIG"
echo "Конфигурация разделов сохранена в $PARTITION_CONFIG"

# Получение списка разделов на карте памяти
PARTITIONS=$(ls /dev/mmcblk0p*)

# Бэкап каждого раздела
for PARTITION in $PARTITIONS; do
  # Имя файла бэкапа
  BACKUP_FILE="$BACKUP_DIR/$(basename $PARTITION).img.gz"
  
  echo "Backing up $PARTITION to $BACKUP_FILE..."
  sudo dd if="$PARTITION" bs=4M conv=sparse status=progress | gzip > "$BACKUP_FILE"
  
  if [ $? -eq 0 ]; then
    echo "Backup of $PARTITION completed successfully."
  else
    echo "Error occurred during backup of $PARTITION."
  fi
done

echo "All backups completed."
