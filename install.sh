#!/bin/bash

# iOS Assets Coder 安装脚本
# 该脚本将编译并安装 ios-assets-coder 到系统的 Go bin 目录

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 检查 Go 是否安装
check_go() {
    if ! command -v go &> /dev/null; then
        print_error "未找到 Go 编译器。请先安装 Go: https://golang.org/dl/"
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}')
    print_info "检测到 Go 版本: $GO_VERSION"
}

# 获取 Go bin 目录
get_go_bin() {
    GO_BIN=$(go env GOPATH)/bin
    if [ -z "$GO_BIN" ]; then
        GO_BIN="$HOME/go/bin"
    fi
    echo "$GO_BIN"
}

# 主函数
main() {
    print_info "开始安装 iOS Assets Coder..."
    
    # 检查 Go 环境
    check_go
    
    # 获取当前目录
    CURRENT_DIR=$(pwd)
    print_info "当前目录: $CURRENT_DIR"
    
    # 检查 main.go 是否存在
    if [ ! -f "main.go" ]; then
        print_error "未找到 main.go 文件，请在项目根目录下运行此脚本"
        exit 1
    fi
    
    # 获取 Go bin 目录
    GO_BIN=$(get_go_bin)
    print_info "Go bin 目录: $GO_BIN"
    
    # 创建 Go bin 目录（如果不存在）
    mkdir -p "$GO_BIN"
    
    # 执行 go install
    print_info "正在编译并安装..."
    if go install .; then
        print_success "安装成功！"
        
        # 检查是否在 PATH 中
        if [[ ":$PATH:" == *":$GO_BIN:"* ]]; then
            print_success "ios-assets-coder 已安装到: $GO_BIN"
            print_info "你现在可以在任何地方使用 'ios-assets-coder' 命令"
        else
            print_success "ios-assets-coder 已安装到: $GO_BIN"
            print_info "请将以下内容添加到你的 shell 配置文件 (~/.bashrc, ~/.zshrc 等):"
            echo ""
            echo "    export PATH=\"\$PATH:$GO_BIN\""
            echo ""
            print_info "然后运行: source ~/.bashrc (或对应的配置文件)"
        fi
        
        # 显示版本信息
        if command -v ios-assets-coder &> /dev/null; then
            echo ""
            print_info "版本信息:"
            ios-assets-coder --version || true
        fi
    else
        print_error "安装失败，请检查错误信息"
        exit 1
    fi
    
    echo ""
    print_success "安装完成！使用 'ios-assets-coder --help' 查看帮助信息"
}

# 运行主函数
main