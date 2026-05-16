#!/bin/bash

# 从 Markdown 生成 RST 文件的辅助脚本
# 用于将教材大纲转换为 Sphinx 可识别的 RST 格式

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 项目配置
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_MD="${WORKSPACE_DIR}/大模型教材大纲.md"
CHAPTER_DIR="${WORKSPACE_DIR}/章节"

# 从原始 Markdown 生成 RST 的函数
generate_from_markdown() {
    print_info "读取 Markdown 文件..."

    if [ ! -f "${SOURCE_MD}" ]; then
        print_error "找不到 ${SOURCE_MD}"
        exit 1
    fi

    # 读取整个文件
    markdown_content=$(cat "${SOURCE_MD}")

    # 第一篇
    print_info "生成第一章 RST..."
    cat > "${CHAPTER_DIR}/第一章_基础理论篇/index.rst" << 'EOF'
第一章: 基础理论篇
====================

本篇约8万字

.. toctree::
   :maxdepth: 1

EOF

    # 第二篇
    print_info "生成第二章 RST..."
    cat > "${CHAPTER_DIR}/第二章_模型架构篇/index.rst" << 'EOF'
第二章: 模型架构篇
==============

本篇约10万字

.. toctree::
   :maxdepth: 1

EOF

    # 第三篇
    print_info "生成第三章 RST..."
    cat > "${CHAPTER_DIR}/第三章_应用实践篇/index.rst" << 'EOF'
第三章: 应用实践篇
==============

本篇约8万字

.. toctree::
   :maxdepth: 1

EOF

    # 第四篇
    print_info "生成第四章 RST..."
    cat > "${CHAPTER_DIR}/第四章_前沿进展篇/index.rst" << 'EOF'
第四章: 前沿进展篇
==============

本篇约4万字

.. toctree::
   :maxdepth: 1

EOF

    # 主索引
    print_info "生成主索引..."
    cat > "${CHAPTER_DIR}/index.rst" << 'EOF'
# 大模型学习教材

.. toctree::
   :maxdepth: 2

第一章_基础理论篇/index
第二章_模型架构篇/index
第三章_应用实践篇/index
第四章_前沿进展篇/index

## 使用建议

1. 按顺序学习，先打好理论基础
2. 结合实践案例加深理解
3. 关注最新研究进展
4. 动手实践，不要只看理论
EOF

    print_success "RST 文件生成完成！"
    echo ""
    print_info "文件位置: ${CHAPTER_DIR}"
}

# 显示帮助
show_help() {
    cat << EOF
Markdown 转 RST 生成器

用法: $0

功能:
    从大模型教材大纲.md 生成章节的 RST 文件

输出:
    ${CHAPTER_DIR}/
    ├── index.rst (主索引)
    ├── 第一章_基础理论篇/
    │   └── index.rst
    ├── 第二章_模型架构篇/
    │   └── index.rst
    ├── 第三章_应用实践篇/
    │   └── index.rst
    └── 第四章_前沿进展篇/
        └── index.rst

后续步骤:
    运行 ./build-html.sh 生成 HTML 文档

EOF
}

# 主函数
main() {
    if [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_help
        exit 0
    fi

    generate_from_markdown
}

main "$@"