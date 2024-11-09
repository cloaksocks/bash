#!/bin/bash

# Запросить email и API ключ
read -p "Введите ваш email для Cloudflare: " AUTH_EMAIL
read -sp "Введите ваш API ключ для Cloudflare: " AUTH_KEY
echo

# Папка для отчетов
REPORT_DIR="./reports"

# Создать папку для отчетов, если её нет
mkdir -p "$REPORT_DIR"

# Путь для отчета
REPORT_FILE="${REPORT_DIR}/ech_report_${AUTH_EMAIL}.csv"

# Заголовок для CSV
echo "email,domain,zone_id,ech_status" > "$REPORT_FILE"

# Получение всех зон для аккаунта
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
    -H "X-Auth-Email: ${AUTH_EMAIL}" \
    -H "X-Auth-Key: ${AUTH_KEY}" \
    -H "Content-Type: application/json")

# Логирование ответа
echo "Ответ от Cloudflare для аккаунта ${AUTH_EMAIL}: $RESPONSE"

# Проверка на ошибку в запросе
ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errors[0].code')
ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.errors[0].message')

if [ "$ERROR_CODE" != "null" ]; then
    echo "Ошибка при запросе: ${ERROR_MESSAGE}"
    echo "${AUTH_EMAIL},N/A,N/A,${ERROR_MESSAGE}" >> "$REPORT_FILE"
    exit 1
fi

# Получение доменов
DOMAINS=$(echo "$RESPONSE" | jq -r '.result[].name')

if [ -z "$DOMAINS" ]; then
    echo "Не удалось получить домены для аккаунта ${AUTH_EMAIL}."
    echo "${AUTH_EMAIL},N/A,N/A,no domains in this CF account" >> "$REPORT_FILE"
    exit 1
fi

# Проверка статуса ECH для каждого домена
for DOMAIN in $DOMAINS; do
    echo "Проверка статуса ECH для домена: ${DOMAIN}"

    # Получение ID зоны для домена
    ZONE_ID=$(echo "$RESPONSE" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name == $DOMAIN) | .id')

    if [ -n "$ZONE_ID" ]; then
        echo "Найден zone_id для домена ${DOMAIN}: ${ZONE_ID}"

        # Получение статуса ECH
        ECH_STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
            -H "X-Auth-Email: ${AUTH_EMAIL}" \
            -H "X-Auth-Key: ${AUTH_KEY}" \
            -H "Content-Type: application/json" | jq -r '.result.value')

        echo "Статус ECH для домена ${DOMAIN}: ${ECH_STATUS}"

        # Запись в CSV файл
        echo "${AUTH_EMAIL},${DOMAIN},${ZONE_ID},${ECH_STATUS}" >> "$REPORT_FILE"
    else
        echo "zone_id для домена ${DOMAIN} не найден для аккаунта ${AUTH_EMAIL}"
        # Запись ошибки в CSV файл
        echo "${AUTH_EMAIL},${DOMAIN},N/A,error" >> "$REPORT_FILE"
    fi

    # Задержка между запросами
    sleep 0.3
done

echo "Отчёт о статусе ECH сохранён в файл ${REPORT_FILE}"
