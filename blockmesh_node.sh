#!/bin/bash

tput reset
tput civis

INSTALLATION_PATH="$HOME/blockmesh"

show_orange() {
    echo -e "\e[33m$1\e[0m"
}

show_blue() {
    echo -e "\e[34m$1\e[0m"
}

show_green() {
    echo -e "\e[32m$1\e[0m"
}

show_red() {
    echo -e "\e[31m$1\e[0m"
}

exit_script() {
    show_red "Скрипт остановлен (Script stopped)"
        echo ""
        exit 0
}

incorrect_option () {
    echo ""
    show_red "Неверная опция. Пожалуйста, выберите из тех, что есть."
    echo ""
    show_red "Invalid option. Please choose from the available options."
    echo ""
}

process_notification() {
    local message="$1"
    show_orange "$message"
    sleep 1
}

run_commands() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo ""
        show_green "Успешно (Success)"
        echo ""
    else
        sleep 1
        echo ""
        show_red "Ошибка (Fail)"
        echo ""
    fi
}

run_commands_info() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo ""
        show_green "Успешно (Success)"
        echo ""
    else
        sleep 1
        echo ""
        show_blue "Не найден (Not Found)"
        echo ""
    fi
}

run_node_command() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        show_green "НОДА ЗАПУЩЕНА (NODE IS RUNNING)!"
        echo
    else
        show_red "НОДА НЕ ЗАПУЩЕНА (NODE ISN'T RUNNING)!"
        echo
    fi
}

create_service() {
    local EMAIL="$1"
    local PASSWORD="$2"
    sudo tee /etc/systemd/system/blockmesh.service > /dev/null << EOF
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USER
ExecStart=$INSTALLATION_PATH/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email "$EMAIL" --password $PASSWORD"
WorkingDirectory=$INSTALLATION_PATH/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

stop_delete_service() {
    local service="$1"
    process_notification "Удаляем сервис (Deleting Service)..."
    sudo systemctl stop $service && sudo systemctl disable $service
    sudo rm /etc/systemd/system/$service.service && sudo systemctl daemon-reload
    sleep 1
}

show_orange " .______    __        ______     ______  __  ___ " && sleep 0.2
show_orange " |   _  \  |  |      /  __  \   /      ||  |/  / " && sleep 0.2
show_orange " |  |_)  | |  |     |  |  |  | |  ,----'|  '  /  " && sleep 0.2
show_orange " |   _  <  |  |     |  |  |  | |  |     |    <   " && sleep 0.2
show_orange " |  |_)  | |   ----.|   --'  | |   ----.|  .  \  " && sleep 0.2
show_orange " |______/  |_______| \______/   \______||__|\__\ " && sleep 0.2
show_orange " .___  ___.  _______      _______. __    __ " && sleep 0.2
show_orange " |   \/   | |   ____|    /       ||  |  |  | " && sleep 0.2
show_orange " |  \  /  | |  |__      |   (---- |  |__|  | " && sleep 0.2
show_orange " |  |\/|  | |   __|      \   \    |   __   | " && sleep 0.2
show_orange " |  |  |  | |  |____ .----)   |   |  |  |  | " && sleep 0.2
show_orange " |__|  |__| |_______||_______/    |__|  |__| " && sleep 0.2
echo
sleep 1

while true; do
    show_green "----- MAIN MENU -----"
    echo "1. Установка (Install)"
    echo "2. Логи (Logs)"
    echo "3. Перезапуск/Остановка (Restart/Stop)"
    echo "4. Удаление (Delete)"
    echo "5. Выход (Exit)"
    echo ""
    read -p "Выберите опцию (Select option): " option

    case $option in
        1)
            process_notification "Начинаем подготовку (Starting preparation)..."
            echo

            # Update packages
            process_notification "Обновляем пакеты (Updating packages)..."
            run_commands "sudo apt update && sudo apt upgrade -y && sudo apt install -y tar"

            # Creating dir
            process_notification "Создаем папку (Creating Dir)..."
            run_commands "cd $HOME && mkdir -p blockmesh && cd blockmesh"

            #Download latest binary
            process_notification "Скачиваем (Downloading)..."
            VERSION="$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest | grep "tag_name" | cut -d '"' -f 4)"
            show_green "LAST VERSION = $VERSION"
            sleep 2
            run_commands "wget -O blockmesh-latest.tar.gz https://github.com/block-mesh/block-mesh-monorepo/releases/download/$VERSION/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"

            # Extract
            process_notification "Распаковываем (Extracting)..."
            run_commands "tar -xzvf blockmesh-latest.tar.gz && rm blockmesh-latest.tar.gz"

            process_notification "Настраиваем (Tuning)..."
            cd $HOME/blockmesh/target/x86_64-unknown-linux-gnu/release/
            read -p "Введите (Enter) Email: " EMAIL
            read -p "Введите (Enter) Password: " PASSWORD

            # Service file
            process_notification "Создаем сервис (Creating service)..."
            create_service "$EMAIL" "$PASSWORD"

            run_node_command "sudo systemctl daemon-reload && sudo systemctl enable blockmesh && sudo systemctl start blockmesh"
            ;;
        2)
            # Logs
            sudo journalctl -u blockmesh -f
            ;;
        3)
            show_orange "Выберете (Choose)"
            echo
            echo "1. Перезапуск (Restart)"
            echo "2. Остановка (Stop)"
            echo
            read -p "Выберите опцию (Select option): " option
                case $option in
                    1)
                        # Restart
                        process_notification "Останавливаем (Stopping)..."
                        run_commands "sudo systemctl stop blockmesh"

                        cd $INSTALLATION_PATH/target/x86_64-unknown-linux-gnu/release/
                        read -p "Введите (Enter) Email: " EMAIL
                        read -p "Введите (Enter) Password: " PASSWORD

                        process_notification "Обновляем сервис (Update service)..."
                        create_service "$EMAIL" "$PASSWORD"
                        run_commands "sudo systemctl daemon-reload && sudo systemctl restart blockmesh"
                        ;;
                    2)
                        # stop
                        process_notification "Останавливаем (Stopping)..."
                        run_commands "sudo systemctl stop blockmesh"
                        echo
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
                ;;
        4)
            # Delete
            process_notification "Удаляем ноду (Deleting node)"
            echo
            run_commands "stop_delete_service blockmesh"

            process_notification "Удаляем файлы (Deleting Files)..."
            run_commands "rm -rvf $HOME/blockmesh"

            echo
            show_green "--- НОДА УДАЛЕНА. NODE DELETED ---"
            echo
            ;;
        5)
            exit_script
            ;;
        *)
            incorrect_option
            ;;
    esac
done
