#!/bin/bash

# Unified Flutter Docker Builder Script
# This script can build Docker images, build APKs, and compare sizes

set -e

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
COMPARE="⚖️"

# Default values
FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.4}"
ANDROID_API_LEVEL="${ANDROID_API_LEVEL:-35}"
ANDROID_MIN_API_LEVEL="${ANDROID_MIN_API_LEVEL:-27}"
JAVA_VERSION="${JAVA_VERSION:-17}"
NDK_VERSION="${NDK_VERSION:-27.0.12077973}"
IMAGE_NAME="${IMAGE_NAME:-darmawanz01/flutter-docker-builder}"
BASE_TYPE="${BASE_TYPE:-ubuntu}"
BUILD_MODE="${BUILD_MODE:-release}"
TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
FLAVOR="${FLAVOR:-}"
OBFUSCATE="${OBFUSCATE:-false}"
SHRINK="${SHRINK:-false}"
SPLIT_PER_ABI="${SPLIT_PER_ABI:-false}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build-image     Build Docker image"
    echo "  build-apk       Build APK from Flutter project"
    echo "  compare         Compare image sizes"
    echo "  clean           Clean up Docker images"
    echo ""
    echo "Options:"
    echo "  -f, --flutter-version VERSION    Flutter version (default: 3.32.4)"
    echo "  -a, --android-api-level LEVEL    Android API level (default: 35)"
    echo "  -m, --min-api-level LEVEL        Minimum Android API level (default: 27)"
    echo "  -j, --java-version VERSION       Java version (default: 17)"
    echo "  -n, --ndk-version VERSION        NDK version (default: 27.0.12077973)"
    echo "  -i, --image-name NAME            Docker image name (default: darmawanz01/flutter-docker-builder)"
    echo "  -b, --base TYPE                  Base image: ubuntu, bookworm, or alpine (default: ubuntu)"
    echo "  -p, --project-dir DIR            Project directory for APK build"
    echo "  -o, --output-dir DIR             Output directory for APK build"
    echo "  --build-mode MODE                Build mode: debug, profile, release (default: release)"
    echo "  --target-platform PLATFORM       Target platform (default: android-arm64)"
    echo "  --flavor FLAVOR                  Build flavor"
    echo "  --obfuscate                      Enable obfuscation"
    echo "  --shrink                         Enable shrinking"
    echo "  --split-per-abi                  Split APK per ABI"
    echo "  -h, --help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Build Ubuntu image"
    echo "  $0 build-image -b ubuntu -a 35 -m 27"
    echo ""
    echo "  # Build Bookworm image"
    echo "  ./build.sh build-image -b bookworm -i my-flutter:bookworm"
    echo ""
    echo "  # Build APK"
    echo "  ./build.sh build-apk -p ./my_app -o ./output"
    echo ""
    echo "  # Compare image sizes"
    echo "  ./build.sh compare"
    echo ""
    echo "  # Clean up images"
    echo "  ./build.sh clean"
}

# Function to show progress
show_progress() {
    local message="$1"
    echo -e "${CYAN}${ARROW} ${message}${NC}"
}

# Function to show success
show_success() {
    local message="$1"
    echo -e "${GREEN}${CHECK_MARK} ${message}${NC}"
}

# Function to show error
show_error() {
    local message="$1"
    echo -e "${RED}${CROSS_MARK} ${message}${NC}"
}

# Function to show info
show_info() {
    local message="$1"
    echo -e "${BLUE}${INFO} ${message}${NC}"
}

# Function to show warning
show_warning() {
    local message="$1"
    echo -e "${YELLOW}${WARNING} ${message}${NC}"
}

