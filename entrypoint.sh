#!/bin/bash
set -e

SOURCE_DIR="${SOURCE_DIR:-/app}"
TARGET_DIR="/home/flutter/projects"
OUTPUT_DIR="/output"

BUILD_MODE="${BUILD_MODE:-release}"
TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
FLAVOR="${FLAVOR:-}"
OBFUSCATE="${OBFUSCATE:-false}"
SHRINK="${SHRINK:-false}"
SPLIT_PER_ABI="${SPLIT_PER_ABI:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK_MARK="✅"
CROSS_MARK="❌"
ARROW="➜"
ROCKET="🚀"
BUILDING="🏗️"
PACKAGE="📦"
FOLDER="📂"
CHART="📊"
GEAR="⚙️"
INFO="ℹ️"
WARNING="⚠️"

# Progress indicator function
show_progress() {
    local message="$1"
    echo -e "${CYAN}${ARROW} ${message}${NC}"
}

# Success message function
show_success() {
    local message="$1"
    echo -e "${GREEN}${CHECK_MARK} ${message}${NC}"
}

# Error message function
show_error() {
    local message="$1"
    echo -e "${RED}${CROSS_MARK} ${message}${NC}"
}

# Info message function
show_info() {
    local message="$1"
    echo -e "${BLUE}${INFO} ${message}${NC}"
}

# Warning message function
show_warning() {
    local message="$1"
    echo -e "${YELLOW}${WARNING} ${message}${NC}"
}

# Build command construction
BUILD_CMD="flutter build apk --${BUILD_MODE} --target-platform=${TARGET_PLATFORM}"

if [ -n "$FLAVOR" ]; then
    BUILD_CMD="$BUILD_CMD --flavor=${FLAVOR}"
fi

if [ "$OBFUSCATE" = "true" ]; then
    BUILD_CMD="$BUILD_CMD --obfuscate --split-debug-info=/app/debug-info"
fi

if [ "$SHRINK" = "true" ]; then
    BUILD_CMD="$BUILD_CMD --shrink"
fi

if [ "$SPLIT_PER_ABI" = "true" ]; then
    BUILD_CMD="$BUILD_CMD --split-per-abi"
fi

# Header
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                     🚀 Flutter APK Builder 🚀               ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Build configuration display
echo -e "${WHITE}${GEAR} Build Configuration:${NC}"
echo -e "${CYAN}   ┌─ Build Mode:      ${YELLOW}${BUILD_MODE}${NC}"
echo -e "${CYAN}   ├─ Target Platform: ${YELLOW}${TARGET_PLATFORM}${NC}"
echo -e "${CYAN}   ├─ Flavor:          ${YELLOW}${FLAVOR:-default}${NC}"
echo -e "${CYAN}   ├─ Obfuscate:       ${YELLOW}${OBFUSCATE}${NC}"
echo -e "${CYAN}   ├─ Shrink:          ${YELLOW}${SHRINK}${NC}"
echo -e "${CYAN}   └─ Split per ABI:   ${YELLOW}${SPLIT_PER_ABI}${NC}"
echo ""

# Environment info
show_info "Current user: $(whoami)"
show_info "Source directory: ${SOURCE_DIR}"
show_info "Target directory: ${TARGET_DIR}"
show_info "Output directory: ${OUTPUT_DIR}"
echo ""

# Step 1: Copy project files
show_progress "Copying project files from ${SOURCE_DIR} to ${TARGET_DIR}..."
if cp -r $SOURCE_DIR/* $TARGET_DIR 2>/dev/null; then
    show_success "Project files copied successfully"
else
    show_error "Failed to copy project files"
    exit 1
fi

# Step 2: Fix permissions
show_progress "Setting correct file permissions..."
if chown -R flutter:flutter /home/flutter/projects; then
    show_success "File permissions updated"
else
    show_warning "Could not update all file permissions (this might be normal)"
fi
echo ""

# Step 3: Navigate to project directory
show_progress "Navigating to project directory..."
cd $TARGET_DIR
show_success "Working directory: $(pwd)"
echo ""

# Step 4: Install dependencies
show_progress "Installing Flutter dependencies..."
if flutter pub get; then
    show_success "Dependencies installed successfully"
else
    show_error "Failed to install dependencies"
    exit 1
fi
echo ""

# Step 5: Build APK
show_progress "Building APK with command:"
echo -e "${YELLOW}${BUILD_CMD}${NC}"
echo ""

if eval $BUILD_CMD; then
    show_success "APK build completed successfully!"
else
    show_error "APK build failed"
    exit 1
fi
echo ""

# Step 6: Copy APK files back
show_progress "Copying APK files to output directory..."
if [ -d "build/app/outputs/apk" ]; then
    cp -r build/app/outputs/apk/* $OUTPUT_DIR/
    show_success "APK files copied to ${OUTPUT_DIR}"
else
    show_error "APK output directory not found"
    exit 1
fi
echo ""

# Step 7: Display results
echo -e "${WHITE}${FOLDER} Generated APK Files:${NC}"

if ls -la $OUTPUT_DIR/*/*.apk 2>/dev/null; then
    echo ""
    echo -e "${WHITE}${CHART} APK File Sizes:${NC}"
    du -h $OUTPUT_DIR/*/*.apk | while read size file; do
        echo -e "${CYAN}   ${size} ${YELLOW}${file}${NC}"
    done
else
    show_warning "No APK files found in output directory"
fi
echo ""

# Footer
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                 ✅ Build Complete ✅                      ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""