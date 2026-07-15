#!/bin/bash

# TrafficCop 全能管理工具 v3.0
# 安装：一行命令，进去自己选功能
# 最后更新：2026-07-15

SCRIPT_VERSION="3.0"
LAST_UPDATE="2026-07-15"

# ========== 颜色定义 ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ========== 基础变量 ==========
WORK_DIR="/root/TrafficCop"
REPO_URL="https://raw.githubusercontent.com/GomoXU/TrafficMonitor/main"
INSTALLED_FLAG="$WORK_DIR/.trafficcop_installed"

# 所有需要下载的脚本清单
SCRIPTS=(
    "trafficcop.sh"
    "tg_notifier.sh"
    "pushplus_notifier.sh"
    "serverchan_notifier.sh"
    "port_traffic_limit.sh"
    "view_port_traffic.sh"
    "port_traffic_helper.sh"
    "machine_limit_manager.sh"
    "remove_traffic_limit.sh"
    "set_daily_time.sh"
    "test_port_traffic_notifications.sh"
)

# ========== 工具函数 ==========

# 检查 root 权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}此脚本必须以 root 权限运行${NC}"
        echo -e "${YELLOW}请执行: sudo bash $0${NC}"
        exit 1
    fi
}

# 打印分隔线
print_line() {
    local char="${1:-─}"
    local width="${2:-54}"
    printf "${BLUE}%s${NC}\n" "$(printf "%.s${char}" $(seq 1 $width))"
}

# 打印居中的标题
print_center() {
    local text="$1"
    local width="${2:-54}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${BLUE}%s${NC}\n" "$(printf "%.s " $(seq 1 $padding))${text}"
}

# 带颜色的状态图标
status_icon() {
    local result="$1"
    if [ "$result" = "yes" ] || [ "$result" = "installed" ] || [ "$result" = "running" ]; then
        echo -e "${GREEN}✓${NC}"
    elif [ "$result" = "no" ] || [ "$result" = "missing" ] || [ "$result" = "stopped" ]; then
        echo -e "${RED}✗${NC}"
    else
        echo -e "${YELLOW}?${NC}"
    fi
}

# ========== 安装函数 ==========

# 创建工作目录
create_work_dir() {
    mkdir -p "$WORK_DIR"
}

# 下载单个脚本
download_script() {
    local script_name="$1"
    local target="$WORK_DIR/$script_name"

    echo -ne "  ${CYAN}$script_name${NC} ... "
    if curl -fsSL "$REPO_URL/$script_name" -o "$target" 2>/dev/null; then
        chmod +x "$target"
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}失败${NC}"
        return 1
    fi
}