# Function to build Docker image
build_image() {
    show_progress "Building Docker image..."
    
    # Determine Dockerfile based on base type
    if [ "$BASE_TYPE" = "bookworm" ]; then
        DOCKERFILE="Dockerfile.bookworm"
        TAG_SUFFIX=":bookworm"
    elif [ "$BASE_TYPE" = "alpine" ]; then
        DOCKERFILE="Dockerfile.alpine"
        TAG_SUFFIX=":alpine"
    else
        DOCKERFILE="Dockerfile"
        TAG_SUFFIX=":ubuntu"
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$DOCKERFILE" ]; then
        show_error "Dockerfile '$DOCKERFILE' does not exist"
        exit 1
    fi
    
    # Build the image
    docker build \
        --build-arg FLUTTER_VERSION="$FLUTTER_VERSION" \
        --build-arg ANDROID_API_LEVEL="$ANDROID_API_LEVEL" \
        --build-arg ANDROID_MIN_API_LEVEL="$ANDROID_MIN_API_LEVEL" \
        --build-arg JAVA_VERSION="$JAVA_VERSION" \
        --build-arg NDK_VERSION="$NDK_VERSION" \
        -t "$IMAGE_NAME$TAG_SUFFIX" \
        -f "$DOCKERFILE" .
    
    if [ $? -eq 0 ]; then
        show_success "Docker image built successfully!"
        
        # Show image size
        IMAGE_SIZE=$(docker images "$IMAGE_NAME$TAG_SUFFIX" --format "table {{.Size}}" | tail -n +2)
        show_info "Image size: $IMAGE_SIZE"
        
        # Show what's included
        echo ""
        show_info "Included components:"
        echo "  • Flutter $FLUTTER_VERSION"
        echo "  • Android SDK API Level $ANDROID_API_LEVEL"
        echo "  • Android SDK API Level $ANDROID_MIN_API_LEVEL (minimum)"
        echo "  • Build Tools $ANDROID_API_LEVEL.0.0"
        echo "  • NDK $NDK_VERSION"
        echo "  • Java $JAVA_VERSION"
        echo "  • Base: $BASE_TYPE"
    else
        show_error "Docker image build failed"
        exit 1
    fi
}

# Function to build APK
build_apk() {
    show_progress "Building APK..."
    
    # Validate inputs
    if [ ! -d "$PROJECT_DIR" ]; then
        show_error "Project directory '$PROJECT_DIR' does not exist"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
        show_error "'$PROJECT_DIR' does not appear to be a Flutter project (missing pubspec.yaml)"
        exit 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Convert to absolute paths
    PROJECT_DIR=$(realpath "$PROJECT_DIR")
    OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
    
    # Determine image name based on base type
    if [ "$BASE_TYPE" = "bookworm" ]; then
        IMAGE_TO_USE="$IMAGE_NAME:bookworm"
    elif [ "$BASE_TYPE" = "alpine" ]; then
        IMAGE_TO_USE="$IMAGE_NAME:alpine"
    else
        IMAGE_TO_USE="$IMAGE_NAME:ubuntu"
    fi
    
    # Check if image exists
    if ! docker image inspect "$IMAGE_TO_USE" >/dev/null 2>&1; then
        show_warning "Image '$IMAGE_TO_USE' does not exist. Building it first..."
        build_image
    fi
    
    # Build the APK
    docker run --rm \
        -v "$PROJECT_DIR:/app" \
        -v "$OUTPUT_DIR:/output" \
        -e BUILD_MODE="$BUILD_MODE" \
        -e TARGET_PLATFORM="$TARGET_PLATFORM" \
        -e FLAVOR="$FLAVOR" \
        -e OBFUSCATE="$OBFUSCATE" \
        -e SHRINK="$SHRINK" \
        -e SPLIT_PER_ABI="$SPLIT_PER_ABI" \
        "$IMAGE_TO_USE"
    
    if [ $? -eq 0 ]; then
        show_success "APK build completed successfully!"
        echo ""
        show_info "Generated APK files:"
        find "$OUTPUT_DIR" -name "*.apk" -type f | while read -r apk; do
            size=$(du -h "$apk" | cut -f1)
            echo "  $size - $apk"
        done
    else
        show_error "APK build failed"
        exit 1
    fi
}

