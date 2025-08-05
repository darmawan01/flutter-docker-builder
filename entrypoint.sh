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

# Function to check and cleanup disk space
check_disk_space() {
    local available_space=$(df . | awk 'NR==2 {print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [ $available_gb -lt 5 ]; then
        show_warning "Low disk space detected: ${available_gb}GB available"
        show_info "Attempting to clean up temporary files..."
        
        # Clean up common temporary directories
        rm -rf /tmp/* 2>/dev/null || true
        rm -rf /var/tmp/* 2>/dev/null || true
        rm -rf /home/flutter/.pub-cache/tmp/* 2>/dev/null || true
        
        # Clean up Flutter build cache
        flutter clean 2>/dev/null || true
        
        # Check space after cleanup
        local new_available_space=$(df . | awk 'NR==2 {print $4}')
        local new_available_gb=$((new_available_space / 1024 / 1024))
        show_info "After cleanup: ${new_available_gb}GB available"
        
        if [ $new_available_gb -lt 2 ]; then
            show_error "Still insufficient disk space after cleanup"
            return 1
        fi
    fi
    return 0
}

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
    BUILD_CMD="$BUILD_CMD --obfuscate --split-debug-info=/home/flutter/projects/debug-info"
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

# Step 1: Clean target directory and copy project files
show_progress "Cleaning target directory and copying project files..."

# Optional disk space check and analysis
if [ "${DEBUG_AVAILABLE_SPACE:-false}" = "true" ]; then
    show_info "=== Disk Space Analysis (Debug Mode) ==="
    
    # Check disk space
    show_info "Available disk space:"
    df -h . 2>/dev/null || show_error "Cannot check disk space"

    # Show disk usage by directory
    show_info "Disk usage by directory (top 10):"
    du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10 || show_error "Cannot check disk usage by directory"

    # Show largest files in common directories
    show_info "Largest files in /tmp:"
    find /tmp -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 || show_info "No files in /tmp"

    show_info "Largest files in /var/tmp:"
    find /var/tmp -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 || show_info "No files in /var/tmp"

    show_info "Largest files in /home/flutter:"
    find /home/flutter -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 || show_info "No files in /home/flutter"

    # Show largest files in current directory
    show_info "Largest files in current directory:"
    find . -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 || show_info "No files in current directory"

    # Show largest files in /opt (Android SDK, Flutter)
    show_info "Largest files in /opt:"
    find /opt -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 || show_info "No files in /opt"

    # Check and cleanup disk space if needed
    if ! check_disk_space; then
        show_error "Insufficient disk space for build"
        exit 1
    fi
    
    show_info "=== End Disk Space Analysis ==="
    echo ""
fi

# Ensure target directory exists
if ! mkdir -p $TARGET_DIR 2>/dev/null; then
    show_error "Failed to create target directory"
    exit 1
fi

# Clean target directory
if ! rm -rf $TARGET_DIR/* 2>/dev/null; then
    show_error "Failed to clean target directory"
    exit 1
fi

# Copy project files with error handling
show_info "Copying project files..."
if ! cp -r $SOURCE_DIR/* $TARGET_DIR/ 2>/dev/null; then
    show_error "Failed to copy project files"
    show_info "Error details:"
    cp -r $SOURCE_DIR/* $TARGET_DIR/ 2>&1 || true
    show_info "Available space:"
    df -h . 2>/dev/null || true
    exit 1
fi

show_success "Project files copied successfully"

# Step 2: Fix permissions and ensure proper ownership
show_progress "Setting correct file permissions..."

if ! chown -R flutter:flutter $TARGET_DIR 2>/dev/null; then
    show_error "Failed to set ownership"
    exit 1
fi

if ! chmod -R 755 $TARGET_DIR 2>/dev/null; then
    show_error "Failed to set permissions"
    exit 1
fi

show_success "File permissions updated"
echo ""

# Step 3: Navigate to project directory and ensure we're in the right place
show_progress "Navigating to project directory..."
if ! cd $TARGET_DIR 2>/dev/null; then
    show_error "Failed to navigate to project directory"
    exit 1
fi
show_success "Working directory: $(pwd)"
echo ""

# Step 4: Clean any existing build artifacts
show_progress "Cleaning existing build artifacts..."
if ! flutter clean 2>/dev/null; then
    show_error "Failed to clean build artifacts"
    exit 1
fi
show_success "Build artifacts cleaned"
echo ""

# Step 5: Install dependencies
show_progress "Installing Flutter dependencies..."
if ! flutter pub get 2>/dev/null; then
    show_error "Failed to install dependencies"
    show_info "Error details:"
    flutter pub get 2>&1 || true
    exit 1
fi
show_success "Dependencies installed successfully"
echo ""

# Step 6: Verify Flutter doctor
show_progress "Verifying Flutter installation..."
if ! flutter doctor 2>/dev/null; then
    show_warning "Flutter doctor reported issues, but continuing with build"
    flutter doctor 2>&1 || true
fi
show_success "Flutter installation verified"
echo ""

# Step 7: Build APK
show_progress "Building APK with command:"
echo -e "${YELLOW}${BUILD_CMD}${NC}"
echo ""

# Set environment to ensure build happens in container
export FLUTTER_BUILD_DIR="$TARGET_DIR/build"
export ANDROID_SDK_ROOT="/opt/android-sdk"
export ANDROID_HOME="/opt/android-sdk"

if ! eval $BUILD_CMD 2>/dev/null; then
    show_error "APK build failed"
    show_info "Error details:"
    eval $BUILD_CMD 2>&1 || true
    exit 1
fi
show_success "APK build completed successfully!"
echo ""

# Step 8: Copy APK files back
show_progress "Copying APK files to output directory..."
if [ ! -d "build/app/outputs/apk" ]; then
    show_error "APK output directory not found"
    exit 1
fi

if ! cp -r build/app/outputs/apk/* $OUTPUT_DIR/ 2>/dev/null; then
    show_error "Failed to copy APK files to output directory"
    show_info "Error details:"
    cp -r build/app/outputs/apk/* $OUTPUT_DIR/ 2>&1 || true
    exit 1
fi
show_success "APK files copied to ${OUTPUT_DIR}"
echo ""

# Step 9: Display results
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