# Flutter Docker Builder

A unified Docker-based Flutter development environment for building APKs with proper isolation and reproducible builds.

## 🚀 Quick Start

### Build Docker Images

```bash
# Build Ubuntu image (default)
./build.sh build-image

# Build Bookworm image (smaller)
./build.sh build-image -b bookworm

# Custom configuration
./build.sh build-image -a 35 -m 27 -f 3.32.4 -b bookworm
```

### Build APKs

```bash
# Build APK with default settings
./build.sh build-apk -p ./my_flutter_app

# Build with custom options
./build.sh build-apk -p ./my_app -o ./output --obfuscate --shrink

# Build using Bookworm image
./build.sh build-apk -p ./my_app -b bookworm
```

### Compare Image Sizes

```bash
# Compare Ubuntu vs Bookworm sizes
./build.sh compare
```

### Clean Up

```bash
# Remove all images
./build.sh clean
```

## Comprehensive SDK Platform Installation
Added pre-installation of commonly used Android SDK platforms:
- `android-28` (API 28)
- `android-29` (API 29) 
- `android-30` (API 30)
- `android-31` (API 31)
- `android-32` (API 32)
- `android-33` (API 33)
- `android-34` (API 34)

## Comprehensive Build Tools Installation
Added pre-installation of corresponding build tools:
- `build-tools;28.0.3`
- `build-tools;29.0.3`
- `build-tools;30.0.3`
- `build-tools;31.0.0`
- `build-tools;32.0.0`
- `build-tools;33.0.0`
- `build-tools;34.0.0`

## 📦 Available Images

### Ubuntu 24.04 (`Dockerfile`)
- **Base**: Ubuntu 24.04
- **Size**: ~2-3GB
- **Use for**: Development, debugging, team familiarity
- **Features**: Full compatibility, familiar environment

### Debian Bookworm (`Dockerfile.bookworm`)
- **Base**: Debian Bookworm Slim
- **Size**: ~1.5-2GB (30-40% smaller)
- **Use for**: Production, CI/CD, resource-constrained environments
- **Features**: Smaller size, faster deployments

### Alpine (`Dockerfile.alpine`)
- **Base**: Alpine 3.21
- **Size**: ~1.2-1.5GB (50-60% smaller than Ubuntu)
- **Use for**: Production, CI/CD, minimal deployments
- **Features**: Smallest size, fastest deployments, glibc compatibility layer

## ⚙️ Configuration

### Default Settings
- **Flutter Version**: 3.32.4
- **Android API Level**: 35 (Android 15)
- **Minimum API Level**: 27 (Android 8.1+)
- **Java Version**: 17
- **NDK Version**: 27.0.12077973

### Build Arguments

```bash
./build.sh build-image \
  -f 3.32.4 \
  -a 35 \
  -m 27 \
  -j 17 \
  -n 27.0.12077973 \
  -i darmawanz01/flutter-docker-builder \
  -b bookworm
```

### APK Build Options

```bash
./build.sh build-apk \
  -p ./my_app \
  -o ./output \
  --build-mode release \
  --target-platform android-arm64 \
  --flavor production \
  --obfuscate \
  --shrink \
  --split-per-abi
```

## 🎯 Usage Examples

### Basic Workflow

```bash
# 1. Build Ubuntu image
./build.sh build-image

# 2. Build APK
./build.sh build-apk -p ./my_app

# 3. Compare sizes
./build.sh compare

# 4. Clean up when done
./build.sh clean
```

### Production Workflow

```bash
# 1. Build Bookworm image (smaller)
./build.sh build-image -b bookworm -i my-flutter:prod

# 2. Build optimized APK
./build.sh build-apk -p ./my_app -b bookworm --obfuscate --shrink

# 3. Clean up
./build.sh clean
```

### CI/CD Example

```bash
# Build and use in one command
./build.sh build-apk -p ./my_app -b bookworm -o ./artifacts
```

## 📊 Size Comparison

| Image Type | Base | Size | Use Case |
|------------|------|------|----------|
| Ubuntu | Ubuntu 24.04 | ~2-3GB | Development, debugging |
| Bookworm | Debian Bookworm | ~1.5-2GB | Production, CI/CD |

## 🔧 Script Commands

### `build-image`
Builds a Docker image with Flutter and Android SDK.

**Options:**
- `-f, --flutter-version`: Flutter version
- `-a, --android-api-level`: Target Android API level
- `-m, --min-api-level`: Minimum Android API level
- `-j, --java-version`: Java version
- `-n, --ndk-version`: NDK version
- `-i, --image-name`: Docker image name
- `-b, --base`: Base image (ubuntu/bookworm)

### `build-apk`
Builds APK from Flutter project.

**Options:**
- `-p, --project-dir`: Project directory
- `-o, --output-dir`: Output directory
- `--build-mode`: Build mode (debug/profile/release)
- `--target-platform`: Target platform
- `--flavor`: Build flavor
- `--obfuscate`: Enable obfuscation
- `--shrink`: Enable shrinking
- `--split-per-abi`: Split APK per ABI

### `compare`
Compares sizes of Ubuntu and Bookworm images.

### `clean`
Removes all Docker images.

## 🏗️ Project Structure

```
flutter-docker-builder/
├── build.sh              # Unified build script
├── Dockerfile            # Ubuntu-based image
├── Dockerfile.bookworm   # Debian Bookworm-based image
├── entrypoint.sh         # Container entrypoint
├── test_app/            # Test Flutter application
└── README.md            # This file
```

## 📋 Requirements

- Docker
- Bash shell
- Internet connection for downloading Flutter and Android SDK

## 🎯 Benefits

- **Unified Script**: One script handles everything
- **Two Base Images**: Choose Ubuntu or Bookworm
- **Optimized Size**: Bookworm is 30-40% smaller
- **Flexible Configuration**: Easy to customize
- **Production Ready**: Suitable for CI/CD
- **Clean Interface**: Simple command structure

## 🚀 Advanced Usage

### Environment Variables

```bash
export FLUTTER_VERSION=3.32.4
export ANDROID_API_LEVEL=35
export ANDROID_MIN_API_LEVEL=27
export BASE_TYPE=bookworm
./build.sh build-image
```

### Custom Image Names

```bash
./build.sh build-image -i my-company/darmawanz01-flutter-builder -b bookworm
```

### Multiple Builds

```bash
# Build both images
./build.sh build-image -b ubuntu
./build.sh build-image -b bookworm

# Compare them
./build.sh compare
```

## 📄 License

MIT License - see LICENSE file for details.