#!/bin/bash

# Flutter Docker APK Builder Script
# This script builds Flutter APKs using Docker with proper isolation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
BUILD_MODE="${BUILD_MODE:-release}"
TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
FLAVOR="${FLAVOR:-}"
OBFUSCATE="${OBFUSCATE:-false}"
SHRINK="${SHRINK:-false}"
SPLIT_PER_ABI="${SPLIT_PER_ABI:-false}"
IMAGE_NAME="${IMAGE_NAME:-flutter-docker-builder}"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project-dir DIR    Project directory (default: current directory)"
    echo "  -o, --output-dir DIR     Output directory (default: ./output)"
    echo "  -m, --build-mode MODE    Build mode: debug, profile, release (default: release)"
    echo "  -t, --target-platform PLATFORM  Target platform (default: android-arm64)"
    echo "  -f, --flavor FLAVOR      Build flavor"
    echo "  --obfuscate              Enable obfuscation"
    echo "  --shrink                 Enable shrinking"
    echo "  --split-per-abi          Split APK per ABI"
    echo "  -i, --image IMAGE        Docker image name (default: flutter-docker-builder)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_DIR              Project directory"
    echo "  OUTPUT_DIR               Output directory"
    echo "  BUILD_MODE               Build mode"
    echo "  TARGET_PLATFORM          Target platform"
    echo "  FLAVOR                   Build flavor"
    echo "  OBFUSCATE                Enable obfuscation (true/false)"
    echo "  SHRINK                   Enable shrinking (true/false)"
    echo "  SPLIT_PER_ABI           Split APK per ABI (true/false)"
    echo "  IMAGE_NAME               Docker image name"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -m|--build-mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        -t|--target-platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        -f|--flavor)
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
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory '$PROJECT_DIR' does not exist${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}Error: '$PROJECT_DIR' does not appear to be a Flutter project (missing pubspec.yaml)${NC}"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert to absolute paths
PROJECT_DIR=$(realpath "$PROJECT_DIR")
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

echo -e "${BLUE}🚀 Flutter Docker APK Builder${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project Directory: $PROJECT_DIR"
echo "  Output Directory:  $OUTPUT_DIR"
echo "  Build Mode:        $BUILD_MODE"
echo "  Target Platform:   $TARGET_PLATFORM"
echo "  Flavor:            ${FLAVOR:-default}"
echo "  Obfuscate:         $OBFUSCATE"
echo "  Shrink:            $SHRINK"
echo "  Split per ABI:     $SPLIT_PER_ABI"
echo "  Docker Image:      $IMAGE_NAME"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check if image exists, build if not
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}Building Docker image '$IMAGE_NAME'...${NC}"
    docker build -t "$IMAGE_NAME" .
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
    echo ""
fi

# Build the APK
echo -e "${YELLOW}Building APK...${NC}"
docker run --rm \
    -v "$PROJECT_DIR:/app" \
    -v "$OUTPUT_DIR:/output" \
    -e BUILD_MODE="$BUILD_MODE" \
    -e TARGET_PLATFORM="$TARGET_PLATFORM" \
    -e FLAVOR="$FLAVOR" \
    -e OBFUSCATE="$OBFUSCATE" \
    -e SHRINK="$SHRINK" \
    -e SPLIT_PER_ABI="$SPLIT_PER_ABI" \
    "$IMAGE_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ APK build completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Generated APK files:${NC}"
    find "$OUTPUT_DIR" -name "*.apk" -type f | while read -r apk; do
        size=$(du -h "$apk" | cut -f1)
        echo "  $size - $apk"
    done
else
    echo -e "${RED}❌ APK build failed${NC}"
    exit 1
fi 