# 首次运行：下载全部脚本
first_run_setup() {
    clear
    echo ""
    print_line "═"
    print_center "TrafficCop v${SCRIPT_VERSION} 安装工具"
    print_center "一键部署，自由选择"
    print_line "═"
    echo ""

    # 检测系统环境
    echo -e "${YELLOW}▶ 正在检测系统环境...${NC}"
    echo -ne "  Root 权限:                    "; echo -e "${GREEN}✓${NC}"

    # 检测操作系统
    local os_name="未知"
    if [ -f /etc/os-release ]; then
        os_name=$(grep -oP '(?<=^ID=).*' /etc/os-release 2>/dev/null | tr -d '"')
    elif command -v lsb_release &>/dev/null; then
        os_name=$(lsb_release -si 2>/dev/null)
    fi
    echo -e "  操作系统:                     ${CYAN}${os_name:-检测中}${NC}"

    # 检测已安装的依赖
    echo ""
    echo -e "${YELLOW}▶ 检测依赖...${NC}"
    local deps=("curl" "bash" "cron")
    for dep in "${deps[@]}"; do
        echo -ne "  $dep: "
        if command -v "$dep" &>/dev/null; then
            echo -e "${GREEN}已安装${NC}"
        else
            echo -e "${YELLOW}未安装 (尝试自动安装)${NC}"
            apt-get install -y "$dep" &>/dev/null || yum install -y "$dep" &>/dev/null
        fi
    done

    # 创建工作目录
    echo ""
    echo -e "${YELLOW}▶ 创建目录 $WORK_DIR${NC}"
    create_work_dir

    # 批量下载所有脚本
    echo ""
    echo -e "${YELLOW}▶ 正在下载所有脚本到 $WORK_DIR ...${NC}"
    local fail_count=0
    for script in "${SCRIPTS[@]}"; do
        download_script "$script" || ((fail_count++))
    done

    if [ $fail_count -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠ 有 $fail_count 个脚本下载失败，可稍后通过菜单 [10] 更新${NC}"
    fi

    # 写入安装标记
    echo "$SCRIPT_VERSION" > "$INSTALLED_FLAG"

    echo ""
    echo -e "${GREEN}✅ 基础安装完成！${NC}"
    echo -e "${CYAN}所有脚本已下载到: $WORK_DIR${NC}"
    echo ""
}

# ========== 快速配置向导 ==========

quick_setup_wizard() {
    clear
    echo ""
    print_line "═"
    print_center "🎯 快速配置向导"
    print_center "一步步完成基础设置"
    print_line "═"
    echo ""
    echo -e "${YELLOW}本向导将引导你完成以下设置：${NC}"
    echo "  1. 流量监控（必配）"
    echo "  2. 推送通知（可选）"
    echo "  3. 端口流量限制（可选）"
    echo ""

    # ---- Step 1: 流量监控 ----
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Step 1/3: 流量监控配置${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}即将进入流量监控配置向导...${NC}"
    echo -e "${YELLOW}你需要设置：统计模式、周期、流量限制等参数${NC}"
    echo ""
    read -p "按回车键开始配置流量监控 (输入 s 跳过): " step1_choice
    if [ "$step1_choice" != "s" ] && [ "$step1_choice" != "S" ]; then
        if [ -f "$WORK_DIR/trafficcop.sh" ]; then
            bash "$WORK_DIR/trafficcop.sh" --quiet-setup
        else
            echo -e "${RED}trafficcop.sh 不存在，请先安装${NC}"
            read -p "按回车键继续..."
        fi
    else
        echo -e "${YELLOW}已跳过流量监控配置${NC}"
        sleep 1
    fi

    # ---- Step 2: 推送通知 ----
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Step 2/3: 推送通知配置 (可选)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}选择你需要的推送通知方式：${NC}"
    echo -e "  ${YELLOW}1${NC}) Telegram   ${YELLOW}2${NC}) PushPlus   ${YELLOW}3${NC}) Server酱   ${YELLOW}0${NC}) 跳过"
    echo ""
    read -p "请选择 [0-3]: " notifier_choice
    case $notifier_choice in
        1)
            if [ -f "$WORK_DIR/tg_notifier.sh" ]; then
                bash "$WORK_DIR/tg_notifier.sh"
            fi
            ;;
        2)
            if [ -f "$WORK_DIR/pushplus_notifier.sh" ]; then
                bash "$WORK_DIR/pushplus_notifier.sh"
            fi
            ;;
        3)
            if [ -f "$WORK_DIR/serverchan_notifier.sh" ]; then
                bash "$WORK_DIR/serverchan_notifier.sh"
            fi
            ;;
        *)
            echo -e "${YELLOW}跳过推送通知配置${NC}"
            ;;
    esac

    # ---- Step 3: 端口流量限制 ----
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Step 3/3: 端口流量限制 (可选)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}端口流量限制可为特定端口（如 80/443）设置独立流量限额${NC}"
    echo ""
    read -p "是否配置端口流量限制？(y/N): " port_choice
    if [ "$port_choice" = "y" ] || [ "$port_choice" = "Y" ]; then
        if [ -f "$WORK_DIR/port_traffic_limit.sh" ]; then
            bash "$WORK_DIR/port_traffic_limit.sh"
        else
            echo -e "${RED}port_traffic_limit.sh 不存在${NC}"
        fi
    else
        echo -e "${YELLOW}跳过端口流量限制配置${NC}"
    fi

    # ---- 完成 ----
    echo ""
    print_line "═"
    echo -e "${GREEN}  🎉 快速配置向导完成！${NC}"
    print_line "═"
    echo ""
    echo -e "${CYAN}配置摘要：${NC}"
    if [ -f "$WORK_DIR/traffic_monitor_config.txt" ]; then
        echo -e "  ${GREEN}✓${NC} 流量监控：已配置"
    else
        echo -e "  ${YELLOW}○${NC} 流量监控：未配置"
    fi
    if [ -f "$WORK_DIR/tg_notifier_config.txt" ] || [ -f "$WORK_DIR/pushplus_notifier_config.txt" ] || [ -f "$WORK_DIR/serverchan_notifier_config.txt" ]; then
        echo -e "  ${GREEN}✓${NC} 推送通知：已配置"
    else
        echo -e "  ${YELLOW}○${NC} 推送通知：未配置"
    fi
    if [ -f "$WORK_DIR/ports_traffic_config.json" ]; then
        echo -e "  ${GREEN}✓${NC} 端口限制：已配置"
    else
        echo -e "  ${YELLOW}○${NC} 端口限制：未配置"
    fi
    echo ""
    read -p "按回车键进入主菜单..."
}

