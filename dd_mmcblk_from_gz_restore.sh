#!/bin/bash

# Проверка на выполнение скрипта с правами root
if [ "$(id -u)" -ne "0" ]; then
    echo "Этот скрипт нужно выполнять с правами root (используйте sudo)." 1>&2
    exit 1
fi

# Путь к целевой карте SD
TARGET_DEVICE="/dev/mmcblk0"

# Файл с конфигурацией разделов
PARTITION_CONFIG="partition_table.txt"

# Функция для создания разделов на целевой карте
create_partitions() {
    if [ ! -f "$PARTITION_CONFIG" ]; then
        echo "Не найден файл конфигурации разделов: $PARTITION_CONFIG" 1>&2
        exit 1
    fi
    
    echo "Создание разделов на целевой карте SD..."
    
    # Удаление существующих разделов
    sfdisk --delete "$TARGET_DEVICE"
    
    # Создание новых разделов по конфигурации
    sfdisk "$TARGET_DEVICE" < "$PARTITION_CONFIG"
}

# Функция для восстановления данных в разделы
restore_partitions() {
    echo "Восстановление данных в разделы..."

    # Список архивов разделов
    local backups=( *.img.gz )
    
    # Восстановление данных в каждый раздел
    local partition_num=1
    for backup in "${backups[@]}"; do
        local partition="${TARGET_DEVICE}p${partition_num}"
        
        echo "Восстановление данных из $backup в $partition..."
        
        # Распаковка резервной копии и запись данных
        gunzip -c "$backup" | dd of="$partition" bs=4M status=progress
        
        partition_num=$((partition_num + 1))
    done
}

# Основная функция
main() {
    # Создание разделов
    create_partitions

    # Восстановление данных
    restore_partitions

    echo "Восстановление завершено."
}

# Выполнение основной функции
main