# Function to compare image sizes
compare_images() {
    show_progress "Comparing image sizes..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        show_error "Docker is not running"
        exit 1
    fi
    
    # Get image sizes
    UBUNTU_SIZE=$(docker images "$IMAGE_NAME:ubuntu" --format "{{.Size}}" 2>/dev/null || echo "Not built")
    BOOKWORM_SIZE=$(docker images "$IMAGE_NAME:bookworm" --format "{{.Size}}" 2>/dev/null || echo "Not built")
    ALPINE_SIZE=$(docker images "$IMAGE_NAME:alpine" --format "{{.Size}}" 2>/dev/null || echo "Not built")
    
    echo ""
    echo -e "${BLUE}${CHART} Image Size Comparison:${NC}"
    echo ""
    echo "┌─────────────────┬─────────────────┬─────────────────┐"
    echo "│ Image Type      │ Size            │ Base            │"
    echo "├─────────────────┼─────────────────┼─────────────────┤"
    echo "│ Ubuntu          │ $(printf "%-15s" "$UBUNTU_SIZE") │ Ubuntu 24.04    │"
    echo "│ Bookworm        │ $(printf "%-15s" "$BOOKWORM_SIZE") │ Debian Bookworm │"
    echo "│ Alpine          │ $(printf "%-15s" "$ALPINE_SIZE") │ Alpine 3.21     │"
    echo "└─────────────────┴─────────────────┴─────────────────┘"
    
    echo ""
    show_info "Recommendations:"
    echo "• Use Ubuntu for development and debugging (full Flutter and Android SDK support)"
    echo "• Use Bookworm for production (smaller, faster, full Flutter and Android SDK support)"
    echo "• Use Alpine for production (smaller, faster, full Flutter and Android SDK support)"
    echo "• Both provide full Flutter and Android SDK support"
}

# Function to clean up images
clean_images() {
    show_progress "Cleaning up Docker images..."
    
    # Remove images if they exist
    if docker image inspect "$IMAGE_NAME:ubuntu" >/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME:ubuntu"
        show_success "Removed $IMAGE_NAME:ubuntu"
    fi
    
    if docker image inspect "$IMAGE_NAME:bookworm" >/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME:bookworm"
        show_success "Removed $IMAGE_NAME:bookworm"
    fi
    
    if docker image inspect "$IMAGE_NAME:alpine" >/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME:alpine"
        show_success "Removed $IMAGE_NAME:alpine"
    fi
    
    show_success "Cleanup completed!"
}

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        build-image|build-apk|compare|clean)
            COMMAND="$1"
            shift
            ;;
        -f|--flutter-version)
            FLUTTER_VERSION="$2"
            shift 2
            ;;
        -a|--android-api-level)
            ANDROID_API_LEVEL="$2"
            shift 2
            ;;
        -m|--min-api-level)
            ANDROID_MIN_API_LEVEL="$2"
            shift 2
            ;;
        -j|--java-version)
            JAVA_VERSION="$2"
            shift 2
            ;;
        -n|--ndk-version)
            NDK_VERSION="$2"
            shift 2
            ;;
        -i|--image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -b|--base)
            BASE_TYPE="$2"
            shift 2
            ;;
        -p|--project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --build-mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        --target-platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        --flavor)
            FLAVOR="$2"
            shift 2
            ;;
        --obfuscate)
            OBFUSCATE="true"
            shift
            ;;
        --shrink)
            SHRINK="true"
            shift
            ;;
        --split-per-abi)
            SPLIT_PER_ABI="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            show_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate command
if [ -z "$COMMAND" ]; then
    show_error "No command specified"
    show_usage
    exit 1
fi

# Validate base type
if [ "$BASE_TYPE" != "ubuntu" ] && [ "$BASE_TYPE" != "bookworm" ] && [ "$BASE_TYPE" != "alpine" ]; then
    show_error "Invalid base type: $BASE_TYPE. Use 'ubuntu', 'bookworm', or 'alpine'"
    exit 1
fi

# Execute command
case "$COMMAND" in
    build-image)
        build_image
        ;;
    build-apk)
        build_apk
        ;;
    compare)
        compare_images
        ;;
    clean)
        clean_images
        ;;
    *)
        show_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac 