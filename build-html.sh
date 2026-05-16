#!/bin/bash

# 大模型教材 Markdown 转 HTML 构建脚本
# 使用 Sphinx + MyST Parser 直接构建 Markdown 文档

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${PROJECT_DIR}/大模型教材"    # Markdown 源文件
WORKSPACE_DIR="${PROJECT_DIR}/章节"         # Sphinx 工作目录
BUILD_DIR="${PROJECT_DIR}/docs"
VENV_DIR="${PROJECT_DIR}/venv"
STATIC_DIR="${WORKSPACE_DIR}/_static"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 函数：检查并安装依赖
check_dependencies() {
    print_info "检查 Python 环境..."

    if [ ! -d "${VENV_DIR}" ]; then
        print_warning "虚拟环境不存在，创建中..."
        python3 -m venv "${VENV_DIR}"
    fi

    source "${VENV_DIR}/bin/activate"

    # 安装所需扩展
    print_info "安装 Sphinx 扩展..."
    pip install --upgrade pip
    pip install sphinx myst-parser sphinx-book-theme sphinx-copybutton

    python3 -c "import sphinx; print('Sphinx version:', sphinx.__version__)"
}

# 函数：创建静态资源目录
prepare_static() {
    mkdir -p "${STATIC_DIR}"

    # 如果没有 logo，创建一个简单的 SVG
    if [ ! -f "${STATIC_DIR}/logo.png" ]; then
        print_info "创建默认 logo..."
        # 创建简单的占位图
        cat > "${STATIC_DIR}/logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="10" fill="#4285f4"/>
  <text x="50" y="60" font-size="40" text-anchor="middle" fill="white" font-family="Arial">LLM</text>
</svg>
EOF
    fi
}

# 函数：生成 index.rst（入口文件）
generate_index() {
    print_info "生成主索引文件..."

    cat > "${WORKSPACE_DIR}/index.rst" << 'EOF'
.. toctree::
   :maxdepth: 2
   :caption: 目录

   第一章_基础理论篇/index
   第二章_模型架构篇/index
   第三章_应用实践篇/index
   第四章_前沿进展篇/index

# 大模型学习教材

本教材涵盖大模型的基础理论、模型架构、应用实践和前沿进展。

## 使用建议

1. 按顺序学习，先打好理论基础
2. 结合实践案例加深理解
3. 关注最新研究进展
4. 动手实践，不要只看理论
EOF
    print_success "主索引已生成"
}

# 函数：生成各篇的 index.rst
generate_chapter_indexes() {
    local chapters=(
        "01基础理论篇:第一章_基础理论篇"
        "02模型架构篇:第二章_模型架构篇"
        "03应用实践篇:第三章_应用实践篇"
        "04前沿进展篇:第四章_前沿进展篇"
    )

    for chapter in "${chapters[@]}"; do
        IFS=':' read -r dir_name title <<< "$chapter"
        local md_dir="${SOURCE_DIR}/${dir_name}"
        local rst_dir="${WORKSPACE_DIR}/${title}"
        local index_file="${rst_dir}/index.rst"

        mkdir -p "${rst_dir}"

        # 生成篇的 index.rst（使用传统 Sphinx toctree 语法）
        cat > "${index_file}" << EOF
# ${title#*_}

.. toctree::
   :maxdepth: 2

EOF

        # 查找该篇的所有 markdown 文件并添加引用（按文件名排序）
        if [ -d "${md_dir}" ]; then
            # 使用 Python 脚本排序（按文件名中的数字）
            python3 -c "
import os
import re
md_dir = '${md_dir}'
md_files = []
for f in os.listdir(md_dir):
    if f.endswith('.md'):
        match = re.search(r'第(\\d+)章', f)
        if match:
            num = int(match.group(1))
            md_files.append((num, f))
md_files.sort(key=lambda x: x[0])
for num, f in md_files:
    print(f'   {f}')
" >> "${index_file}"
        fi

        print_success "已生成 ${title}/index.rst"
    done
}

# 函数：复制 Markdown 文件到 RST 目录
copy_markdown_files() {
    print_info "复制 Markdown 文件..."

    local chapters=(
        "01基础理论篇:第一章_基础理论篇"
        "02模型架构篇:第二章_模型架构篇"
        "03应用实践篇:第三章_应用实践篇"
        "04前沿进展篇:第四章_前沿进展篇"
    )

    for chapter in "${chapters[@]}"; do
        IFS=':' read -r dir_name title <<< "$chapter"
        local md_dir="${SOURCE_DIR}/${dir_name}"
        local rst_dir="${WORKSPACE_DIR}/${title}"

        if [ -d "${md_dir}" ]; then
            for md_file in "${md_dir}"/*.md; do
                if [ -f "$md_file" ]; then
                    local basename=$(basename "$md_file")
                    cp "$md_file" "${rst_dir}/${basename}"
                fi
            done
        fi
    done

    print_success "Markdown 文件已复制"
}

# 函数：构建 HTML
build_html() {
    print_info "开始构建 HTML 文档..."
    print_info "源目录: ${SOURCE_DIR}"
    print_info "构建目录: ${BUILD_DIR}"

    cd "${WORKSPACE_DIR}"
    source "${VENV_DIR}/bin/activate"

    sphinx-build -b html . "${BUILD_DIR}"

    print_success "HTML 文档构建完成！"
    echo ""
    print_info "访问地址: ${BUILD_DIR}/index.html"
    print_info "GitHub Pages 地址: https://a576378368.github.io/llm-study/"
}

# 函数：清理构建文件
clean() {
    print_info "清理构建文件..."
    rm -rf "${BUILD_DIR}"
    print_success "清理完成"
}

# 函数：重建
rebuild() {
    clean
    generate_index
    generate_chapter_indexes
    copy_markdown_files
    build_html
}

# 函数：显示帮助
show_help() {
    cat << EOF
大模型教材 HTML 构建脚本

用法: $0 [命令]

命令:
    build      构建 HTML 文档（默认）
    rebuild    完整重建（生成索引+复制文件+构建）
    prepare    仅准备文件（生成索引+复制文件）
    clean      清理构建文件
    help       显示此帮助信息

示例:
    $0              # 构建文档
    $0 rebuild      # 完整重建
    $0 prepare      # 仅准备文件
    $0 clean         # 清理

EOF
}

# 主函数
main() {
    case "${1:-build}" in
        build)
            check_dependencies
            prepare_static
            build_html
            ;;
        rebuild)
            check_dependencies
            prepare_static
            rebuild
            ;;
        prepare)
            check_dependencies
            prepare_static
            generate_index
            generate_chapter_indexes
            copy_markdown_files
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
