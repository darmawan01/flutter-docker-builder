# Flutter Docker Builder

A modern, production-ready Docker image for building Flutter applications with Android SDK support. This image provides a complete Flutter development environment with the latest Android SDK, NDK, and build tools.

## 🚀 Features

- **Latest Flutter SDK** (configurable version)
- **Android SDK** with multiple API levels (30-35)
- **Android NDK** for native code compilation
- **Multiple build tools** versions for compatibility
- **Non-root user** for security
- **Health checks** for container monitoring
- **Configurable build options** (flavor, obfuscation, shrinking, etc.)
- **Beautiful colored output** with progress indicators

## 📋 Prerequisites

- Docker installed on your system
- Flutter project with valid `pubspec.yaml`
- Sufficient disk space (recommended: 10GB+)

## 🏗️ Building the Image

### Option 1: Build from Source

Clone this repository and build the image locally:

```bash
# Clone the repository
git clone <repository-url>
cd flutter-docker-builder

# Build the image
docker build -t flutter-docker-builder .
```

### Option 2: Use Pre-built Image from Registry

The latest image is automatically built and pushed to Docker Hub:

```bash
# Pull the latest image
docker pull ${{ github.repository }}:latest

# Or pull a specific version
docker pull ${{ github.repository }}:v1.0.0
```

#### Custom Build Arguments

You can customize the build with these arguments:

```bash
docker build \
  --build-arg FLUTTER_VERSION=3.32.4 \
  --build-arg ANDROID_API_LEVEL=35 \
  --build-arg JAVA_VERSION=17 \
  --build-arg NDK_VERSION=27.0.12077973 \
  -t flutter-docker-builder .
```

**Available Arguments:**
- `FLUTTER_VERSION`: Flutter SDK version (default: 3.32.4)
- `ANDROID_API_LEVEL`: Target Android API level (default: 35)
- `JAVA_VERSION`: Java version (default: 17)
- `NDK_VERSION`: Android NDK version (default: 27.0.12077973)



## 🎯 Usage

### Basic Usage

```bash
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  flutter-docker-builder:latest
```

### Advanced Usage with Environment Variables

```bash
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  -e BUILD_MODE=release \
  -e TARGET_PLATFORM=android-arm64 \
  -e FLAVOR=production \
  -e OBFUSCATE=true \
  -e SHRINK=true \
  -e SPLIT_PER_ABI=true \
  flutter-docker-builder:latest
```

### Interactive Mode

For debugging or development:

```bash
docker run --rm -it \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  flutter-docker-builder:latest /bin/bash
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_MODE` | `release` | Build mode (debug, profile, release) |
| `TARGET_PLATFORM` | `android-arm64` | Target platform (android-arm, android-arm64, android-x64) |
| `FLAVOR` | `` | Build flavor (optional) |
| `OBFUSCATE` | `false` | Enable code obfuscation |
| `SHRINK` | `false` | Enable code shrinking |
| `SPLIT_PER_ABI` | `false` | Split APK per ABI |

### Volume Mounts

| Mount Point | Purpose |
|-------------|---------|
| `/app` | Source Flutter project directory |
| `/output` | Output directory for generated APKs |

## 📁 Project Structure

Your Flutter project should be mounted to `/app` and contain:

```
/app/
├── pubspec.yaml
├── lib/
├── android/
├── ios/
└── ...
```

## 📦 Output

Generated APK files will be available in the mounted output directory:

```
/output/
├── apk/
│   ├── debug/
│   │   └── app-debug.apk
│   └── release/
│       └── app-release.apk
└── bundle/
    └── release/
        └── app-release.aab
```

## 🔧 Examples

### Build Release APK

```bash
# Set your project and output directories
export PROJECT_DIR="/path/to/your/flutter/project"
export OUTPUT_DIR="/path/to/output"

# Build release APK
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  -e BUILD_MODE=release \
  flutter-docker-builder:latest
```

### Build with Flavor

```bash
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  -e BUILD_MODE=release \
  -e FLAVOR=staging \
  flutter-docker-builder:latest
```

### Build Obfuscated APK

```bash
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  -e BUILD_MODE=release \
  -e OBFUSCATE=true \
  -e SHRINK=true \
  flutter-docker-builder:latest
```

### Build for Multiple ABIs

```bash
docker run --rm \
  -v "$PROJECT_DIR:/app" \
  -v "$OUTPUT_DIR:/output" \
  -e BUILD_MODE=release \
  -e SPLIT_PER_ABI=true \
  flutter-docker-builder:latest
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Ensure output directory has correct permissions
   mkdir -p "$OUTPUT_DIR" && chmod 755 "$OUTPUT_DIR"
   ```

2. **Out of Memory**
   ```bash
   # Increase Docker memory limit
   docker run --rm --memory=4g \
     -v "$PROJECT_DIR:/app" \
     -v "$OUTPUT_DIR:/output" \
     flutter-docker-builder:latest
   ```

3. **Build Fails**
   ```bash
   # Run in interactive mode to debug
   docker run --rm -it \
     -v "$PROJECT_DIR:/app" \
     -v "$OUTPUT_DIR:/output" \
     flutter-docker-builder:latest /bin/bash
   ```

### Health Check

The container includes a health check that verifies Flutter installation:

```bash
docker inspect --format='{{.State.Health.Status}}' <container_id>
```

## 🔒 Security

- Runs as non-root user (`flutter`)
- Uses official Ubuntu 24.04 base image
- Minimal attack surface with only necessary packages
- Regular security updates recommended

## 📊 Performance

- Multi-stage build optimization
- Layer caching for faster rebuilds
- Parallel dependency installation
- Optimized for CI/CD pipelines

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 🔄 CI/CD Pipeline

This project includes automated CI/CD pipelines for building, testing, and releasing Docker images:

### Workflows

1. **Build and Push** (`.github/workflows/docker-build.yml`)
   - Triggers on pushes to main/master and version tags
   - Builds multi-platform images (amd64, arm64)
   - Pushes to Docker Hub with proper tagging
   - Generates SBOM for security

2. **Security Scan** (`.github/workflows/security-scan.yml`)
   - Scans Docker images for vulnerabilities using Trivy
   - Runs on every push and weekly schedule
   - Uploads results to GitHub Security tab

3. **Test Build** (`.github/workflows/test-build.yml`)
   - Tests image builds with different Flutter versions
   - Verifies APK generation works correctly
   - Matrix testing with multiple configurations

4. **Release** (`.github/workflows/release.yml`)
   - Creates GitHub releases on version tags
   - Generates release notes automatically
   - Pushes latest and versioned tags

### Setup Requirements

To enable the CI/CD pipeline, add these secrets to your GitHub repository:

- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub access token

And these variables (optional, for customization):
- `FLUTTER_VERSION`: Flutter SDK version (default: 3.32.4)
- `ANDROID_API_LEVEL`: Android API level (default: 35)
- `JAVA_VERSION`: Java version (default: 17)
- `NDK_VERSION`: NDK version (default: 27.0.12077973)

### Automated Updates

Dependabot is configured to automatically:
- Update GitHub Actions to latest versions
- Update Docker base images
- Create pull requests for security updates

## 📄 License

[Add your license information here]

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the Docker logs: `docker logs <container_id>`
- Check GitHub Actions for build status