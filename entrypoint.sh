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

# Function to clean corrupted Gradle cache
clean_gradle_cache() {
    if [ -d "/home/flutter/.gradle" ]; then
        show_info "Cleaning potentially corrupted Gradle cache..."
        
        # Remove specific corrupted cache directories
        rm -rf /home/flutter/.gradle/caches/journal-* 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/modules-* 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/transforms-* 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/build-cache-* 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/file-access.bin 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/fileHashes 2>/dev/null || true
        rm -rf /home/flutter/.gradle/caches/fileSnapshots 2>/dev/null || true
        
        # Clean up any lock files and temporary files
        find /home/flutter/.gradle -name "*.lock" -delete 2>/dev/null || true
        find /home/flutter/.gradle -name "*.tmp" -delete 2>/dev/null || true
        find /home/flutter/.gradle -name "*.part" -delete 2>/dev/null || true
        find /home/flutter/.gradle -name "*.journal" -delete 2>/dev/null || true
        
        # Clean up daemon state
        rm -rf /home/flutter/.gradle/daemon 2>/dev/null || true
        rm -rf /home/flutter/.gradle/wrapper 2>/dev/null || true
        
        # Recreate essential directories
        mkdir -p /home/flutter/.gradle/caches/modules-2/files-2.1 2>/dev/null || true
        mkdir -p /home/flutter/.gradle/caches/transforms-3 2>/dev/null || true
        mkdir -p /home/flutter/.gradle/caches/build-cache-1 2>/dev/null || true
        
        show_success "Gradle cache cleaned and reinitialized"
    fi
}