# ========== 功能菜单处理函数 ==========

# 选项 1：配置/修改流量监控
configure_monitor() {
    clear
    echo -e "${CYAN}▶ 流量监控配置${NC}"
    echo ""
    if [ ! -f "$WORK_DIR/trafficcop.sh" ]; then
        echo -e "${YELLOW}trafficcop.sh 不存在，正在下载...${NC}"
        install_script "trafficcop.sh"
    fi
    bash "$WORK_DIR/trafficcop.sh" --quiet-setup
    echo ""
    read -p "按回车键返回主菜单..."
}

# 选项 2：配置推送通知
configure_notifications() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         推送通知配置                  ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}1${NC}) Telegram 通知"
        echo -e "  ${YELLOW}2${NC}) PushPlus 通知"
        echo -e "  ${YELLOW}3${NC}) Server酱 通知"
        echo -e "  ${YELLOW}0${NC}) 返回主菜单"
        echo ""
        read -p "请选择 [0-3]: " nc

        case $nc in
            1)
                if [ ! -f "$WORK_DIR/tg_notifier.sh" ]; then
                    install_script "tg_notifier.sh"
                fi
                bash "$WORK_DIR/tg_notifier.sh"
                read -p "按回车键继续..."
                ;;
            2)
                if [ ! -f "$WORK_DIR/pushplus_notifier.sh" ]; then
                    install_script "pushplus_notifier.sh"
                fi
                bash "$WORK_DIR/pushplus_notifier.sh"
                read -p "按回车键继续..."
                ;;
            3)
                if [ ! -f "$WORK_DIR/serverchan_notifier.sh" ]; then
                    install_script "serverchan_notifier.sh"
                fi
                bash "$WORK_DIR/serverchan_notifier.sh"
                read -p "按回车键继续..."
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 选项 3：配置端口流量限制
configure_port_limit() {
    clear
    echo -e "${CYAN}▶ 端口流量限制配置${NC}"
    echo ""
    if [ ! -f "$WORK_DIR/port_traffic_limit.sh" ]; then
        echo -e "${YELLOW}port_traffic_limit.sh 不存在，正在下载...${NC}"
        install_script "port_traffic_limit.sh"
        install_script "view_port_traffic.sh"
        install_script "port_traffic_helper.sh"
    fi
    bash "$WORK_DIR/port_traffic_limit.sh"
    read -p "按回车键返回主菜单..."
}

# 选项 4：机器限速管理
manage_machine_limit() {
    clear
    echo -e "${CYAN}▶ 机器限速管理${NC}"
    echo ""
    if [ ! -f "$WORK_DIR/machine_limit_manager.sh" ]; then
        echo -e "${YELLOW}正在下载机器限速管理器...${NC}"
        install_script "machine_limit_manager.sh"
    fi
    bash "$WORK_DIR/machine_limit_manager.sh"
    read -p "按回车键返回主菜单..."
}

