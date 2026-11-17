#!/bin/bash
set -e

echo "🔄 Загрузка списка доменов из hxehex/russia-mobile-internet-whitelist..."
mkdir -p data

curl -fsSL -o data/russia-mobile-whitelist.raw \
  "https://raw.githubusercontent.com/hxehex/russia-mobile-internet-whitelist/main/whitelist.txt"

if [ ! -s data/russia-mobile-whitelist.raw ]; then
  echo "❌ Ошибка: не удалось загрузить список доменов (пустой файл или 404)"
  exit 1
fi

loaded=$(wc -l < data/russia-mobile-whitelist.raw)
echo "📊 Загружено строк: $loaded"

echo "🔄 Конвертация в формат domain-list-community..."

# Регулярные выражения для валидации
VALID_DOMAIN_REGEX='^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$'
TLD_REGEX='^\.[a-zA-Z0-9.-]+$'

skipped=0
converted=0

{
  echo "# Russia Mobile Whitelist domains"
  echo "# Source: https://github.com/hxehex/russia-mobile-internet-whitelist"
  echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo ""

  while IFS= read -r domain || [ -n "$domain" ]; do
    # Пропустить пустые строки и комментарии
    [[ -z "${domain// }" || "$domain" =~ ^[[:space:]]*# ]] && continue

    # Очистка: убрать \r, пробелы, привести к нижнему регистру
    domain=$(printf '%s' "$domain" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')
    
    [[ -z "$domain" ]] && continue

    # Сценарий А: Строка уже размечена
    if [[ "$domain" =~ ^(domain:|full:|keyword:|regexp:|include:) ]]; then
      echo "$domain"
      converted=$((converted + 1))
      continue
    fi

    # Сценарий Б: Это доменная зона (начинается с точки)
    if [[ "$domain" =~ $TLD_REGEX ]]; then
      clean_tld="${domain#.}"
      escaped_tld=$(echo "$clean_tld" | sed 's/\./\\./g')
      echo "regexp:\\.${escaped_tld}\$"
      converted=$((converted + 1))
      continue
    fi

    # Сценарий В: Обычный валидный домен
    if [[ "$domain" =~ $VALID_DOMAIN_REGEX ]]; then
      echo "domain:$domain"
      converted=$((converted + 1))
    else
      skipped=$((skipped + 1))
    fi
  done < data/russia-mobile-whitelist.raw
} > data/russia-mobile-whitelist

rm -f data/russia-mobile-whitelist.raw

echo "✅ Конвертировано правил: $converted"
echo "⚠️ Пропущено невалидных строк (мусор): $skipped"
