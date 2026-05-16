# -*- coding: utf-8 -*-

project = '大模型学习教材'
copyright = '2026, yangfeng'
author = 'yangfeng'
release = '1.0'
version = '1.0'
language = 'zh_CN'
master_doc = 'index'

# 扩展配置
extensions = [
    'myst_parser',          # Markdown 支持
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx_copybutton',
]

# MyST Markdown 扩展配置
myst_enable_extensions = [
    'dollarmath',           # $...$ 行内公式
    'amsmath',              # $$...$$ 块级公式
    'deflist',              # 定义列表
    'colon_fence',          # ::: 栅栏
]

# 主题配置
html_theme = 'sphinx_book_theme'
html_title = '大模型学习教材'
html_logo = '_static/logo.png'
html_favicon = '_static/favicon.png'

# 静态文件路径
html_static_path = ['_static']

# 目录深度
numfig = True