# 选项 5：使用预设配置
use_preset_config() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         预设配置                      ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "可用的预设配置:"
        echo ""
        echo -e "  ${YELLOW}1${NC}) 阿里云轻量 20G"
        echo -e "  ${YELLOW}2${NC}) 阿里云轻量 200G"
        echo -e "  ${YELLOW}3${NC}) 阿里云轻量 1T"
        echo -e "  ${YELLOW}4${NC}) 亚洲云 300G"
        echo -e "  ${YELLOW}5${NC}) Azure 15G"
        echo -e "  ${YELLOW}6${NC}) Azure 115G"
        echo -e "  ${YELLOW}7${NC}) GCP 200G"
        echo -e "  ${YELLOW}8${NC}) GCP 625G"
        echo -e "  ${YELLOW}9${NC}) Alice 1500G"
        echo -e "  ${YELLOW}0${NC}) 返回主菜单"
        echo ""

        read -p "请选择 [0-9]: " preset_choice

        local config_name=""
        case $preset_choice in
            1) config_name="ali-20g" ;;
            2) config_name="ali-200g" ;;
            3) config_name="ali-1T" ;;
            4) config_name="asia-300g" ;;
            5) config_name="az-15g" ;;
            6) config_name="az-115g" ;;
            7) config_name="gcp-200g" ;;
            8) config_name="gcp-625g" ;;
            9) config_name="alice-1500g" ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 1
                continue
                ;;
        esac

        echo ""
        echo -e "${YELLOW}正在下载并应用预设配置 $config_name ...${NC}"
        echo ""
        if curl -fsSL "$REPO_URL/$config_name" -o "$WORK_DIR/traffic_monitor_config.txt"; then
            echo -e "${GREEN}✅ 预设配置已应用！${NC}"
            echo ""
            echo -e "${CYAN}配置内容：${NC}"
            cat "$WORK_DIR/traffic_monitor_config.txt"
            echo ""
            echo -e "${YELLOW}注意：${NC}预设只包含基础配置，还需手动设置网络接口"
            echo ""

            read -p "是否立即进入流量监控配置？(y/N): " start_monitor
            if [ "$start_monitor" = "y" ] || [ "$start_monitor" = "Y" ]; then
                if [ -f "$WORK_DIR/trafficcop.sh" ]; then
                    bash "$WORK_DIR/trafficcop.sh" --quiet-setup
                fi
            fi
        else
            echo -e "${RED}下载预设配置失败${NC}"
        fi
        read -p "按回车键继续..."
    done
}

# 选项 6：查看端口流量状态
view_port_traffic() {
    clear
    echo -e "${CYAN}▶ 端口流量状态${NC}"
    echo ""
    if [ ! -f "$WORK_DIR/view_port_traffic.sh" ]; then
        echo -e "${YELLOW}view_port_traffic.sh 不存在，正在下载...${NC}"
        install_script "view_port_traffic.sh"
    fi
    if [ -f "$WORK_DIR/view_port_traffic.sh" ]; then
        bash "$WORK_DIR/view_port_traffic.sh"
    else
        echo -e "${RED}无法下载端口流量查看脚本${NC}"
    fi
    echo ""
    read -p "按回车键返回主菜单..."
}

# 选项 7：查看日志
view_logs() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         查看日志                      ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}1${NC}) 流量监控日志"
        echo -e "  ${YELLOW}2${NC}) Telegram 通知日志"
        echo -e "  ${YELLOW}3${NC}) PushPlus 通知日志"
        echo -e "  ${YELLOW}4${NC}) Server酱 通知日志"
        echo -e "  ${YELLOW}5${NC}) 端口流量监控日志"
        echo -e "  ${YELLOW}0${NC}) 返回主菜单"
        echo ""

        read -p "请选择 [0-5]: " log_choice

        local log_file=""
        case $log_choice in
            1) log_file="traffic_monitor.log" ;;
            2) log_file="tg_notifier_cron.log" ;;
            3) log_file="pushplus_notifier_cron.log" ;;
            4) log_file="serverchan_notifier_cron.log" ;;
            5) log_file="port_traffic_monitor.log" ;;
            0) return ;;
            *) echo -e "${RED}无效选择${NC}"; sleep 1; continue ;;
        esac

        if [ -f "$WORK_DIR/$log_file" ]; then
            echo ""
            tail -30 "$WORK_DIR/$log_file"
        else
            echo ""
            echo -e "${YELLOW}日志文件不存在: $log_file${NC}"
        fi
        echo ""
        read -p "按回车键继续..."
    done
}

