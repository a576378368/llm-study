# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 大模型教材编写项目

## 项目概述

这是一个大模型（LLM）学习教材项目，包含四篇共16章内容。源文件使用 Markdown 编写，通过 Sphinx + MyST Parser 构建为 HTML 文档。

## 目录结构

```
llm-study/
├── 大模型教材/              # Markdown 格式教材源文件
│   ├── 01基础理论篇/
│   ├── 02模型架构篇/
│   ├── 03应用实践篇/
│   └── 04前沿进展篇/
├── 章节/                    # Sphinx 工作目录
│   ├── conf.py              # Sphinx 配置
│   ├── index.rst            # 主索引
│   ├── 第一章_基础理论篇/   # 各篇目录（含 index.rst 和 .md 文件）
│   └── _static/             # 静态资源
├── _build/html/             # 构建输出的 HTML 文档
├── build-html.sh            # 主构建脚本
└── venv/                    # Python 虚拟环境
```

## 常用命令

```bash
./build-html.sh          # 构建 HTML（默认）
./build-html.sh rebuild # 完整重建（清理+生成索引+构建）
./build-html.sh prepare # 仅准备文件（生成索引+复制 Markdown）
./build-html.sh clean   # 清理构建文件
```

## 文档构建流程

1. **源文件** → `大模型教材/` 目录（Markdown 格式）
2. **prepare 阶段** → 复制 .md 文件到 `章节/` 各篇目录，生成 index.rst
3. **build 阶段** → Sphinx + MyST Parser 将 Markdown 构建为 HTML

## Sphinx 配置

位于 `章节/conf.py`，主要配置：
- `html_theme = 'sphinx_book_theme'` - 现代书籍主题
- `myst_enable_extensions` - 支持 LaTeX 公式（dollarmath, amsmath）
- `extensions = ['myst_parser', ...]` - Markdown 解析器

## 编写规范

- 公式使用 LaTeX 格式：`$...$` 或 `$$...$$`
- 代码块需标注语法高亮
- 重要概念用**粗体**强调
