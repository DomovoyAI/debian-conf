
# Создаём скрипт для автоматического встраивания preseed в ISO

build_script = """#!/bin/bash
# Скрипт встраивания preseed.cfg в Debian ISO
# Версия: 1.0 (Тестовая)

set -e

# Цвета для вывода
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log "Проверка зависимостей..."
    
    local deps=("xorriso" "isolinux" "wget")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Не установлены: ${missing[*]}\\nУстановите: sudo apt install xorriso isolinux syslinux-utils wget"
    fi
    
    log "✓ Все зависимости установлены"
}

# Скачивание ISO
download_iso() {
    local iso_url="$1"
    local iso_file="$2"
    
    if [ -f "$iso_file" ]; then
        warning "ISO уже существует: $iso_file"
        read -p "Скачать заново? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    log "Скачивание ISO..."
    wget -O "$iso_file" "$iso_url" || error "Ошибка скачивания ISO"
    log "✓ ISO скачан: $iso_file"
}

# Распаковка ISO
extract_iso() {
    local iso_file="$1"
    local extract_dir="$2"
    
    log "Распаковка ISO..."
    
    # Удалить старую директорию
    [ -d "$extract_dir" ] && rm -rf "$extract_dir"
    
    # Создать директорию
    mkdir -p "$extract_dir"
    
    # Распаковать ISO
    xorriso -osirrox on -indev "$iso_file" -extract / "$extract_dir" 2>/dev/null || error "Ошибка распаковки ISO"
    
    # Сделать файлы записываемыми
    chmod -R u+w "$extract_dir"
    
    log "✓ ISO распакован в: $extract_dir"
}

# Встраивание preseed
embed_preseed() {
    local preseed_file="$1"
    local extract_dir="$2"
    
    log "Встраивание preseed.cfg..."
    
    # Проверка preseed файла
    [ ! -f "$preseed_file" ] && error "Файл preseed не найден: $preseed_file"
    
    # Копировать preseed в корень ISO
    cp "$preseed_file" "$extract_dir/preseed.cfg"
    
    # Модифицировать isolinux.cfg для автозагрузки
    local isolinux_cfg="$extract_dir/isolinux/isolinux.cfg"
    local txt_cfg="$extract_dir/isolinux/txt.cfg"
    
    if [ -f "$txt_cfg" ]; then
        log "Модификация txt.cfg..."
        
        # Создать резервную копию
        cp "$txt_cfg" "$txt_cfg.bak"
        
        # Добавить автоматический пункт меню
        cat > "$txt_cfg" << 'EOF'
default auto
label auto
    menu label ^Automatic Install (Preseed)
    kernel /install.amd/vmlinuz
    append auto=true priority=critical vga=788 initrd=/install.amd/initrd.gz preseed/file=/cdrom/preseed.cfg --- quiet

label install
    menu label ^Install
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/initrd.gz --- quiet

label installgui
    menu label ^Graphical install
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/gtk/initrd.gz --- quiet
EOF
        
        log "✓ txt.cfg модифицирован"
    else
        warning "txt.cfg не найден, пропускаем модификацию"
    fi
    
    # Уменьшить таймаут загрузки
    if [ -f "$isolinux_cfg" ]; then
        sed -i 's/^timeout.*/timeout 10/' "$isolinux_cfg"
        log "✓ Таймаут загрузки установлен на 1 секунду"
    fi
    
    log "✓ Preseed встроен"
}

# Создание нового ISO
create_iso() {
    local extract_dir="$1"
    local output_iso="$2"
    
    log "Создание нового ISO..."
    
    # Удалить старый ISO
    [ -f "$output_iso" ] && rm -f "$output_iso"
    
    # Создать ISO
    xorriso -as mkisofs \\
        -r -V "Debian 12 Preseed" \\
        -o "$output_iso" \\
        -J -joliet-long \\
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \\
        -c isolinux/boot.cat \\
        -b isolinux/isolinux.bin \\
        -no-emul-boot \\
        -boot-load-size 4 \\
        -boot-info-table \\
        -eltorito-alt-boot \\
        -e boot/grub/efi.img \\
        -no-emul-boot \\
        -isohybrid-gpt-basdat \\
        "$extract_dir" 2>&1 | grep -v "xorriso : UPDATE" || error "Ошибка создания ISO"
    
    log "✓ ISO создан: $output_iso"
    log "📊 Размер: $(du -h "$output_iso" | cut -f1)"
}

# Очистка временных файлов
cleanup() {
    local extract_dir="$1"
    
    log "Очистка временных файлов..."
    [ -d "$extract_dir" ] && rm -rf "$extract_dir"
    log "✓ Очистка завершена"
}

# Главная функция
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Debian Preseed ISO Builder                       ║"
    echo "║   Автоматическое встраивание preseed.cfg           ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    # Конфигурация
    ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"
    ISO_FILE="debian-12.8.0-amd64-netinst.iso"
    PRESEED_FILE="preseed-minimal.cfg"
    EXTRACT_DIR="iso-extract"
    OUTPUT_ISO="debian-12-preseed-auto.iso"
    
    # Проверка аргументов
    if [ $# -ge 1 ]; then
        PRESEED_FILE="$1"
    fi
    
    if [ $# -ge 2 ]; then
        OUTPUT_ISO="$2"
    fi
    
    log "Конфигурация:"
    echo "  • Preseed: $PRESEED_FILE"
    echo "  • Output ISO: $OUTPUT_ISO"
    echo ""
    
    # Выполнение
    check_dependencies
    download_iso "$ISO_URL" "$ISO_FILE"
    extract_iso "$ISO_FILE" "$EXTRACT_DIR"
    embed_preseed "$PRESEED_FILE" "$EXTRACT_DIR"
    create_iso "$EXTRACT_DIR" "$OUTPUT_ISO"
    cleanup "$EXTRACT_DIR"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✓ УСПЕШНО ЗАВЕРШЕНО                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "📀 Готовый ISO: $OUTPUT_ISO"
    echo ""
    echo "🚀 Следующие шаги:"
    echo "  1. Запишите ISO на USB: sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
    echo "  2. Или используйте в виртуальной машине"
    echo "  3. Загрузитесь с ISO и выберите 'Automatic Install'"
    echo ""
    echo "🔐 Тестовые данные для входа:"
    echo "  Пользователь: testuser"
    echo "  Пароль: test123"
    echo ""
}

# Запуск
main "$@"
"""