# 选项 8：查看当前配置
view_config() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         查看配置                      ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}1${NC}) 流量监控配置"
        echo -e "  ${YELLOW}2${NC}) Telegram 通知配置"
        echo -e "  ${YELLOW}3${NC}) PushPlus 通知配置"
        echo -e "  ${YELLOW}4${NC}) Server酱 通知配置"
        echo -e "  ${YELLOW}0${NC}) 返回主菜单"
        echo ""

        read -p "请选择 [0-4]: " config_choice

        local config_file=""
        case $config_choice in
            1) config_file="traffic_monitor_config.txt" ;;
            2) config_file="tg_notifier_config.txt" ;;
            3) config_file="pushplus_notifier_config.txt" ;;
            4) config_file="serverchan_notifier_config.txt" ;;
            0) return ;;
            *) echo -e "${RED}无效选择${NC}"; sleep 1; continue ;;
        esac

        if [ -f "$WORK_DIR/$config_file" ]; then
            echo ""
            cat "$WORK_DIR/$config_file"
        else
            echo ""
            echo -e "${YELLOW}配置文件不存在: $config_file${NC}"
        fi
        echo ""
        read -p "按回车键继续..."
    done
}

# 选项 9：停止所有服务
stop_all_services() {
    clear
    echo -e "${YELLOW}▶ 正在停止所有 TrafficCop 服务...${NC}"
    echo ""

    # 停止进程
    pkill -f "trafficcop.sh" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 流量监控进程已停止" || echo -e "  ${YELLOW}○${NC} 无运行中的监控进程"
    pkill -f "traffic_monitor.sh" 2>/dev/null
    pkill -f "tg_notifier.sh" 2>/dev/null && echo -e "  ${GREEN}✓${NC} TG 通知进程已停止" || echo -e "  ${YELLOW}○${NC} 无运行中的 TG 通知"
    pkill -f "pushplus_notifier.sh" 2>/dev/null && echo -e "  ${GREEN}✓${NC} PushPlus 通知进程已停止" || echo -e "  ${YELLOW}○${NC} 无运行中的 PushPlus"
    pkill -f "serverchan_notifier.sh" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Server酱 通知进程已停止" || echo -e "  ${YELLOW}○${NC} 无运行中的 Server酱"
    pkill -f "port_traffic_limit.sh" 2>/dev/null && echo -e "  ${GREEN}✓${NC} 端口限制进程已停止" || echo -e "  ${YELLOW}○${NC} 无运行中的端口限制"

    # 移除 cron 任务
    echo ""
    crontab -l 2>/dev/null | grep -v "trafficcop.sh\|traffic_monitor.sh\|tg_notifier.sh\|pushplus_notifier.sh\|serverchan_notifier.sh\|port_traffic_limit.sh" | crontab - 2>/dev/null
    echo -e "  ${GREEN}✓${NC} 定时任务已清理"

    # 清除 TC 规则
    local interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [ -n "$interface" ]; then
        tc qdisc del dev "$interface" root 2>/dev/null
        echo -e "  ${GREEN}✓${NC} TC 限速规则已清除"
    fi

    # 取消关机
    shutdown -c 2>/dev/null
    echo -e "  ${GREEN}✓${NC} 关机计划已取消"

    echo ""
    echo -e "${GREEN}✅ 所有服务已停止！${NC}"
    read -p "按回车键返回主菜单..."
}

# 选项 10：更新所有脚本
update_all_scripts() {
    clear
    echo -e "${YELLOW}▶ 正在更新所有脚本到最新版本...${NC}"
    echo ""

    local fail_count=0
    for script in "${SCRIPTS[@]}"; do
        echo -ne "  ${CYAN}$script${NC} ... "
        if curl -fsSL "$REPO_URL/$script" -o "$WORK_DIR/$script.new" 2>/dev/null; then
            mv "$WORK_DIR/$script.new" "$WORK_DIR/$script"
            chmod +x "$WORK_DIR/$script"
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}无更新${NC}"
            rm -f "$WORK_DIR/$script.new"
        fi
    done

    echo ""
    echo -e "${GREEN}✅ 脚本更新完成！${NC}"
    read -p "按回车键返回主菜单..."
}

# ========== 状态检测 ==========

# 检测组件状态，用于菜单头部显示
check_component_status() {
    local status_monitor="missing"
    local status_tg="missing"
    local status_port="missing"
    local status_cron="missing"

    # 流量监控配置
    if [ -f "$WORK_DIR/traffic_monitor_config.txt" ] && [ -s "$WORK_DIR/traffic_monitor_config.txt" ]; then
        status_monitor="installed"
    fi

    # TG 通知
    if [ -f "$WORK_DIR/tg_notifier_config.txt" ]; then
        status_tg="installed"
    fi

    # 端口限制
    if [ -f "$WORK_DIR/ports_traffic_config.json" ]; then
        status_port="installed"
    fi

    # Cron 任务
    if crontab -l 2>/dev/null | grep -qE "trafficcop.sh.*--(run|cron)"; then
        status_cron="installed"
    fi

    echo -e "  ${CYAN}系统状态:${NC}"
    echo -e "    流量监控:  $(status_icon "$status_monitor")  ${status_monitor}"
    echo -e "    推送通知:  $(status_icon "$status_tg")  ${status_tg}"
    echo -e "    端口限制:  $(status_icon "$status_port")  ${status_port}"
    echo -e "    定时任务:  $(status_icon "$status_cron")  ${status_cron}"
}

