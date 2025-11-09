#!/bin/bash
# preseed-validator.sh

echo "🔍 Проверка preseed.cfg..."

# Проверка существования файла
if [ ! -f "preseed.cfg" ]; then
    echo "❌ Файл preseed.cfg не найден!"
    exit 1
fi

# Проверка базового синтаксиса
echo "✅ Файл найден"

# Проверка обязательных параметров
required_params=(
    "debian-installer/locale"
    "keyboard-configuration/xkb-keymap"
    "netcfg/choose_interface"
    "passwd/username"
    "partman-auto/method"
    "grub-installer/only_debian"
)

missing=0
for param in "${required_params[@]}"; do
    if ! grep -q "$param" preseed.cfg; then
        echo "⚠️  Отсутствует: $param"
        missing=$((missing + 1))
    fi
done

if [ $missing -eq 0 ]; then
    echo "✅ Все обязательные параметры присутствуют"
else
    echo "❌ Найдено $missing отсутствующих параметров"
fi

# Проверка на типичные ошибки
echo ""
echo "🔍 Проверка типичных ошибок..."

# Проверка на дублирующиеся параметры
duplicates=$(grep -v '^#' preseed.cfg | grep -v '^$' | awk '{print $1" "$2}' | sort | uniq -d)
if [ -n "$duplicates" ]; then
    echo "⚠️  Найдены дублирующиеся параметры:"
    echo "$duplicates"
else
    echo "✅ Дублирующихся параметров не найдено"
fi

# Проверка паролей
if grep -q "password changeme" preseed.cfg; then
    echo "⚠️  Используется пароль по умолчанию 'changeme'"
fi

echo ""
echo "✅ Базовая проверка завершена"
