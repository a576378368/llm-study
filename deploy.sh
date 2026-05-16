#!/bin/bash

# 静态部署脚本 - 将构建好的 HTML 部署到 GitHub Pages

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/_build/html"
DOCS_DIR="${PROJECT_DIR}/docs"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 函数：清理 docs 目录
clean_docs() {
    print_info "清理 docs 目录..."
    rm -rf "${DOCS_DIR}"
    mkdir -p "${DOCS_DIR}"
    print_success "docs 目录已清理"
}

# 函数：复制 HTML 到 docs
deploy_html() {
    print_info "复制 HTML 文件到 docs 目录..."
    
    if [ ! -d "${BUILD_DIR}" ]; then
        print_warning "构建目录不存在，正在构建..."
        cd "${PROJECT_DIR}"
        bash build-html.sh build
    fi
    
    cp -r "${BUILD_DIR}"/* "${DOCS_DIR}/"
    print_success "HTML 文件已复制到 docs 目录"
}

# 函数：显示部署信息
show_info() {
    echo ""
    print_info "=== 部署完成 ==="
    echo "本地预览: ${DOCS_DIR}/index.html"
    echo "GitHub Pages: https://a576378368.github.io/llm-study/"
    echo ""
    print_info "提交并推送 docs 目录到 GitHub:"
    echo "  git add docs"
    echo "  git commit -m '更新网站'"
    echo "  git push"
}

# 主函数
main() {
    clean_docs
    deploy_html
    show_info
}

main "$@"
