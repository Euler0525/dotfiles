# Claude Code Dotfiles

Claude Code 配置备份，包含插件、权限、技能、记忆系统的完整迁移方案。

## 目录结构

```shell
claude-code/
├── README.md
├── install.ps1          # Windows 安装脚本
├── install.sh           # Linux/macOS 安装脚本
├── .gitignore
├── config/
│   ├── settings.json    # 主配置（插件、权限、状态栏）
│   ├── CLAUDE.md        # 全局系统指令
│   └── blocklist.json   # 插件黑名单
├── memory/
│   ├── MEMORY.md        # 记忆索引
│   └── *.md             # 各类记忆文件
└── skills/
    ├── find-skills/           # Skill 发现与安装
    ├── karpathy-guidelines/  # 代码质量指南
    ├── skill-creator/        # Skill 创建工具
    ├── vitis-hls-synthesis/  # Vitis HLS 综合
    ├── vivado-analysis/      # Vivado 时序分析
    ├── vivado-constraints/   # Vivado 约束
    ├── vivado-debug/         # Vivado 调试
    ├── vivado-impl/          # Vivado 实现
    ├── vivado-sim/           # Vivado 仿真
    ├── vivado-synth/         # Vivado 综合
    └── vivado-tcl/           # Vivado TCL
```

## 使用方法

### 新机器恢复

**Windows:**

```powershell
git clone git@github.com:Euler0525/dotfiles.git ~/dotfiles
powershell ~/dotfiles/others/claude-code/install.ps1
```

**Linux/macOS:**

```bash
git clone git@github.com:Euler0525/dotfiles.git ~/dotfiles
~/dotfiles/others/claude-code/install.sh
```

### 恢复后

1. 用 `CC Switch` 配置你的 API Key 和模型
2. 启动 `claude`，插件会自动安装
3. 用 `CC Switch` 或在设置中切换 API 配置

## 安装脚本功能

- 自动检测已有配置，备份旧 `settings.json` 后再覆盖
- 自动替换 settings.json 中的用户路径，适配当前机器的 `$HOME`
- 恢复完成后显示摘要（插件数、skills 数、记忆文件数）

## 隐私说明

- 本仓库 **不包含** 任何 API Token 或密钥
- 请在新机器上通过 `CC Switch` 自行配置 API 密钥
- 推送前请确认未将包含敏感信息的文件加入版本管理
