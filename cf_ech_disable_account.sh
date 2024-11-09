#!/bin/bash

cd "$(dirname "$0")"

REPORTS_DIR="./reports"

mkdir -p "$REPORTS_DIR"

# Запрос email и API ключа у пользователя
read -p "Введите email для Cloudflare: " AUTH_EMAIL
read -sp "Введите API ключ для Cloudflare: " AUTH_KEY
echo

# Проверка на пустые значения
if [ -z "$AUTH_EMAIL" ] || [ -z "$AUTH_KEY" ]; then
    echo "Ошибка: email или API ключ пустой."
    exit 1
fi

echo "Обработка аккаунта с email: ${AUTH_EMAIL}"

REPORT_FILE="${REPORTS_DIR}/ech_report_${AUTH_EMAIL}.csv"
echo "email,domain,zone_id,ech_status" > "$REPORT_FILE"

# Получаем список зон из Cloudflare
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
    -H "X-Auth-Email: ${AUTH_EMAIL}" \
    -H "X-Auth-Key: ${AUTH_KEY}" \
    -H "Content-Type: application/json")

ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errors[0].code')
ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.errors[0].message')

if [ "$ERROR_CODE" != "null" ]; then
    echo "Ошибка при запросе для аккаунта ${AUTH_EMAIL}: ${ERROR_MESSAGE}"
    echo "${AUTH_EMAIL},N/A,N/A,${ERROR_MESSAGE}" >> "$REPORT_FILE"
    exit 1
fi

DOMAINS=$(echo "$RESPONSE" | jq -r '.result[].name')

if [ -z "$DOMAINS" ]; then
    echo "Не удалось получить домены для аккаунта ${AUTH_EMAIL}."
    echo "${AUTH_EMAIL},N/A,N/A,No domains in this CF account" >> "$REPORT_FILE"
    exit 1
fi

# Для каждого домена проверяем ECH статус и отключаем его, если включен
for DOMAIN in $DOMAINS; do
    echo "Проверка домена: ${DOMAIN}"

    ZONE_ID=$(echo "$RESPONSE" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name == $DOMAIN) | .id')

    if [ -n "$ZONE_ID" ]; then
        ECH_STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
            -H "X-Auth-Email: ${AUTH_EMAIL}" \
            -H "X-Auth-Key: ${AUTH_KEY}" \
            -H "Content-Type: application/json" | jq -r '.result.value')

        echo "ECH статус для домена ${DOMAIN}: ${ECH_STATUS}"

        # Если ECH включен, отключаем его
        if [ "$ECH_STATUS" == "on" ]; then
            echo "Отключение ECH для домена ${DOMAIN}..."
            DISABLE_ECH=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
                -H "X-Auth-Email: ${AUTH_EMAIL}" \
                -H "X-Auth-Key: ${AUTH_KEY}" \
                -H "Content-Type: application/json" \
                --data '{"value":"off"}')

            # Проверка успешности отключения
            ECH_NEW_STATUS=$(echo "$DISABLE_ECH" | jq -r '.result.value')
            if [ "$ECH_NEW_STATUS" == "off" ]; then
                echo "ECH успешно отключен для домена ${DOMAIN}"
                ECH_STATUS="off"
            else
                echo "Не удалось отключить ECH для домена ${DOMAIN}"
            fi
        fi

        # Записываем актуальный статус в отчет
        echo "${AUTH_EMAIL},${DOMAIN},${ZONE_ID},${ECH_STATUS}" >> "$REPORT_FILE"
    else
        echo "zone_id для домена ${DOMAIN} не найден"
        echo "${AUTH_EMAIL},${DOMAIN},N/A,error" >> "$REPORT_FILE"
    fi

    sleep 0.3
done

echo "Отчет для ${AUTH_EMAIL} сохранен в файл ${REPORT_FILE}"

echo "Обработка завершена."
