# 大模型学习教材

一套使用 Sphinx 构建的 HTML 教材，已部署到 GitHub Pages。

## 项目结构

```
llm-study/
├── 大模型教材/        # Markdown 源文件
├── 章节/              # Sphinx 工作目录（自动构建）
├── docs/              # 构建输出（GitHub Pages）
├── build-html.sh      # 构建脚本
├── deploy.sh          # 部署脚本（保留用于测试）
├── .github/workflows/pages.yml  # GitHub Actions 配置
└── README.md
```

## 访问地址

**https://a576378368.github.io/llm-study/**

## 开发

### 本地构建

```bash
cd /home/yang/workspace/llm-study
bash build-html.sh build
```

### 部署流程

1. 修改 `大模型教材/` 目录下的 Markdown 文件
2. 运行 `bash build-html.sh build` 构建
3. 提交代码到 GitHub

GitHub Actions 会自动：
- 拉取代码
- 安装依赖
- 构建 HTML
- 部署到 GitHub Pages

## 构建依赖

- Python 3.12+
- Sphinx
- myst-parser
- sphinx-book-theme
- sphinx-copybutton
