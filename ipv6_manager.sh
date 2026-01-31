#!/bin/bash

# Цветовые коды
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_WHITE="\033[1;37m"
COLOR_RED="\033[1;31m"

# Языковые переменные
declare -A LANG=(
    [IPV6_MENU_TITLE]="Управление IPv6"
    [IPV6_ENABLE]="Включить IPv6"
    [IPV6_DISABLE]="Отключить IPv6"
    [IPV6_TEST]="Протестировать IPv6"
    [IPV6_PROMPT]="Выберите действие (0-3):"
    [IPV6_INVALID_CHOICE]="Неверный выбор. Выберите 0-3."
    [IPV6_ALREADY_ENABLED]="IPv6 уже включен"
    [IPV6_ALREADY_DISABLED]="IPv6 уже отключен"
    [ENABLE_IPV6]="Включение IPv6..."
    [IPV6_ENABLED]="IPv6 включен."
    [DISABLING_IPV6]="Отключение IPv6..."
    [IPV6_DISABLED]="IPv6 отключен."
    [EXIT]="Выход"
    [WAITING]="Пожалуйста, подождите..."
    [IPV6_TEST_TITLE]="Тестирование IPv6"
    [IPV6_STATUS]="Текущий статус IPv6:"
    [IPV6_ENABLED_STATUS]="ВКЛЮЧЕН"
    [IPV6_DISABLED_STATUS]="ОТКЛЮЧЕН"
    [IPV6_INTERFACE]="Сетевой интерфейс:"
    [IPV6_ADDRESSES]="IPv6 адреса:"
    [IPV6_CONNECTIVITY]="Проверка внешней связи:"
    [IPV6_CONNECTED]="✓ Связь с интернетом работает"
    [IPV6_NOT_CONNECTED]="✗ Нет связи с интернетом"
    [IPV6_GOOGLE_TEST]="Пинг Google IPv6:"
    [IPV6_GOOGLE_SUCCESS]="✓ Успешно"
    [IPV6_GOOGLE_FAILED]="✗ Не удалось"
    [IPV6_TEST_SUCCESS]="Тестирование завершено успешно"
    [IPV6_TEST_FAILED]="Тестирование выявило проблемы"
    [NO_INTERFACE_FOUND]="Не найден сетевой интерфейс"
    [NO_IPV6_ADDRESSES]="IPv6 адреса не найдены"
)

# Функции вывода
question() {
    echo -e "${COLOR_GREEN}[?]${COLOR_RESET} ${COLOR_YELLOW}$*${COLOR_RESET}"
}

reading() {
    read -rp " $(question "$1")" "$2"
}

spinner() {
    local pid=$1
    local text=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local delay=0.1
    
    printf "${COLOR_YELLOW}%s${COLOR_RESET}" "$text" > /dev/tty
    
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r[%s] %s" "$(echo -n "${spinstr:$i:1}")" "$text" > /dev/tty
            sleep $delay
        done
    done
    
    printf "\r\033[K" > /dev/tty
}

# Функция включения IPv6
enable_ipv6() {
    echo -e "${COLOR_YELLOW}${LANG[ENABLE_IPV6]}${COLOR_RESET}"
    
    # Находим сетевой интерфейс
    interface_name=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)
    
    if [ -z "$interface_name" ]; then
        echo -e "${COLOR_RED}${LANG[NO_INTERFACE_FOUND]}${COLOR_RESET}"
        return 1
    fi
    
    echo -e "${COLOR_YELLOW}Используется интерфейс: $interface_name${COLOR_RESET}"
    
    # Удаляем старые настройки
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf
    sed -i "/net.ipv6.conf.$interface_name.disable_ipv6/d" /etc/sysctl.conf
    
    # Добавляем новые настройки для включения IPv6
    {
        echo "net.ipv6.conf.all.disable_ipv6 = 0"
        echo "net.ipv6.conf.default.disable_ipv6 = 0"
        echo "net.ipv6.conf.lo.disable_ipv6 = 0"
        echo "net.ipv6.conf.$interface_name.disable_ipv6 = 0"
    } >> /etc/sysctl.conf
    
    # Применяем изменения
    sysctl -p > /dev/null 2>&1 &
    spinner $! "${LANG[WAITING]}"
    
    # Проверяем результат
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 0 ]; then
        echo -e "${COLOR_GREEN}${LANG[IPV6_ENABLED]}${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}Ошибка при включении IPv6${COLOR_RESET}"
        return 1
    fi
}

