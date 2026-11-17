#!/bin/bash
set -e

echo "🔧 Применение пользовательских списков..."

DOMAINS_FILE="data/russia-mobile-whitelist"

# Обработать custom_deny.lst (исключения)
if [ -f custom_deny.lst ] && [ -s custom_deny.lst ]; then
  echo "➖ Применение исключений из custom_deny.lst..."
  
  cp "$DOMAINS_FILE" "${DOMAINS_FILE}.tmp"
  
  while IFS= read -r deny_domain; do
    [[ -z "$deny_domain" || "$deny_domain" =~ ^# ]] && continue
    deny_domain=$(echo "$deny_domain" | xargs)
    
    grep -v "^domain:$deny_domain$" "${DOMAINS_FILE}.tmp" > "${DOMAINS_FILE}.tmp2" || true
    mv "${DOMAINS_FILE}.tmp2" "${DOMAINS_FILE}.tmp"
    
    echo "  Удалён: $deny_domain"
  done < custom_deny.lst
  
  mv "${DOMAINS_FILE}.tmp" "$DOMAINS_FILE"
fi

# Обработать custom_allow.lst (добавления)
if [ -f custom_allow.lst ] && [ -s custom_allow.lst ]; then
  echo "➕ Применение добавлений из custom_allow.lst..."
  
  while IFS= read -r allow_domain; do
    [[ -z "$allow_domain" || "$allow_domain" =~ ^# ]] && continue
    allow_domain=$(echo "$allow_domain" | xargs)
    
    if ! grep -q "^domain:$allow_domain$" "$DOMAINS_FILE"; then
      echo "domain:$allow_domain" >> "$DOMAINS_FILE"
      echo "  Добавлен: $allow_domain"
    fi
  done < custom_allow.lst
fi

# Сортировать и удалить дубликаты
sort -u "$DOMAINS_FILE" > "${DOMAINS_FILE}.sorted"
mv "${DOMAINS_FILE}.sorted" "$DOMAINS_FILE"

echo "✅ Пользовательские списки применены"
