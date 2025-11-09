
readme = """# 🚀 Debian Preseed ISO Builder

**Автоматизированная сборка ISO с предустановленной конфигурацией**

> Проект для создания полностью автоматической установки Debian 12 без интерактивных вопросов

---

## 📦 Что это?

Этот проект позволяет встроить файл `preseed.cfg` в Debian ISO, чтобы установка проходила **полностью автоматически**:
- ✅ Без вопросов о языке, раскладке, часовом поясе
- ✅ Автоматическое разбиение диска
- ✅ Создание пользователя и установка пароля
- ✅ Установка базовых пакетов

---

## 🎯 Для кого это?

- **DevOps-инженеры**: быстрое развёртывание тестовых окружений
- **Системные администраторы**: массовая установка серверов
- **Разработчики**: создание идентичных dev-окружений
- **Студенты**: изучение автоматизации установки Linux

---

## 📋 Требования

### Система
- **OS**: Debian/Ubuntu Linux (или WSL2)
- **RAM**: 2 GB свободной (для сборки)
- **Disk**: 5 GB свободного места

### Зависимости
```bash
sudo apt update
sudo apt install -y \\
    xorriso \\
    isolinux \\
    syslinux-utils \\
    wget
```

---

## 🚀 Быстрый старт (3 шага)

### 1. Клонировать репозиторий
```bash
git clone https://github.com/yourusername/debian-preseed-iso.git
cd debian-preseed-iso
```

### 2. Запустить сборку
```bash
chmod +x build-preseed-iso.sh
./build-preseed-iso.sh
```

### 3. Тестировать
```bash
# В VirtualBox или записать на USB
sudo dd if=debian-12-preseed-auto.iso of=/dev/sdX bs=4M status=progress
```

**Готово!** ISO создан за ~5-10 минут.

---

## 📂 Структура проекта

```
debian-preseed-iso/
├── preseed-minimal.cfg          # Конфигурация установки
├── build-preseed-iso.sh         # Скрипт автоматизации
├── CHEATSHEET.md                # Шпаргалка команд
├── README.md                    # Документация (этот файл)
└── debian-12-preseed-auto.iso   # Готовый ISO (после сборки)
```

---

## ⚙️ Как это работает?

```
┌─────────────────────┐
│  preseed.cfg        │  Конфигурация установки
│  build-preseed.sh   │  Скрипт сборки
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  1. Скачать ISO     │  Debian 12 netinst (~400 MB)
│  2. Распаковать     │  Извлечь файлы ISO
│  3. Встроить cfg    │  Копировать preseed.cfg
│  4. Модифицировать  │  Изменить меню загрузки
│  5. Пересобрать     │  Создать новый ISO
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  debian-12-preseed  │  Готовый ISO (~420 MB)
│  -auto.iso          │
└─────────────────────┘
```

---

## 🧪 Тестирование

### В VirtualBox

1. **Создать новую VM**:
   - Name: Debian-Preseed-Test
   - Type: Linux
   - Version: Debian (64-bit)
   - RAM: 2048 MB
   - Disk: 20 GB (VDI, динамический)

2. **Настроить**:
   - Storage → Controller: IDE → Добавить `debian-12-preseed-auto.iso`
   - Network → Adapter 1 → NAT

3. **Запустить**:
   - Start VM
   - Выбрать: **"Automatic Install (Preseed)"**
   - Ждать ~10-15 минут

4. **Войти**:
   ```
   Username: testuser
   Password: test123
   ```

### На реальном железе

```bash
# 1. Найти USB-устройство
lsblk

# 2. Записать ISO (ВНИМАНИЕ: все данные будут удалены!)
sudo dd if=debian-12-preseed-auto.iso of=/dev/sdX bs=4M status=progress && sync

# 3. Загрузиться с USB
# 4. Выбрать "Automatic Install (Preseed)"
```

---

## 🔧 Кастомизация

### Изменить hostname
```bash
# В preseed-minimal.cfg
d-i netcfg/get_hostname string MY-SERVER
```

### Изменить часовой пояс
```bash
d-i time/zone string America/New_York
```

### Добавить пакеты
```bash
d-i pkgsel/include string vim git curl docker.io htop
```

### Изменить пользователя
```bash
d-i passwd/user-fullname string John Doe
d-i passwd/username string john
d-i passwd/user-password-crypted password $6$rounds=656000$...
```

**Генерация хеша пароля**:
```bash
mkpasswd -m sha-512 -S $(pwgen -ns 16 1) -R 656000
```

---

## 🐛 Отладка

### Просмотр логов во время установки

Во время установки нажмите:
- **Alt + F2**: Shell
- **Alt + F3**: Лог установки
- **Alt + F4**: Системные сообщения
- **Alt + F1**: Вернуться к установщику

### Проверка синтаксиса preseed

```bash
# Установить debconf-utils
sudo apt install debconf-utils

# Проверить синтаксис
debconf-set-selections -c preseed-minimal.cfg
```

### Тестирование preseed без ISO

```bash
# Запустить установку с preseed по сети
# В параметрах загрузки добавить:
auto=true priority=critical url=http://example.com/preseed.cfg
```

---

## 📊 Сравнение методов установки

| Метод | Время | Вопросы | Повторяемость |
|-------|-------|---------|---------------|
| Обычная установка | 30+ мин | ~20 | ❌ Низкая |
| Preseed ISO | 10-15 мин | 0 | ✅ Высокая |
| PXE + Preseed | 5-10 мин | 0 | ✅ Очень высокая |

---

## 🔐 Безопасность

### ⚠️ ВАЖНО: Тестовые данные!

Проект содержит **тестовые** учётные данные:
- User: `testuser`
- Password: `test123`

**Для продакшена**:
1. Сгенерируйте сильный пароль:
   ```bash
   pwgen -s 32 1
   ```

2. Создайте хеш:
   ```bash
   mkpasswd -m sha-512 -S $(pwgen -ns 16 1) -R 656000
   ```

3. Замените в `preseed-minimal.cfg`:
   ```bash
   d-i passwd/user-password-crypted password $6$YOUR_HASH_HERE
   ```

4. Настройте SSH-ключи вместо паролей

---

## 🚀 Продвинутое использование

### Интеграция с Ansible

После установки автоматически запустить Ansible:

```bash
# В preseed.cfg добавить:
d-i preseed/late_command string \\
    in-target wget -O /tmp/bootstrap.sh http://your-server/bootstrap.sh; \\
    in-target bash /tmp/bootstrap.sh
```

### PXE Boot сервер

```bash
# Настроить TFTP + DHCP для сетевой загрузки
apt install tftpd-hpa isc-dhcp-server

# Извлечь ядро и initrd из ISO
xorriso -osirrox on -indev debian-12-preseed-auto.iso \\
    -extract /install.amd/vmlinuz /srv/tftp/vmlinuz \\
    -extract /install.amd/initrd.gz /srv/tftp/initrd.gz
```

### Docker-контейнер для сборки

```dockerfile
FROM debian:12
RUN apt update && apt install -y xorriso isolinux syslinux-utils wget
COPY . /build
WORKDIR /build
CMD ["./build-preseed-iso.sh"]
```

---

## 📚 Полезные ссылки

- [Официальная документация Preseed](https://www.debian.org/releases/stable/amd64/apb.html)
- [Примеры preseed.cfg](https://www.debian.org/releases/stable/example-preseed.txt)
- [Debian Installer](https://www.debian.org/devel/debian-installer/)
- [Автоматизация с Ansible](https://docs.ansible.com/)

---

## 🤝 Вклад в проект

Приветствуются:
- 🐛 Сообщения об ошибках
- 💡 Идеи улучшений
- 📝 Улучшение документации
- 🔧 Pull requests

---

## 📜 Лицензия

MIT License - используйте свободно!

---

## 👤 Автор

Создано для изучения автоматизации установки Linux систем.

**Вопросы?** Создайте Issue на GitHub!

---

## ⭐ Roadmap

- [ ] Поддержка Ubuntu
- [ ] Web-интерфейс для генерации preseed
- [ ] Шаблоны для разных сценариев (веб-сервер, БД, k8s-ноды)
- [ ] Интеграция с Terraform
- [ ] CI/CD pipeline для автоматической сборки

---

**Сделано с ❤️ для DevOps-сообщества**


✅ preseed-minimal.cfg          - Конфигурация автоустановки
✅ build-preseed-iso.sh         - Скрипт сборки ISO
✅ CHEATSHEET.md                - Шпаргалка команд
✅ README.md                    - Полная документация
✅ preseed-iso-workflow.png     - Визуальная схема процесса


# Создадим LICENSE
license_text = """MIT License

Copyright (c) 2025 Debian Preseed ISO Builder

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

with open('/home/user/LICENSE', 'w') as f:
    f.write(license_text)

print("✅ Создан LICENSE")

print("\n" + "="*60)
print("🎉 ВСЕ ГОТОВО ДЛЯ ИСПОЛЬЗОВАНИЯ!")
print("="*60)
print("""
📌 СЛЕДУЮЩИЕ ШАГИ:

1️⃣  Скачать все файлы из sandbox
2️⃣  Запустить build-preseed-iso.sh
3️⃣  Протестировать в VirtualBox
4️⃣  Опубликовать на GitHub (опционально)

💡 СОВЕТ: Начните с тестирования в VM перед использованием на реальном железе!
""")
