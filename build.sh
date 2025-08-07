#!/bin/bash

# iOS Assets Coder 构建脚本
# 该脚本用于构建不同平台的可执行文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_building() {
    echo -e "${BLUE}🔨 $1${NC}"
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

# 创建输出目录
create_output_dir() {
    OUTPUT_DIR="dist"
    if [ -d "$OUTPUT_DIR" ]; then
        print_info "清理旧的构建文件..."
        rm -rf "$OUTPUT_DIR"
    fi
    mkdir -p "$OUTPUT_DIR"
    print_success "创建输出目录: $OUTPUT_DIR"
}

# 构建单个平台
build_platform() {
    local GOOS=$1
    local GOARCH=$2
    local OUTPUT_NAME=$3
    
    print_building "构建 $GOOS/$GOARCH..."
    
    GOOS=$GOOS GOARCH=$GOARCH go build \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/$OUTPUT_NAME" \
        main.go
    
    if [ $? -eq 0 ]; then
        # 获取文件大小
        SIZE=$(du -h "$OUTPUT_DIR/$OUTPUT_NAME" | cut -f1)
        print_success "构建成功: $OUTPUT_NAME (大小: $SIZE)"
    else
        print_error "构建失败: $GOOS/$GOARCH"
        return 1
    fi
}

# 压缩文件
compress_file() {
    local FILE=$1
    local ARCHIVE=$2
    
    print_info "压缩: $ARCHIVE"
    
    cd "$OUTPUT_DIR"
    if [[ "$ARCHIVE" == *.zip ]]; then
        zip -q "$ARCHIVE" "$(basename $FILE)"
    else
        tar -czf "$ARCHIVE" "$(basename $FILE)"
    fi
    cd ..
    
    # 删除原始文件，只保留压缩包
    rm "$OUTPUT_DIR/$FILE"
    
    SIZE=$(du -h "$OUTPUT_DIR/$ARCHIVE" | cut -f1)
    print_success "压缩完成: $ARCHIVE (大小: $SIZE)"
}

# 主函数
main() {
    print_info "开始构建 iOS Assets Coder..."
    echo ""
    
    # 检查 Go 环境
    check_go
    echo ""
    
    # 检查 main.go 是否存在
    if [ ! -f "main.go" ]; then
        print_error "未找到 main.go 文件，请在项目根目录下运行此脚本"
        exit 1
    fi
    
    # 创建输出目录
    create_output_dir
    echo ""
    
    # 获取版本信息（如果可能）
    VERSION="latest"
    if [ -n "$1" ]; then
        VERSION=$1
        print_info "版本号: $VERSION"
        echo ""
    fi
    
    # 构建不同平台的版本
    print_info "开始构建多平台版本..."
    echo ""
    
    # macOS (Intel)
    if build_platform "darwin" "amd64" "ios-assets-coder-darwin-amd64"; then
        compress_file "ios-assets-coder-darwin-amd64" "ios-assets-coder-darwin-amd64-$VERSION.tar.gz"
    fi
    echo ""
    
    # macOS (Apple Silicon)
    if build_platform "darwin" "arm64" "ios-assets-coder-darwin-arm64"; then
        compress_file "ios-assets-coder-darwin-arm64" "ios-assets-coder-darwin-arm64-$VERSION.tar.gz"
    fi
    echo ""
    
    # Linux (amd64)
    if build_platform "linux" "amd64" "ios-assets-coder-linux-amd64"; then
        compress_file "ios-assets-coder-linux-amd64" "ios-assets-coder-linux-amd64-$VERSION.tar.gz"
    fi
    echo ""
    
    # Linux (arm64)
    if build_platform "linux" "arm64" "ios-assets-coder-linux-arm64"; then
        compress_file "ios-assets-coder-linux-arm64" "ios-assets-coder-linux-arm64-$VERSION.tar.gz"
    fi
    echo ""
    
    # Windows (amd64)
    if build_platform "windows" "amd64" "ios-assets-coder-windows-amd64.exe"; then
        compress_file "ios-assets-coder-windows-amd64.exe" "ios-assets-coder-windows-amd64-$VERSION.zip"
    fi
    echo ""
    
    # Windows (arm64)
    if build_platform "windows" "arm64" "ios-assets-coder-windows-arm64.exe"; then
        compress_file "ios-assets-coder-windows-arm64.exe" "ios-assets-coder-windows-arm64-$VERSION.zip"
    fi
    echo ""
    
    # 显示构建结果
    print_success "构建完成！"
    echo ""
    print_info "构建产物位于 $OUTPUT_DIR 目录:"
    ls -lh "$OUTPUT_DIR"
    echo ""
    
    # 构建当前平台的可执行文件用于测试
    print_info "构建当前平台的可执行文件..."
    go build -o ios-assets-coder main.go
    print_success "本地可执行文件: ./ios-assets-coder"
    
    # 显示帮助信息
    echo ""
    print_info "使用方法:"
    echo "  ./ios-assets-coder --help"
}

# 运行主函数，传递版本参数
main "$@"