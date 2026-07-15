# TrafficCop - 智能流量监控与限制脚本

[English](README_EN.md) | 中文

## 一键安装

```bash
bash <(curl -sL https://raw.githubusercontent.com/GomoXU/TrafficMonitor/main/trafficcop-manager.sh)
```

**一行命令，进去自己选功能。**

安装后你会看到一个交互菜单，选择你需要的功能即可：

| 选项 | 功能 | 说明 |
|------|------|------|
| `1` | 配置/修改流量监控 | 流量统计、限速、关机保护 |
| `2` | 配置推送通知 | Telegram / PushPlus / Server酱 |
| `3` | 配置端口流量限制 | 为指定端口设置独立限额 |
| `4` | 机器限速管理 | 临时启用/禁用限速 |
| `5` | 使用预设配置 | 阿里云/Azure/GCP 等一键配置 |
| `6` | 查看端口流量状态 | 实时监控各个端口 |
| `7-8` | 查看日志和配置 | |
| `9` | 停止所有服务 | |
| `10` | 更新所有脚本 | 保持最新 |

## 注意事项

1. 本脚本是基于vnstat的流量统计，vnstat只会在安装后开始统计流量!
2. TC模式无法防止DDoS消耗流量，流量消耗速度仍然较快！
3. 脚本默认使用root权限运行。如需非root用户运行，请确保该用户有sudo权限。
4. 如果遇到问题，可以查看日志文件 (`/root/TrafficCop/traffic_monitor.log`) 获取更多信息。
5. 建议定期备份配置文件 (`traffic_monitor_config.txt`)。

## 脚本逻辑

- 自动检测并选择主要网卡进行流量限制
- 用户选择流量统计模式（四种选项）
- 用户设置流量计算周期（月/季/年）和起始日期
- 用户输入流量限制和容错范围
- 用户选择限制模式（TC模式或关机模式）
- 脚本每分钟检测流量消耗，达到限制时执行相应操作
- 在新的流量周期开始时自动解除限制

## 脚本特色

- 四种全面的流量统计模式，适应各种VPS计费方式
- 自定义流量计算周期和起始日
- 自定义流量容错范围
- 交互式配置，可随时修改参数
- 实时流量统计提示
- TC模式保证SSH连接可用
- 关机模式提供更严格的流量控制

## 推送通知

TrafficCop 支持以下推送方式：

- **Telegram Bot** - 发送限速警告、解除通知、每日流量报告等
- **PushPlus** - 微信推送
- **Server酱** - 微信推送

在配置菜单中选择对应选项，按提示输入 Token 即可。

## 预设配置

通过脚本菜单的选项 `5` 即可使用预设配置，支持：

| 预设 | 流量限制 | 适用场景 |
|------|---------|---------|
| 阿里云 20G | 20 GB | 阿里云轻量 |
| 阿里云 200G | 200 GB | 阿里云CDT |
| 阿里云 1T | 1 TB | 阿里云轻量 |
| GCP 200G | 200 GB | Google Cloud |
| GCP 625G | 625 GB | Google Cloud |
| Azure 15G | 15 GB | Azure学生 |
| Azure 115G | 115 GB | Azure学生 |
| Alice 1500G | 1.5 TB | Alice云 |
| 亚洲云 300G | 300 GB | 亚洲云 |

## 端口流量限制

TrafficCop 支持为多个端口设置独立的流量限制，适合对特定服务（如Web服务器、代理服务、SSH等）进行精细化流量管理。

### 功能特点

1. **多端口流量管理** - 同时监控和限制多个端口的流量
2. **独立端口流量统计** - 使用iptables精确统计每个端口的入站和出站流量
3. **实时流量查看** - 彩色可视化界面，显示所有端口的流量使用情况和进度条
4. **灵活的限制策略** - TC模式（限速）或阻断模式（完全阻断）
5. **推送通知集成** - 所有推送服务自动包含端口流量信息

### 通过管理器菜单操作

```
选项 3) 配置端口流量限制 → 添加/修改端口配置
选项 6) 查看端口流量状态 → 查看所有端口实时流量
```

### 配置文件

JSON格式，存储在 `/root/TrafficCop/ports_traffic_config.json`

## 实用命令

```bash
# 查看日志
sudo tail -f -n 30 /root/TrafficCop/traffic_monitor.log

# 查看当前配置
sudo cat /root/TrafficCop/traffic_monitor_config.txt

# 紧急停止所有进程
sudo pkill -f traffic_monitor.sh
```

## 常见问题

**Q: 为什么我的流量统计似乎不准确？**
A: 确保vnstat已正确安装并运行一段时间。新安装的vnstat需要时间来收集准确的数据。

**Q: 如何更改已设置的配置？**
A: 重新运行 `bash <(curl -sL url)` 进入菜单，选择选项1即可修改。

**Q: TC模式下SSH连接变慢怎么办？**
A: 尝试增加TC模式下的速度限制值。

**Q: 如何完全卸载？**
```bash
sudo pkill -f trafficcop.sh
sudo rm -rf /root/TrafficCop
sudo tc qdisc del dev $(ip route | grep default | cut -d ' ' -f 5) root
```