# Функция отключения IPv6
disable_ipv6() {
    echo -e "${COLOR_YELLOW}${LANG[DISABLING_IPV6]}${COLOR_RESET}"
    
    # Находим сетевой интерфейс
    interface_name=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)
    
    if [ -z "$interface_name" ]; then
        echo -e "${COLOR_RED}${LANG[NO_INTERFACE_FOUND]}${COLOR_RESET}"
        return 1
    fi
    
    echo -e "${COLOR_YELLOW}Используется интерфейс: $interface_name${COLOR_RESET}"
    
    # Удаляем старые настройки
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf
    sed -i "/net.ipv6.conf.$interface_name.disable_ipv6/d" /etc/sysctl.conf
    
    # Добавляем новые настройки для отключения IPv6
    {
        echo "net.ipv6.conf.all.disable_ipv6 = 1"
        echo "net.ipv6.conf.default.disable_ipv6 = 1"
        echo "net.ipv6.conf.lo.disable_ipv6 = 1"
        echo "net.ipv6.conf.$interface_name.disable_ipv6 = 1"
    } >> /etc/sysctl.conf
    
    # Применяем изменения
    sysctl -p > /dev/null 2>&1 &
    spinner $! "${LANG[WAITING]}"
    
    # Проверяем результат
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 1 ]; then
        echo -e "${COLOR_GREEN}${LANG[IPV6_DISABLED]}${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}Ошибка при отключении IPv6${COLOR_RESET}"
        return 1
    fi
}

# Функция тестирования IPv6
test_ipv6() {
    echo -e ""
    echo -e "${COLOR_GREEN}${LANG[IPV6_TEST_TITLE]}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}========================================${COLOR_RESET}"
    
    # 1. Проверяем текущий статус
    echo -e "${COLOR_YELLOW}${LANG[IPV6_STATUS]}${COLOR_RESET}"
    local ipv6_status=$(sysctl -n net.ipv6.conf.all.disable_ipv6)
    if [ "$ipv6_status" -eq 0 ]; then
        echo -e "${COLOR_GREEN}  ${LANG[IPV6_ENABLED_STATUS]}${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}  ${LANG[IPV6_DISABLED_STATUS]}${COLOR_RESET}"
    fi
    
    # 2. Проверяем сетевой интерфейс
    echo -e "${COLOR_YELLOW}${LANG[IPV6_INTERFACE]}${COLOR_RESET}"
    local interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)
    if [ -n "$interface" ]; then
        echo -e "  ${COLOR_WHITE}$interface${COLOR_RESET}"
    else
        echo -e "  ${COLOR_RED}${LANG[NO_INTERFACE_FOUND]}${COLOR_RESET}"
    fi
    
    # 3. Проверяем IPv6 адреса
    echo -e "${COLOR_YELLOW}${LANG[IPV6_ADDRESSES]}${COLOR_RESET}"
    local ipv6_addrs=$(ip -6 addr show dev "$interface" 2>/dev/null | grep inet6 | awk '{print $2}' | head -5)
    if [ -n "$ipv6_addrs" ]; then
        while IFS= read -r addr; do
            echo -e "  ${COLOR_WHITE}$addr${COLOR_RESET}"
        done <<< "$ipv6_addrs"
    else
        echo -e "  ${COLOR_YELLOW}${LANG[NO_IPV6_ADDRESSES]}${COLOR_RESET}"
    fi
    
    # 4. Проверяем связь с интернетом (только если IPv6 включен)
    if [ "$ipv6_status" -eq 0 ]; then
        echo -e "${COLOR_YELLOW}${LANG[IPV6_CONNECTIVITY]}${COLOR_RESET}"
        
        # Пинг Google IPv6
        echo -e "${COLOR_YELLOW}${LANG[IPV6_GOOGLE_TEST]}${COLOR_RESET}"
        if ping6 -c 2 -W 2 ipv6.google.com > /dev/null 2>&1; then
            echo -e "  ${COLOR_GREEN}${LANG[IPV6_GOOGLE_SUCCESS]}${COLOR_RESET}"
        else
            echo -e "  ${COLOR_RED}${LANG[IPV6_GOOGLE_FAILED]}${COLOR_RESET}"
        fi
        
        # Проверка внешней связи
        echo -e "${COLOR_YELLOW}${LANG[IPV6_CONNECTIVITY]}${COLOR_RESET}"
        if curl -s --max-time 5 --ipv6 https://ipv6.google.com > /dev/null 2>&1; then
            echo -e "  ${COLOR_GREEN}${LANG[IPV6_CONNECTED]}${COLOR_RESET}"
        else
            echo -e "  ${COLOR_RED}${LANG[IPV6_NOT_CONNECTED]}${COLOR_RESET}"
        fi
        
        echo -e "${COLOR_GREEN}${LANG[IPV6_TEST_SUCCESS]}${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}IPv6 отключен. Для тестирования включите его сначала.${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_YELLOW}========================================${COLOR_RESET}"
    echo -e ""
    
    reading "${LANG[PRESS_ENTER_RETURN_MENU]}" dummy
}

