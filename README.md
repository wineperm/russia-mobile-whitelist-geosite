# 📱 Russia Mobile Whitelist GeoSite

Автоматически обновляемый список российских мобильных сервисов в формате `geosite.dat` для **Xray**, **V2Ray**, **Passwall2**.



## 📋 Описание

Репозиторий ежедневно генерирует `geosite.dat` из списка мобильных whitelist-сервисов РФ:

| Файл | Формат | Назначение |
|------|--------|------------|
| `geosite.dat` | Бинарный Protobuf (V2Ray) | ⚡ Оптимальный для Xray / Passwall2 |
| `geosite.dat.sha256sum` | Контрольная сумма | Проверка целостности |
| `data/russia-mobile-whitelist` | Текстовый список | Читаемый формат |

### 🔗 Источник данных

- **Список**: [hxehex/russia-mobile-internet-whitelist](https://github.com/hxehex/russia-mobile-internet-whitelist) — whitelist для обхода ограничений мобильных операторов РФ
- **Компилятор**: [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)

### ✨ Особенности

- 🔄 Ежедневное обновление в 03:00 UTC
- 📬 Уведомления в Telegram
- ➕➖ Пользовательские списки `custom_allow.lst` / `custom_deny.lst`
- 🔤 Корректная обработка TLD (`.ru`, `.su`) → `regexp`-правила
- ✅ Совместимость с Xray, V2Ray, Passwall2



## 🚀 Быстрое использование

### Скачивание

```
https://github.com/wineperm/russia-mobile-whitelist-geosite/releases/latest/download/geosite.dat
```

### Использование в Passwall2

1. **Скачайте файл:**

```bash
wget -O /usr/share/xray/geosite-mobile-whitelist.dat \
  https://github.com/wineperm/russia-mobile-whitelist-geosite/releases/latest/download/geosite.dat
```

2. **Создайте правило маршрутизации** (Passwall2 → Node List → Add Node → Shunt Node):

| Приоритет | Rule Name | Match | Destination |
|-----------|-----------|-------|-------------|
| 1 | Mobile Whitelist | `geosite:russia-mobile-whitelist` | `_direct` |
| 2 | Russia Inside | `geosite:russia-inside` | `_direct` |
| 3 | China Direct | `geosite:cn`, `geoip:cn` | `_direct` |
| 4 | Proxy Blocked | `geosite:geolocation-!cn` | [ваш VLESS node] |
| 5 | Default | (fallback) | [ваш VLESS node] |

3. **Примените** Shunt Node в Global Settings
4. **Перезапустите**: `/etc/init.d/passwall2 restart`

> 💡 Мобильные сервисы РФ (Яндекс, Mail.ru, VK, Сбербанк, Госуслуги, Ozon) пойдут напрямую, заблокированные — через прокси.



## 📁 Структура репозитория

```
📦 russia-mobile-whitelist-geosite
├── 📄 README.md
├── 📄 LICENSE
├── 📄 .gitignore
├── 📁 .github/workflows/
│   └── 📄 build-geosite.yml
├── 📁 data/
│   └── 📄 russia-mobile-whitelist      # Автогенерация
├── 📁 scripts/
│   ├── 📄 fetch-and-convert.sh
│   └── 📄 apply-custom-lists.sh
├── 📄 custom_allow.lst                 # ➕ Домены для добавления
├── 📄 custom_deny.lst                  # ➖ Домены для исключения
└── 📄 .last_checksum
```

---

## ⚙️ Как это работает

1. **Ежедневно в 03:00 UTC** запускается GitHub Actions
2. Скачивается список из `hxehex/russia-mobile-internet-whitelist`
3. Конвертируется в формат `domain-list-community`:
   - Обычные домены → `domain:yandex.ru`
   - TLD (`.ru`, `.su`) → `regexp:\.ru$`
4. Применяются пользовательские правила из `custom_*.lst`
5. Компилируется `geosite.dat` через V2Fly
6. Создаётся Release и отправляется уведомление в Telegram

### 🔄 Триггеры запуска

```yaml
schedule:  cron: '0 3 * * *'    # Ежедневно в 03:00 UTC
push:      paths: data/**, custom_*.lst, scripts/**
workflow_dispatch:              # Ручной запуск
```

## 🛠️ Развёртывание своей копии

1. **Форкните** репозиторий
2. **Настройте секреты** (Settings → Secrets → Actions):
   - `TELEGRAM_BOT_TOKEN` — от @BotFather
   - `TELEGRAM_CHAT_ID` — от @getidsbot
3. **Проверьте** в workflow наличие:
   ```yaml
   permissions:
     contents: write
   ```
4. **Запустите** вручную: Actions → Build GeoSite Database → Run workflow
5. **Готово!** `geosite.dat` появится в Releases

## 🔧 Локальное тестирование

```bash
git clone https://github.com/wineperm/russia-mobile-whitelist-geosite.git
cd russia-mobile-whitelist-geosite
git clone https://github.com/v2fly/domain-list-community.git dlc
cd dlc && go mod download && cd ..
chmod +x scripts/*.sh
./scripts/fetch-and-convert.sh
./scripts/apply-custom-lists.sh
cd dlc && go run ./ --datapath=../data && mv dlc.dat ../geosite.dat
sha256sum ../geosite.dat
```

## 🔄 Автообновление на роутере

Создайте `/root/update-geosite-mobile.sh`:

```bash
#!/bin/sh
GEOSITE_PATH="/usr/share/xray/geosite-mobile-whitelist.dat"
GEOSITE_URL="https://github.com/wineperm/russia-mobile-whitelist-geosite/releases/latest/download/geosite.dat"

wget -q -O "$GEOSITE_PATH.tmp" "$GEOSITE_URL" && \
  mv "$GEOSITE_PATH.tmp" "$GEOSITE_PATH" && \
  /etc/init.d/passwall2 restart
```

Добавьте в cron (`crontab -e`):

```bash
30 4 * * * /root/update-geosite-mobile.sh >> /var/log/geosite-mobile.log 2>&1
```

## ❓ FAQ

**Почему geosite.dat бинарный?**
Формат Protobuf обеспечивает максимальную производительность Xray. Используйте `data/russia-mobile-whitelist` для просмотра содержимого.

**Как постоянно добавить/исключить домены?**
Отредактируйте `custom_allow.lst` или `custom_deny.lst` — по одному домену на строку. После пуша автоматически пересоберётся `geosite.dat`.

**Чем отличается от `russia-inside`?**
- `russia-inside` — все российские домены (включая заблокированные)
- `russia-mobile-whitelist` — только мобильные сервисы, гарантированно работающие без прокси (Яндекс, Mail.ru, VK, Сбербанк, Госуслуги, Ozon, Wildberries и т.д.)

**Можно ли использовать в других клиентах?**
- ✅ Xray / V2Ray / Passwall2 — нативно
- ⚠️ sing-box / Podkop — требуется формат `.srs` (используйте [wineperm/whitelist](https://github.com/wineperm/whitelist))

## 📜 Лицензия

MIT. Исходные данные: [hxehex/russia-mobile-internet-whitelist](https://github.com/hxehex/russia-mobile-internet-whitelist).

## ⚠️ Отказ от ответственности

Проект предоставляется «как есть», без гарантий. Автор не несёт ответственности за возможные проблемы с маршрутизацией.

> ⭐ Понравился проект? Поставьте звезду — это помогает другим найти репозиторий!