# Сохраняем скрипт
with open('/home/user/build-preseed-iso.sh', 'w') as f:
    f.write(build_script)

print("✅ Создан скрипт: build-preseed-iso.sh")
print("\n" + "="*60)
print("📋 ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ:")
print("="*60)
print("""
1️⃣  УСТАНОВКА ЗАВИСИМОСТЕЙ:
   sudo apt update
   sudo apt install xorriso isolinux syslinux-utils wget

2️⃣  ЗАПУСК СКРИПТА:
   chmod +x build-preseed-iso.sh
   ./build-preseed-iso.sh

3️⃣  ТЕСТИРОВАНИЕ В VIRTUALBOX:
   - Создать новую VM (Debian 64-bit, 2GB RAM, 20GB disk)
   - Подключить созданный ISO
   - Запустить и выбрать "Automatic Install"
   - Установка пройдёт БЕЗ ВОПРОСОВ

4️⃣  ЗАПИСЬ НА USB (опционально):
   sudo dd if=debian-12-preseed-auto.iso of=/dev/sdX bs=4M status=progress
   (замените /dev/sdX на ваше устройство, например /dev/sdb)

⚠️  ВАЖНО: Тестовые данные!
   Пользователь: testuser
   Пароль: test123
   
   После теста ОБЯЗАТЕЛЬНО поменяйте пароль!
""")

# Создаём также краткую шпаргалку
cheatsheet = """# ШПАРГАЛКА: Встраивание Preseed в ISO

## Быстрый старт (3 команды):
```bash
sudo apt install xorriso isolinux syslinux-utils wget
chmod +x build-preseed-iso.sh
./build-preseed-iso.sh
```

## Структура файлов:
```
project/
├── preseed-minimal.cfg          # Конфигурация установки
├── build-preseed-iso.sh         # Скрипт сборки
├── debian-12.8.0-amd64-netinst.iso  # Оригинальный ISO (скачается)
└── debian-12-preseed-auto.iso   # Готовый ISO (создастся)
```

## Что делает скрипт:
1. ✓ Проверяет зависимости
2. ✓ Скачивает Debian 12 netinst ISO
3. ✓ Распаковывает ISO
4. ✓ Встраивает preseed.cfg
5. ✓ Модифицирует меню загрузки (добавляет "Automatic Install")
6. ✓ Создаёт новый ISO
7. ✓ Очищает временные файлы

## Параметры загрузки:
- `auto=true` - автоматический режим
- `priority=critical` - задавать только критические вопросы
- `preseed/file=/cdrom/preseed.cfg` - путь к preseed

## Тестирование в VirtualBox:
1. Создать VM: Type=Linux, Version=Debian (64-bit)
2. RAM: 2048 MB (минимум 1024)
3. Disk: 20 GB (минимум 10 GB)
4. Storage: подключить debian-12-preseed-auto.iso
5. Start → выбрать "Automatic Install (Preseed)"
6. Ждать ~10-15 минут

## Кастомизация:
Отредактируйте preseed-minimal.cfg:
- Hostname: `d-i netcfg/get_hostname string YOUR_NAME`
- Timezone: `d-i time/zone string Europe/Moscow`
- Пакеты: `d-i pkgsel/include string vim git docker.io`

## Проверка preseed синтаксиса:
```bash
debconf-set-selections -c preseed-minimal.cfg
```

## Отладка:
Во время установки нажмите Alt+F4 для просмотра логов
"""

with open('/home/user/CHEATSHEET.md', 'w') as f:
    f.write(cheatsheet)

print("\n✅ Создана шпаргалка: CHEATSHEET.md")
print("\n📦 Все файлы готовы для использования!")
