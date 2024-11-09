#!/bin/bash

# Запрос email и API ключа
read -p "Введите ваш email для Cloudflare: " AUTH_EMAIL
read -sp "Введите ваш API ключ для Cloudflare: " AUTH_KEY
echo

# Проверка на ввод данных
if [ -z "$AUTH_EMAIL" ] || [ -z "$AUTH_KEY" ]; then
    echo "Ошибка: email и/или API ключ не были введены."
    exit 1
fi

# Папка для отчетов
REPORT_DIR="./reports"

# Создание папки, если она не существует
mkdir -p "$REPORT_DIR"

# Output report file
REPORT_FILE="${REPORT_DIR}/ech_report_${AUTH_EMAIL}.csv"

# CSV header
echo "email,domain,zone_id,ech_status" > "$REPORT_FILE"

echo "Обработка аккаунта с email: ${AUTH_EMAIL}"

# Получение всех доменов для аккаунта
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

DOMAINS=$(echo "$RESPONSE" | jq -r '.result[].name')

if [ -z "$DOMAINS" ]; then
    echo "Не удалось получить домены для аккаунта ${AUTH_EMAIL}."
    # Запись в отчет, что нет доменов
    echo "${AUTH_EMAIL},N/A,N/A,no domains in this CF account" >> "$REPORT_FILE"
    exit 1
fi

# Обработка доменов
for DOMAIN in $DOMAINS; do
    echo "Обработка домена: ${DOMAIN}"

    # Получение ID зоны для домена
    ZONE_ID=$(echo "$RESPONSE" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name == $DOMAIN) | .id')

    if [ -n "$ZONE_ID" ]; then
        echo "Найден zone_id для домена ${DOMAIN}: ${ZONE_ID}"

        # Отключение ECH
        curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
            -H "X-Auth-Email: ${AUTH_EMAIL}" \
            -H "X-Auth-Key: ${AUTH_KEY}" \
            -H "Content-Type: application/json" \
            --data '{"id":"ech","value":"off"}'

        echo "ECH отключен для zone_id=${ZONE_ID} в аккаунте ${AUTH_EMAIL}"

        # Проверка статуса ECH
        ECH_STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
            -H "X-Auth-Email: ${AUTH_EMAIL}" \
            -H "X-Auth-Key: ${AUTH_KEY}" \
            -H "Content-Type: application/json" | jq -r '.result.value')

        if [ "$ECH_STATUS" == "off" ]; then
            echo "ECH успешно отключен для zone_id=${ZONE_ID}."
            STATUS="off"
        else
            echo "Ошибка: ECH не отключен для zone_id=${ZONE_ID}."
            STATUS="error"
        fi

        # Запись в CSV файл
        echo "${AUTH_EMAIL},${DOMAIN},${ZONE_ID},${STATUS}" >> "$REPORT_FILE"
    else
        echo "zone_id для домена ${DOMAIN} не найден для аккаунта ${AUTH_EMAIL}"
        # Запись ошибки в CSV файл
        echo "${AUTH_EMAIL},${DOMAIN},N/A,error" >> "$REPORT_FILE"
    fi

    # Задержка между запросами, чтобы не превышать лимиты
    sleep 0.3
done

echo "Отчёт о статусе ECH сохранён в файл ${REPORT_FILE}"