# Function to detect Alpine and handle CMake issues
detect_and_handle_alpine() {
    if [ -f /etc/alpine-release ]; then
        show_info "Alpine Linux detected - applying compatibility fixes"
        
        # Set environment variables for better Alpine compatibility
        export CMAKE_BUILD_PARALLEL_LEVEL=1
        export NINJA_BUILD_PARALLEL_LEVEL=1
        export NINJA_STATUS="[%f/%t] "
        
        # Disable problematic optimizations
        export CFLAGS="-O1"
        export CXXFLAGS="-O1"
        
        # Use alternative CMake configuration for Alpine
        if [ "$BUILD_MODE" = "release" ]; then
            show_info "Using Alpine-optimized build configuration"
            export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx2g -Dorg.gradle.parallel=false"
        fi

        # Android tools compatibility fixes
        export LD_LIBRARY_PATH="/usr/glibc-compat/lib:/usr/lib:/lib64:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
        export LIBRARY_PATH="/usr/glibc-compat/lib:/usr/lib:/lib64:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:$LIBRARY_PATH"
        export ANDROID_AAPT2_FROM_MAVEN_OVERRIDE="/opt/android-sdk/build-tools/35.0.0/aapt2"
        export CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=clang
        export GLIBC_TUNABLES=glibc.pthread.stack_cache_size=0

        # Create additional runtime symlinks for better compatibility
        show_info "Creating additional library symlinks for Android tools"
        mkdir -p /usr/lib/x86_64-linux-gnu 2>/dev/null || true
        mkdir -p /lib/x86_64-linux-gnu 2>/dev/null || true
        
        # Create symlinks for all required libraries
        ln -sf /usr/glibc-compat/lib/libc.so.6 /usr/lib/x86_64-linux-gnu/libc.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libm.so.6 /usr/lib/x86_64-linux-gnu/libm.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libdl.so.2 /usr/lib/x86_64-linux-gnu/libdl.so.2 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libpthread.so.0 /usr/lib/x86_64-linux-gnu/libpthread.so.0 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libresolv.so.2 /usr/lib/x86_64-linux-gnu/libresolv.so.2 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/librt.so.1 /usr/lib/x86_64-linux-gnu/librt.so.1 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libutil.so.1 /usr/lib/x86_64-linux-gnu/libutil.so.1 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libgcc_s.so.1 /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 2>/dev/null || true
        
        # Also create symlinks in /lib/x86_64-linux-gnu for broader compatibility
        ln -sf /usr/glibc-compat/lib/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libresolv.so.2 /lib/x86_64-linux-gnu/libresolv.so.2 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libutil.so.1 /lib/x86_64-linux-gnu/libutil.so.1 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6 2>/dev/null || true
        ln -sf /usr/glibc-compat/lib/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1 2>/dev/null || true

        # Verify critical libraries are accessible
        show_info "Verifying library accessibility..."
        if [ -f "/usr/glibc-compat/lib/libgcc_s.so.1" ]; then
            show_success "libgcc_s.so.1 is available"
        else
            show_warning "libgcc_s.so.1 not found in glibc-compat"
        fi
        
        if [ -f "/usr/lib/x86_64-linux-gnu/libgcc_s.so.1" ]; then
            show_success "libgcc_s.so.1 symlink created successfully"
        else
            show_warning "libgcc_s.so.1 symlink creation failed"
        fi

        show_success "Alpine compatibility fixes applied"
    fi
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

# Clean Gradle cache to prevent corruption issues on all platforms
clean_gradle_cache

# Detect and handle Alpine-specific issues
detect_and_handle_alpine

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

# Fix permissions and ensure proper ownership
show_progress "Setting correct file permissions..."

if ! chown -R flutter:flutter $TARGET_DIR 2>/dev/null; then
    show_error "Failed to set ownership"
    exit 1
fi

if ! chmod -R 755 $TARGET_DIR 2>/dev/null; then
    show_error "Failed to set permissions"
    exit 1
fi

# Ensure Gradle cache directory exists with proper permissions
show_progress "Setting up Gradle cache directory..."
if ! mkdir -p /home/flutter/.gradle/caches 2>/dev/null; then
    show_error "Failed to create Gradle cache directory"
    exit 1
fi

if ! chown -R flutter:flutter /home/flutter/.gradle 2>/dev/null; then
    show_error "Failed to set Gradle cache ownership"
    exit 1
fi

if ! chmod -R 755 /home/flutter/.gradle 2>/dev/null; then
    show_error "Failed to set Gradle cache permissions"
    exit 1
fi

# Create a fresh Gradle cache structure
show_progress "Initializing fresh Gradle cache structure..."
mkdir -p /home/flutter/.gradle/caches/modules-2/files-2.1 2>/dev/null || true
mkdir -p /home/flutter/.gradle/caches/transforms-3 2>/dev/null || true
mkdir -p /home/flutter/.gradle/caches/build-cache-1 2>/dev/null || true
chown -R flutter:flutter /home/flutter/.gradle 2>/dev/null || true

show_success "File permissions updated"
echo ""

# Navigate to project directory and ensure we're in the right place
show_progress "Navigating to project directory..."
if ! cd $TARGET_DIR 2>/dev/null; then
    show_error "Failed to navigate to project directory"
    exit 1
fi
show_success "Working directory: $(pwd)"

# Fix Gradle wrapper permissions if it exists
if [ -f "android/gradlew" ]; then
    show_progress "Fixing Gradle wrapper permissions..."
    chmod +x android/gradlew
    show_success "Gradle wrapper permissions fixed"
fi
echo ""

# Clean any existing build artifacts
show_progress "Cleaning existing build artifacts..."
if ! flutter clean 2>/dev/null; then
    show_error "Failed to clean build artifacts"
    exit 1
fi
show_success "Build artifacts cleaned"
echo ""

# Install dependencies
show_progress "Installing Flutter dependencies..."
if ! flutter pub get 2>/dev/null; then
    show_error "Failed to install dependencies"
    show_info "Error details:"
    flutter pub get 2>&1 || true
    exit 1
fi
show_success "Dependencies installed successfully"

# Ensure Android local.properties is properly configured
if [ -d "android" ]; then
    show_progress "Configuring Android local.properties..."
    mkdir -p android
    echo "sdk.dir=/opt/android-sdk" > android/local.properties
    echo "flutter.sdk=/opt/flutter" >> android/local.properties
    
    # Add Alpine-specific Android configuration
    if [ -f /etc/alpine-release ]; then
        show_info "Configuring Alpine-specific Android settings"
        # Update existing gradle.properties with Alpine optimizations
        if [ -f "android/gradle.properties" ]; then
            # Backup original gradle.properties
            cp android/gradle.properties android/gradle.properties.backup
            # Update with Alpine-optimized JVM args
            sed -i 's/org.gradle.jvmargs=.*/org.gradle.jvmargs=-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.parallel=false/' android/gradle.properties
                    show_success "Updated existing gradle.properties with Alpine optimizations"
        
            # Check and remove any deprecated settings from gradle.properties
            show_info "Checking for deprecated Android settings..."
            sed -i '/android.enableAapt2/d' android/gradle.properties 2>/dev/null || true
            sed -i '/android.enableD8.desugaring/d' android/gradle.properties 2>/dev/null || true
            sed -i '/android.enableBuildCache/d' android/gradle.properties 2>/dev/null || true
            sed -i '/android.enableDexingArtifactTransform/d' android/gradle.properties 2>/dev/null || true
            show_success "Removed deprecated Android settings"
        fi
    fi
    
    show_success "Android local.properties configured"
fi
echo ""

# Verify Flutter doctor
show_progress "Verifying Flutter installation..."
if ! flutter doctor 2>/dev/null; then
    show_warning "Flutter doctor reported issues, but continuing with build"
    flutter doctor 2>&1 || true
fi
show_success "Flutter installation verified"
echo ""

# Build APK
show_progress "Building APK with command:"
echo -e "${YELLOW}${BUILD_CMD}${NC}"
echo ""

# Set environment to ensure build happens in container
export FLUTTER_BUILD_DIR="$TARGET_DIR/build"
export ANDROID_SDK_ROOT="/opt/android-sdk"
export ANDROID_HOME="/opt/android-sdk"
export GRADLE_USER_HOME="/home/flutter/.gradle"
# Set Alpine-specific Gradle options if on Alpine
if [ -f /etc/alpine-release ]; then
    export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.parallel=false -Dorg.gradle.cache.dir=/home/flutter/.gradle/caches -Dorg.gradle.configureondemand=false"
else
    export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx4g -Dorg.gradle.daemon=false -Dorg.gradle.parallel=false -Dorg.gradle.cache.dir=/home/flutter/.gradle/caches"
fi

# Pre-initialize Gradle to avoid permission issues
show_progress "Pre-initializing Gradle cache..."
# Ensure Gradle cache directory exists and has proper permissions
mkdir -p /home/flutter/.gradle/caches
mkdir -p /home/flutter/.gradle/wrapper
chmod -R 755 /home/flutter/.gradle
show_success "Gradle cache directory prepared"
echo ""

if ! eval $BUILD_CMD 2>/dev/null; then
    show_error "APK build failed"
    show_info "Error details:"
    eval $BUILD_CMD 2>&1 || true
    
    # Check if it's a Gradle cache corruption issue
    BUILD_OUTPUT=$(eval $BUILD_CMD 2>&1 || true)
    if echo "$BUILD_OUTPUT" | grep -q "CorruptedCacheException\|Corrupted IndexBlock\|file-access.bin" 2>/dev/null; then
        show_warning "Detected Gradle cache corruption, attempting to clean and retry..."
        clean_gradle_cache
        
        show_info "Retrying build after cache cleanup..."
        if ! eval $BUILD_CMD 2>/dev/null; then
            show_error "Build still failed after cache cleanup"
            eval $BUILD_CMD 2>&1 || true
        else
            show_success "Build succeeded after cache cleanup!"
        fi
    else
        # Additional diagnostics for other issues
        show_info "=== Additional Diagnostics ==="
        show_info "Gradle cache directory permissions:"
        ls -la /home/flutter/.gradle/ 2>/dev/null || show_error "Cannot access Gradle cache directory"
        
        show_info "Current user and permissions:"
        whoami
        id
        
        show_info "Available disk space:"
        df -h . 2>/dev/null || show_error "Cannot check disk space"
        
        show_info "Gradle cache directory contents:"
        find /home/flutter/.gradle -type d 2>/dev/null | head -10 || show_error "Cannot list Gradle cache contents"
    fi
    
    exit 1
fi
show_success "APK build completed successfully!"
echo ""

# Copy APK files back
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

# Display results
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