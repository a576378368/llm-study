# 大模型学习教材 - HTML 构建工具

[查看在线文档](https://a576378368.github.io/llm-study/)

这是一套用于将 Markdown 格式的教材转换为 HTML 文档的自动化脚本工具。

## 功能特性

- ✅ 自动检测和安装 Python 环境
- ✅ 自动管理虚拟环境
- ✅ 自动安装 Sphinx 依赖
- ✅ 支持增量构建
- ✅ 生成美观的 HTML 文档
- ✅ 包含搜索和索引功能

## 快速开始

### 1. 生成 RST 文件

如果还没有 RST 文件，先运行生成脚本：

```bash
./generate-rst.sh
```

### 2. 构建 HTML 文档

构建 HTML 文档：

```bash
./build-html.sh build
```

### 3. 查看文档

在浏览器中打开：

```bash
open _build/html/index.html
# 或
xdg-open _build/html/index.html
```

## 命令说明

### build-html.sh

主要构建脚本，支持以下命令：

| 命令 | 说明 |
|------|------|
| `build` | 构建HTML文档（默认） |
| `rebuild` | 清理后重新构建 |
| `clean` | 清理构建文件 |
| `index` | 生成章节索引 |
| `help` | 显示帮助信息 |

### generate-rst.sh

辅助脚本，用于从 Markdown 生成 RST 格式的文档：

```bash
./generate-rst.sh
```

## 目录结构

```
workspace/
├── build-html.sh              # 主构建脚本
├── generate-rst.sh            # RST 生成脚本
├── README.md                  # 本文档
├── conf.py                    # Sphinx 配置文件
├── index.rst                  # 主索引文件
├── 章节/                      # 源文档目录
│   ├── index.rst              # 章节索引
│   ├── 第一章_基础理论篇/
│   │   ├── index.rst
│   │   └── 1.1_机器学习基础回顾.rst
│   ├── 第二章_模型架构篇/
│   │   ├── index.rst
│   │   └── ...
│   ├── 第三章_应用实践篇/
│   └── 第四章_前沿进展篇/
├── _build/                    # 构建输出目录
│   └── html/
│       ├── index.html
│       ├── 第一章_基础理论篇/
│       └── ...
└── venv/                      # Python 虚拟环境
```

## 配置说明

### Sphinx 配置 (conf.py)

```python
project = u'大模型学习教材'
copyright = u'2026, Claude Code'
author = u'Claude Code'
release = '1.0'

html_theme = 'alabaster'  # 主题
```

### 自定义主题

如需使用其他主题（如 furo、sphinx_rtd_theme），请在 `conf.py` 中修改 `html_theme`：

```python
html_theme = 'furo'  # 推荐：现代简洁
# html_theme = 'sphinx_rtd_theme'  # Read the Docs 主题
```

## 常见问题

### 1. 警告信息

构建时可能出现一些警告（如标题下划线不匹配），这不会影响文档生成，可以忽略。

### 2. 主题缺失

如果使用 `furo` 等主题，需要先安装：

```bash
pip install sphinx-rtd-theme
```

### 3. 清理构建

如果需要完全重新构建：

```bash
./build-html.sh rebuild
```

## 工作流程

1. **编写 Markdown** - 在 `章节/` 目录下编写 RST 文件
2. **生成索引** - 使用 `index` 命令更新索引
3. **构建文档** - 运行 `build` 命令生成 HTML
4. **查看效果** - 在浏览器中预览

## 相关工具

- **Sphinx** - Python 文档生成工具
- **Alabaster** - 简洁美观的默认主题
- **Python venv** - 虚拟环境管理

## 技术支持

如有问题，请检查：
1. Python 版本 >= 3.7
2. 网络连接（用于安装依赖）
3. 文件权限

---

**版本**: 1.0
**更新时间**: 2026-05-09