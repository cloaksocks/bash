#!/bin/bash

cd "$(dirname "$0")"

REPORTS_DIR="./reports"
CREDENTIALS_FILE="./cf_creds.csv"

mkdir -p "$REPORTS_DIR"

if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "Файл cf_creds.csv не найден! Убедитесь, что файл с учетными данными существует."
    exit 1
fi

while IFS=',' read -r AUTH_EMAIL AUTH_KEY; do
    # Убираем пробелы и проверяем данные
    AUTH_EMAIL=$(echo "$AUTH_EMAIL" | xargs)
    AUTH_KEY=$(echo "$AUTH_KEY" | xargs)

    if [ -z "$AUTH_EMAIL" ] || [ -z "$AUTH_KEY" ]; then
        echo "Пропущена строка с некорректными данными (email или API ключ пустой)"
        continue
    fi

    echo "Обработка аккаунта с email: ${AUTH_EMAIL}"

    REPORT_FILE="${REPORTS_DIR}/ech_report_${AUTH_EMAIL}.csv"
    echo "email,domain,zone_id,ech_status" > "$REPORT_FILE"

    RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
        -H "X-Auth-Email: ${AUTH_EMAIL}" \
        -H "X-Auth-Key: ${AUTH_KEY}" \
        -H "Content-Type: application/json")

    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errors[0].code')
    ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.errors[0].message')

    if [ "$ERROR_CODE" != "null" ]; then
        echo "Ошибка при запросе для аккаунта ${AUTH_EMAIL}: ${ERROR_MESSAGE}"
        echo "${AUTH_EMAIL},N/A,N/A,${ERROR_MESSAGE}" >> "$REPORT_FILE"
        continue
    fi

    DOMAINS=$(echo "$RESPONSE" | jq -r '.result[].name')

    if [ -z "$DOMAINS" ]; then
        echo "Не удалось получить домены для аккаунта ${AUTH_EMAIL}."
        echo "${AUTH_EMAIL},N/A,N/A,No domains in this CF account" >> "$REPORT_FILE"
        continue
    fi

    for DOMAIN in $DOMAINS; do
        echo "Проверка домена: ${DOMAIN}"

        ZONE_ID=$(echo "$RESPONSE" | jq -r --arg DOMAIN "$DOMAIN" '.result[] | select(.name == $DOMAIN) | .id')

        if [ -n "$ZONE_ID" ]; then
            ECH_STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
                -H "X-Auth-Email: ${AUTH_EMAIL}" \
                -H "X-Auth-Key: ${AUTH_KEY}" \
                -H "Content-Type: application/json" | jq -r '.result.value')

            echo "ECH статус для домена ${DOMAIN}: ${ECH_STATUS}"
            echo "${AUTH_EMAIL},${DOMAIN},${ZONE_ID},${ECH_STATUS}" >> "$REPORT_FILE"

            # Если ECH включен, отключаем его
            if [ "$ECH_STATUS" == "on" ]; then
                echo "Отключение ECH для домена ${DOMAIN}"
                curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/ech" \
                    -H "X-Auth-Email: ${AUTH_EMAIL}" \
                    -H "X-Auth-Key: ${AUTH_KEY}" \
                    -H "Content-Type: application/json" \
                    --data '{"id":"ech","value":"off"}' > /dev/null
                echo "ECH отключен для домена ${DOMAIN}"
            fi
        else
            echo "zone_id для домена ${DOMAIN} не найден"
            echo "${AUTH_EMAIL},${DOMAIN},N/A,error" >> "$REPORT_FILE"
        fi

        sleep 0.3
    done

    echo "Отчет для ${AUTH_EMAIL} сохранен в файл ${REPORT_FILE}"

done < "$CREDENTIALS_FILE"

echo "Обработка завершена для всех аккаунтов."