# ========== 主菜单 ==========

show_main_menu() {
    clear
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         TrafficCop 管理工具 v${SCRIPT_VERSION}        ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}  一行命令安装 · 进去自己选功能                ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    check_component_status
    echo ""
    echo -e "${WHITE}───────────────── 基础功能 ─────────────────${NC}"
    echo -e "  ${YELLOW}1${NC})  配置/修改流量监控"
    echo -e "  ${YELLOW}2${NC})  配置推送通知 ${CYAN}(TG/PushPlus/Server酱)${NC}"
    echo -e "  ${YELLOW}3${NC})  配置端口流量限制"
    echo -e "  ${YELLOW}4${NC})  机器限速管理"
    echo -e "  ${YELLOW}5${NC})  使用预设配置"
    echo ""
    echo -e "${WHITE}───────────────── 查看与管理 ───────────────${NC}"
    echo -e "  ${YELLOW}6${NC})  查看端口流量状态"
    echo -e "  ${YELLOW}7${NC})  查看日志"
    echo -e "  ${YELLOW}8${NC})  查看当前配置"
    echo -e "  ${YELLOW}9${NC})  停止所有服务"
    echo -e "  ${YELLOW}10${NC}) 更新所有脚本"
    echo -e "  ${YELLOW}11${NC}) 快速配置向导 ${CYAN}(重新引导)${NC}"
    echo ""
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}0${NC})  退出"
    echo ""
}

# ========== 安装脚本（备用下载函数） ==========

install_script() {
    local script_name="$1"
    curl -fsSL "$REPO_URL/$script_name" -o "$WORK_DIR/$script_name"
    chmod +x "$WORK_DIR/$script_name"
}

# ========== 主入口 ==========

main() {
    check_root

    # 首次运行检测
    if [ ! -f "$INSTALLED_FLAG" ] || [ ! -f "$WORK_DIR/trafficcop.sh" ]; then
        first_run_setup

        # 询问是否进入快速配置向导
        echo ""
        echo -e "${GREEN}┌──────────────────────────────────────────┐${NC}"
        echo -e "${GREEN}│  🎯 快速配置向导                          │${NC}"
        echo -e "${GREEN}│     一步接一步，完成基础设置               │${NC}"
        echo -e "${GREEN}├──────────────────────────────────────────┤${NC}"
        echo -e "${GREEN}│  ${YELLOW}[1]${GREEN} 进入快速配置向导 ${CYAN}(推荐)${NC}            ${GREEN}│${NC}"
        echo -e "${GREEN}│  ${YELLOW}[2]${GREEN} 直接进入主菜单，我自己来                    ${GREEN}│${NC}"
        echo -e "${GREEN}└──────────────────────────────────────────┘${NC}"
        echo ""
        read -p "请选择 [1/2]，默认 1: " wizard_choice
        if [ "$wizard_choice" != "2" ]; then
            quick_setup_wizard
        fi
    fi

    # 主循环
    while true; do
        show_main_menu
        read -p "请选择操作 [0-11]: " choice

        case $choice in
            1) configure_monitor ;;
            2) configure_notifications ;;
            3) configure_port_limit ;;
            4) manage_machine_limit ;;
            5) use_preset_config ;;
            6) view_port_traffic ;;
            7) view_logs ;;
            8) view_config ;;
            9) stop_all_services ;;
            10) update_all_scripts ;;
            11) quick_setup_wizard ;;
            0)
                echo ""
                echo -e "${GREEN}感谢使用 TrafficCop 管理工具！${NC}"
                echo -e "${CYAN}项目地址: https://github.com/GomoXU/TrafficMonitor${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 1
                ;;
        esac
    done
}

# 启动主程序
main "$@"
