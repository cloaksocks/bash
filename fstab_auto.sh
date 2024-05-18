#!/bin/bash

# данный скрипт отключает сетевые диски, убирает строки монтирования из fstab и подключает новые сетевые диски
# логин и пароль для каждой samba share запрашивается при каждом запуске скрипта
# скрипт создаёт каталоги для монтирования, файлы c кредами, строки монтирования в fstab, ярлыки на Рабочий стол.

clear

# Массив строк монтирования
# Здесь должны быть уже проверенные и рабочие строки для монтирования, с уникальными путями каталогов для монтирования (/srv/share) и именами файлов .creds

mount_entries=(
    ### Добавьте нужные строки монтирования здесь:
    "//192.168.0.1/для\040ознакомления /srv/share1 cifs auto,user,noperm,rw,credentials=/home/user/.creds1 0 0"
    "//192.168.0.2/ГИТ /srv/share cifs auto,user,noperm,rw,credentials=/home/user/.creds2 0 0"
    ###
)

# функция для отмонтирования сетевых дисков
umount_network_disks() {
    umount -a -t cifs
}

# основной цикл для обработки каждого mount entry
main_loop() {
    for entry in "${mount_entries[@]}"; do
        if [ -n "$entry" ]; then

            # определение имени пользователя
            homeuser=$(echo "$entry" | sed -n 's|.*credentials=/home/\([^/]*\).*|\1|p')

            # определение имени creds файла
            credsname=$(echo "$entry" | awk -F'/' '{print $NF}' | awk '{print $1}')

            # определение sambashare
            sambashare=$(echo "$entry" | awk '{print $1}' | sed 's/\\040/ /g')

            # определение каталога для монтирования
            folder=$(echo "$entry" | awk '{print $2}')

            # определение имени для symlink
            symlink=$(echo "$entry" | awk -F'/' '{print $4}' | sed 's/\\040/_/g')

            # создание каталога для монтирования
            mkdir -p "$folder"

            # запрос имени и пароля SAMBA пользователя и добавление их в creds
            read -p "Введите имя пользователя учётной записи SAMBA для сетевого диска '$sambashare': " sambauser
            read -p "Введите пароль учётной записи SAMBA для сетевого диска '$sambashare': " sambapswd
            echo

            # создание creds файлов
            echo "username=$sambauser" > "/home/$homeuser/$credsname"
            echo "password=$sambapswd" >> "/home/$homeuser/$credsname"

            # установка прав на .creds файлы
            chmod 600 "/home/$homeuser/$credsname"
            chown "$homeuser:" "/home/$homeuser/$credsname"

            # создание символьных ссылок на рабочий стол
            ln -s "$folder" "/home/$homeuser/Рабочий стол/$symlink"
            chown "$homeuser:" "/home/$homeuser/Рабочий стол/$symlink"
        fi
    done
}

# функция для удаления пустых строк и строк монтирования по маске cifs из fstab
remove_fstab_entries() {
    sed -i '/cifs/d' /etc/fstab
    sed -i '/^$/d' /etc/fstab
}

# функция для добавления строк монтирования сетевых дисков в fstab
add_to_fstab() {
    for entry in "${mount_entries[@]}"; do
        echo "$entry" >> /etc/fstab
    done
}

# функция для монтирования сетевых дисков
mount_network_disks() {
    mount -a
}

# вызов всех функций
umount_network_disks
main_loop
remove_fstab_entries
add_to_fstab
mount_network_disks
