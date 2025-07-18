# Flutter Builder Docker Image
# Usage: docker build --build-arg FLUTTER_VERSION=3.24.5 -t flutter-builder .

FROM ubuntu:24.04

LABEL maintainer="flutter-builder" \
      description="Modern Flutter development environment with latest Android SDK"

# Build arguments for flexible versioning
ARG FLUTTER_VERSION="3.32.4"
ARG ANDROID_API_LEVEL="35"
ARG JAVA_VERSION="17"
ARG NDK_VERSION="27.0.12077973"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ANDROID_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/opt/flutter" \
    JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"

ENV ANDROID_SDK_ROOT="$ANDROID_HOME" \
    PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/ndk/$NDK_VERSION:$FLUTTER_HOME/bin"

# Install system dependencies in single layer
RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
        # Build essentials
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        unzip \
        xz-utils \
        # Java
        openjdk-${JAVA_VERSION}-jdk \
        # Flutter/Android dependencies
        libstdc++6 \
        libglu1-mesa \
        # NDK dependencies
        cmake \
        ninja-build \
        pkg-config \
        # Locale support
        locales \
        # User management
        gosu \
        # Cleanup in same layer
        && locale-gen en_US.UTF-8 \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user first
RUN useradd -m -s /bin/bash flutter && \
    mkdir -p $ANDROID_HOME $FLUTTER_HOME && \
    chown -R flutter:flutter $ANDROID_HOME $FLUTTER_HOME && \
    # Ensure flutter user can access common directories
    mkdir -p /home/flutter/.pub-cache && \
    chown -R flutter:flutter /home/flutter && \
    mkdir -p /output && \
    chown -R flutter:flutter /output && \
    chmod 755 /output

# Install Android SDK Command Line Tools as flutter user
USER flutter
RUN ANDROID_SDK_URL=$(curl -s "https://developer.android.com/studio/index.html" | \
    grep -oP 'commandlinetools-linux-\d+_latest\.zip' | head -1) && \
    curl -fsSL "https://dl.google.com/android/repository/${ANDROID_SDK_URL}" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Install Android SDK packages as flutter user
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --update && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-${ANDROID_API_LEVEL}" \
        "platforms;android-34" \
        "platforms;android-33" \
        "platforms;android-32" \
        "platforms;android-31" \
        "platforms;android-30" \
        "build-tools;${ANDROID_API_LEVEL}.0.0" \
        "build-tools;34.0.0" \
        "build-tools;33.0.2" \
        "build-tools;32.0.0" \
        "build-tools;31.0.0" \
        "build-tools;30.0.3" \
        "cmdline-tools;latest" \
        "ndk;${NDK_VERSION}" \
        "cmake;3.22.1"

# Install Flutter as flutter user
RUN if [ -z "$FLUTTER_VERSION" ]; then \
        FLUTTER_VERSION=$(curl -fsSL https://api.github.com/repos/flutter/flutter/releases/latest | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); \
    fi && \
    echo "Installing Flutter version: $FLUTTER_VERSION" && \
    curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz && \
    tar xf /tmp/flutter.tar.xz -C /opt/ && \
    rm /tmp/flutter.tar.xz

WORKDIR /home/flutter

# Configure Flutter
RUN flutter precache && \
    flutter config --android-sdk $ANDROID_HOME && \
    yes | flutter doctor --android-licenses && \
    flutter doctor

# Create project directory
RUN mkdir -p /home/flutter/projects && \
    mkdir -p /home/flutter/.android && \
    touch /home/flutter/.android/repositories.cfg

WORKDIR /home/flutter/projects

# Copy and set up entrypoint
COPY entrypoint.sh /usr/local/bin/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD flutter doctor --machine > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]