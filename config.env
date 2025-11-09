#!/bin/bash
# Preseed Builder - Сборщик конфигураций

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_CFG="${SCRIPT_DIR}/base.cfg"
MODULES_DIR="${SCRIPT_DIR}/modules"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Создать директорию вывода
mkdir -p "$OUTPUT_DIR"

# Функция сборки
build_preseed() {
    local recipe_name="$1"
    shift
    local modules=("$@")
    
    echo -e "${GREEN}🔨 Сборка: ${recipe_name}${NC}"
    
    local output_file="${OUTPUT_DIR}/${recipe_name}.cfg"
    
    # Начать с базового шаблона
    cat "$BASE_CFG" > "$output_file"
    
    # Добавить модули
    for module in "${modules[@]}"; do
        local module_file="${MODULES_DIR}/${module}.cfg"
        if [ -f "$module_file" ]; then
            echo -e "${YELLOW}  + ${module}${NC}"
            echo "" >> "$output_file"
            echo "### MODULE: ${module}" >> "$output_file"
            cat "$module_file" >> "$output_file"
        else
            echo -e "${RED}  ✗ Модуль не найден: ${module}${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}  ✓ Создан: ${output_file}${NC}"
}

# Функция замены плейсхолдеров
replace_placeholders() {
    local file="$1"
    local config_file="$2"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}⚠️  Файл конфигурации не найден: ${config_file}${NC}"
        return
    fi
    
    echo -e "${GREEN}🔄 Замена плейсхолдеров...${NC}"
    
    while IFS='=' read -r key value; do
        # Пропустить комментарии и пустые строки
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Удалить пробелы
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Заменить в файле
        sed -i "s|{{${key}}}|${value}|g" "$file"
        echo -e "  ${key} = ${value}"
    done < "$config_file"
}

# Главное меню
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Preseed Configuration Builder        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Доступные рецепты:"
    echo "  1) VPN Server (WireGuard + Security)"
    echo "  2) Dev Server (Docker + Monitoring)"
    echo "  3) Minimal (только base)"
    echo "  4) Custom (выбрать модули)"
    echo "  5) Список модулей"
    echo "  0) Выход"
    echo ""
}

# Список модулей
list_modules() {
    echo -e "${GREEN}📦 Доступные модули:${NC}"
    for module in "${MODULES_DIR}"/*.cfg; do
        local name=$(basename "$module" .cfg)
        echo "  • $name"
    done
}

# Интерактивный режим
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                build_preseed "vpn-server" "network-static" "vpn-wireguard" "security-hardened"
                ;;
            2)
                build_preseed "dev-server" "docker" "monitoring"
                ;;
            3)
                cp "$BASE_CFG" "${OUTPUT_DIR}/minimal.cfg"
                echo -e "${GREEN}✓ Создан: minimal.cfg${NC}"
                ;;
            4)
                list_modules
                read -p "Введите имя рецепта: " recipe_name
                read -p "Введите модули через пробел: " -a custom_modules
                build_preseed "$recipe_name" "${custom_modules[@]}"
                ;;
            5)
                list_modules
                ;;
            0)
                echo "Выход"
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный выбор${NC}"
                ;;
        esac
        
        read -p "Нажмите Enter для продолжения..."
    done
fi

# CLI режим
if [ "$1" == "build" ]; then
    recipe_name="$2"
    shift 2
    build_preseed "$recipe_name" "$@"
elif [ "$1" == "replace" ]; then
    replace_placeholders "$2" "$3"
else
    echo "Использование:"
    echo "  $0                              # Интерактивный режим"
    echo "  $0 build <name> <module1> ...   # Собрать рецепт"
    echo "  $0 replace <file> <config>      # Заменить плейсхолдеры"
fi