# Показ меню управления IPv6
show_ipv6_menu() {
    echo -e ""
    echo -e "${COLOR_GREEN}${LANG[IPV6_MENU_TITLE]}${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_YELLOW}1. ${LANG[IPV6_TEST]}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}2. ${LANG[IPV6_ENABLE]}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}3. ${LANG[IPV6_DISABLE]}${COLOR_RESET}"
    echo -e ""
    echo -e "${COLOR_YELLOW}0. ${LANG[EXIT]}${COLOR_RESET}"
    echo -e ""
}

# Основная функция управления IPv6
manage_ipv6() {
    while true; do
        clear
        show_ipv6_menu
        reading "${LANG[IPV6_PROMPT]}" IPV6_OPTION
        
        case $IPV6_OPTION in
            1)
                # Тестирование IPv6
                clear
                test_ipv6
                ;;
            2)
                # Включение IPv6
                clear
                
                # Проверяем текущий статус
                if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 0 ]; then
                    echo -e "${COLOR_YELLOW}${LANG[IPV6_ALREADY_ENABLED]}${COLOR_RESET}"
                    sleep 2
                    continue
                fi
                
                # Запрашиваем подтверждение
                echo -e "${COLOR_YELLOW}Вы уверены, что хотите включить IPv6? (y/n):${COLOR_RESET}"
                read -n 1 confirm
                echo ""
                
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    enable_ipv6
                else
                    echo -e "${COLOR_YELLOW}Включение IPv6 отменено${COLOR_RESET}"
                fi
                
                sleep 2
                ;;
            3)
                # Отключение IPv6
                clear
                
                # Проверяем текущий статус
                if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 1 ]; then
                    echo -e "${COLOR_YELLOW}${LANG[IPV6_ALREADY_DISABLED]}${COLOR_RESET}"
                    sleep 2
                    continue
                fi
                
                # Запрашиваем подтверждение
                echo -e "${COLOR_YELLOW}Вы уверены, что хотите отключить IPv6? (y/n):${COLOR_RESET}"
                read -n 1 confirm
                echo ""
                
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    disable_ipv6
                else
                    echo -e "${COLOR_YELLOW}Отключение IPv6 отменено${COLOR_RESET}"
                fi
                
                sleep 2
                ;;
            0)
                # Выход
                echo -e "${COLOR_YELLOW}${LANG[EXIT]}${COLOR_RESET}"
                break
                ;;
            *)
                echo -e "${COLOR_RED}${LANG[IPV6_INVALID_CHOICE]}${COLOR_RESET}"
                sleep 2
                ;;
        esac
    done
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${COLOR_RED}Скрипт нужно запускать с правами root${COLOR_RESET}"
        exit 1
    fi
}

# Основная функция
main() {
    # Проверяем права root
    check_root
    
    # Проверяем наличие необходимых утилит
    if ! command -v ip >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Утилита 'ip' не найдена. Установите iproute2${COLOR_RESET}"
        exit 1
    fi
    
    if ! command -v sysctl >/dev/null 2>&1; then
        echo -e "${COLOR_RED}Утилита 'sysctl' не найдена${COLOR_RESET}"
        exit 1
    fi
    
    # Запускаем меню
    manage_ipv6
}

# Запуск основной функции
main
