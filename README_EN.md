# TrafficCop - Smart Traffic Monitoring and Limiting Script

English | [中文](README.md)

## One-Click Installation

```bash
bash <(curl -sL https://raw.githubusercontent.com/GomoXU/TrafficMonitor/main/trafficcop-manager.sh)
```

**One command. Choose features interactively inside.**

After installation, you'll see an interactive menu. Just pick what you need:

| Option | Feature | Description |
|--------|---------|-------------|
| `1` | Configure Traffic Monitoring | Traffic stats, speed limit, shutdown protection |
| `2` | Configure Push Notifications | Telegram / PushPlus / ServerChan |
| `3` | Configure Port Traffic Limits | Set independent limits per port |
| `4` | Machine Limit Management | Enable/disable traffic limits |
| `5` | Use Preset Configs | Alibaba/Azure/GCP one-click configs |
| `6` | View Port Traffic | Real-time port monitoring |
| `7-8` | View Logs and Configs | |
| `9` | Stop All Services | |
| `10` | Update All Scripts | Keep everything up-to-date |

## Important Notes

1. This script relies on vnstat for traffic statistics. vnstat will only start tracking traffic after installation!
2. TC mode cannot prevent DDoS traffic consumption.
3. The script runs with root privileges by default. For non-root users, ensure they have sudo privileges.
4. If you encounter issues, check the log file (`/root/TrafficCop/traffic_monitor.log`).
5. It's recommended to regularly backup the configuration file (`traffic_monitor_config.txt`).

## Script Logic

- Automatically detects and selects the main network interface for traffic limiting
- Users select traffic statistics mode (four options)
- Users set traffic calculation cycle (month/quarter/year) and start date
- Users input traffic limit and error tolerance range
- Users select limiting mode (TC mode or shutdown mode)
- Script checks traffic consumption every minute and executes appropriate actions when limits are reached
- Automatically removes restrictions when a new traffic cycle begins

## Script Features

- Four comprehensive traffic statistics modes, adaptable to various VPS billing methods
- Custom traffic calculation cycles and start dates
- Custom traffic error tolerance range
- Interactive configuration, parameters can be modified at any time
- Real-time traffic statistics prompts
- TC mode ensures SSH connections remain available
- Shutdown mode provides stricter traffic control

## Push Notifications

TrafficCop supports:
- **Telegram Bot** - Speed limit warnings, daily reports, etc.
- **PushPlus** - WeChat push
- **ServerChan** - WeChat push

Just select the corresponding option in the menu and enter your Token.

## Preset Configurations

Select option `5` in the menu to use preset configs:

| Preset | Limit | Scenario |
|--------|-------|----------|
| Alibaba 20G | 20 GB | Alibaba Cloud |
| Alibaba 200G | 200 GB | Alibaba CDT |
| Alibaba 1T | 1 TB | Alibaba Cloud |
| GCP 200G | 200 GB | Google Cloud |
| GCP 625G | 625 GB | Google Cloud |
| Azure 15G | 15 GB | Azure for Students |
| Azure 115G | 115 GB | Azure for Students |
| Alice 1500G | 1.5 TB | Alice Cloud |
| Asia 300G | 300 GB | Asia Cloud |

## Port Traffic Limits

Set independent traffic limits for specific ports (web server, proxy, SSH, etc.).

### Features

1. **Multi-Port Management** - Monitor/limit multiple ports simultaneously
2. **Independent Statistics** - iptables-based per-port tracking
3. **Real-Time Viewing** - Colored visual interface with progress bars
4. **Flexible Strategies** - TC mode (throttle) or block mode
5. **Push Integration** - Port info included in all notifications

### Via Manager Menu

```
Option 3) Configure Port Traffic Limits → Add/modify ports
Option 6) View Port Traffic Status → See all ports
```

## Useful Commands

```bash
# View logs
sudo tail -f -n 30 /root/TrafficCop/traffic_monitor.log

# View current config
sudo cat /root/TrafficCop/traffic_monitor_config.txt

# Emergency stop all processes
sudo pkill -f trafficcop.sh
```

## FAQ

**Q: Why do my traffic statistics seem inaccurate?**
A: Ensure vnstat has been running long enough to collect accurate data.

**Q: How do I change existing configurations?**
A: Run the manager script again and select option 1.

**Q: How do I completely uninstall?**
```bash
sudo pkill -f trafficcop.sh
sudo rm -rf /root/TrafficCop
sudo tc qdisc del dev $(ip route | grep default | cut -d ' ' -f 5) root
```
