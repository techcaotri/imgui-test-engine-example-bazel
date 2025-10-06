# Modern Bazel Configuration with bzlmod

This guide covers the updated Bazel configuration using the modern Bazel module system (bzlmod) with automatic fetching of ImGui and ImGui Test Engine from GitHub.

## 📋 Requirements

- **Bazel 6.0+** (Bazel 7.0+ recommended for full bzlmod support)
- **C++17 compatible compiler**
- **Git** (for fetching repositories)
- **lcov** (for coverage reports)

### Check Bazel Version
```bash
bazel version
# Should show 6.0.0 or higher
```

### Install/Update Bazel
```bash
# Ubuntu/Debian
sudo apt install apt-transport-https curl gnupg
curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg
sudo mv bazel-archive-keyring.gpg /usr/share/keyrings
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
sudo apt update && sudo apt install bazel

# macOS
brew install bazel

# Or use Bazelisk (recommended - auto-manages Bazel versions)
npm install -g @bazel/bazelisk
# or
brew install bazelisk
```

## 🚀 Quick Start

### 1. Project Setup

```bash
# Clone the project
git clone <your-repo>
cd imgui_test_project

# Create the required files
touch MODULE.bazel
touch extensions.bzl
touch BUILD.bazel
touch .bazelrc
touch .bazelversion

# Copy the provided configurations into these files
```

### 2. Initial Setup

```bash
# Run the setup script
chmod +x scripts/setup_bazel.sh
./scripts/setup_bazel.sh

# Or manually:
echo "7.0.0" > .bazelversion  # Pin Bazel version
bazel fetch //...              # Fetch all dependencies
```

### 3. Build and Run

```bash
# Build the application
bazel build //:imgui_test_app

# Run the application
./bazel-bin/imgui_test_app

# Run tests headless
./bazel-bin/imgui_test_app --test --headless

# Run with test UI
./bazel-bin/imgui_test_app --test
```

## 📁 Project Structure

```
imgui_test_project/
├── MODULE.bazel           # Bazel module configuration (bzlmod)
├── MODULE.bazel.lock      # Auto-generated, add to .gitignore
├── extensions.bzl       # External repository definitions
├── BUILD.bazel           # Main build targets
├── .bazelrc              # Bazel configuration
├── .bazelversion         # Pin Bazel version
├── .bazelignore          # Files to ignore
├── main.cpp              # Application source
└── scripts/
    ├── setup_bazel.sh         # Initial setup script
    ├── build_modern_bazel.sh  # Build helper script
    └── generate_coverage.sh   # Coverage generation
```

## 🔧 Key Configuration Files

### MODULE.bazel
The modern replacement for WORKSPACE. Defines the module and its dependencies:
```python
module(
    name = "imgui_test_project",
    version = "1.0.0",
)

bazel_dep(name = "platforms", version = "0.0.8")
bazel_dep(name = "bazel_skylib", version = "1.5.0")
bazel_dep(name = "rules_cc", version = "0.0.9")
```

### extensions.bzl
Defines how to fetch ImGui and ImGui Test Engine from GitHub:
```python
def imgui_test_repositories():
    new_git_repository(
        name = "imgui",
        remote = "https://github.com/ocornut/imgui.git",
        tag = "v1.90.0",  # Specific version
        build_file_content = "..."  # Build rules
    )
    
    new_git_repository(
        name = "imgui_test_engine",
        remote = "https://github.com/ocornut/imgui_test_engine.git",
        commit = "main",  # Or specific commit
        build_file_content = "..."
    )
```

## 🏗️ Build Configurations

### Debug Build (default)
```bash
bazel build //:imgui_test_app
# or
bazel build --config=debug //:imgui_test_app
```

### Release Build
```bash
bazel build --config=release //:imgui_test_app
```

### Coverage Build
```bash
bazel build --config=coverage //:imgui_test_app_coverage
```

## 🧪 Testing

### Run All Tests
```bash
# Run the complete test suite
bazel test //:all_tests

# With detailed output
bazel test //:all_tests --test_output=all
```

### Run Specific Test Categories
```bash
# Widget tests only
bazel test //:test_widgets

# Integration tests
bazel test //:test_integration

# Performance tests
bazel test //:test_performance
```

### Run Tests with Coverage
```bash
# Run tests with coverage collection
bazel coverage --config=coverage //:all_tests

# Generate HTML report
bazel run //:coverage

# View report
xdg-open coverage_report/html/index.html  # Linux
open coverage_report/html/index.html       # macOS
```

## 📊 Coverage Reports

### Generate Coverage Report
```bash
# Using the helper script
./scripts/build_modern_bazel.sh --coverage --test

# Or manually
bazel build --config=coverage //:imgui_test_app_coverage
./bazel-bin/imgui_test_app_coverage --test --headless
bazel run //:coverage
```

### Coverage Output
- **HTML Report**: `coverage_report/html/index.html`
- **LCOV Data**: `coverage_report/coverage_filtered.info`
- **Summary**: Printed to console

## 🔄 Dependency Management

### Fetching Dependencies
Dependencies are automatically fetched from GitHub when building:
```bash
# Fetch all dependencies without building
bazel fetch //...

# Force re-fetch (after clean)
bazel clean --expunge
bazel fetch //...
```

### Updating Dependencies

To update ImGui or Test Engine versions:

1. Edit `extensions.bzl`
2. Change the `tag` or `commit`:
```python
new_git_repository(
    name = "imgui",
    remote = "https://github.com/ocornut/imgui.git",
    tag = "v1.91.0",  # Update version here
    ...
)
```
3. Clean and rebuild:
```bash
bazel clean --expunge
bazel build //:imgui_test_app
```

### Pinning Specific Commits
For reproducible builds, pin to specific commits:
```python
new_git_repository(
    name = "imgui_test_engine",
    remote = "https://github.com/ocornut/imgui_test_engine.git",
    commit = "abc123def456",  # Specific commit SHA
    ...
)
```

## 🛠️ Helper Scripts

### Setup Script
```bash
./scripts/setup_bazel.sh
# - Checks Bazel version
# - Creates configuration files
# - Fetches dependencies
# - Verifies build
```

### Build Script
```bash
./scripts/build_modern_bazel.sh [OPTIONS]
# Options:
#   --release    Build in release mode
#   --test       Run tests after building
#   --coverage   Generate coverage report
#   --clean      Clean before building
#   --fetch      Only fetch dependencies
```

### Examples
```bash
# Clean build with tests and coverage
./scripts/build_modern_bazel.sh --clean --coverage --test

# Release build
./scripts/build_modern_bazel.sh --release

# Just fetch dependencies
./scripts/build_modern_bazel.sh --fetch
```

## 🐛 Troubleshooting

### Module Lock File Issues
```bash
# If MODULE.bazel.lock causes issues
rm MODULE.bazel.lock
bazel clean --expunge
bazel fetch //...
```

### Old WORKSPACE Warning
If you see warnings about WORKSPACE:
```bash
# Ensure bzlmod is enabled in .bazelrc
echo "common --enable_bzlmod" >> .bazelrc
```

### Fetch Failures
```bash
# Clear cache and retry
bazel clean --expunge
bazel shutdown
bazel fetch //...
```

### Platform-Specific Issues

#### Linux - Missing X11 Headers
```bash
sudo apt-get install libx11-dev libxrandr-dev libxinerama-dev \
                     libxcursor-dev libxi-dev
```

#### macOS - Framework Issues
```bash
# Ensure Xcode command line tools are installed
xcode-select --install
```

#### Windows - OpenGL Issues
```bash
# Ensure OpenGL libraries are available
# May need to install graphics drivers
```

## 📈 CI/CD Integration

### GitHub Actions
```yaml
name: Bazel Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Mount Bazel cache
      uses: actions/cache@v3
      with:
        path: ~/.cache/bazel
        key: bazel-${{ runner.os }}-${{ hashFiles('MODULE.bazel') }}
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y lcov libx11-dev libgl1-mesa-dev
    
    - name: Build and test
      run: |
        bazel test --config=coverage //:all_tests
    
    - name: Generate coverage
      run: |
        bazel run //:coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage_report/coverage_filtered.info
```

## 🔍 Advanced Features

### Custom Build Flags
Add to `.bazelrc`:
```bash
# Custom configuration
build:custom --copt=-DCUSTOM_FLAG
build:custom --linkopt=-lcustom_lib
```

### Query Dependencies
```bash
# Show all external dependencies
bazel query "deps(//:imgui_test_app)" | grep "@"

# Show dependency graph
bazel query "deps(//:imgui_test_app)" --output graph | dot -Tpng > deps.png
```

### Build Info
```bash
# Show build info
bazel info

# Show action graph
bazel aquery //:imgui_test_app
```

## 📚 Additional Resources

- [Bazel Modules Documentation](https://bazel.build/docs/bzlmod)
- [Migrating from WORKSPACE to bzlmod](https://bazel.build/migrate/bzlmod)
- [Bazel C++ Tutorial](https://bazel.build/tutorials/cpp)
- [ImGui Repository](https://github.com/ocornut/imgui)
- [ImGui Test Engine](https://github.com/ocornut/imgui_test_engine)

## ⚡ Performance Tips

1. **Use Bazelisk** for automatic Bazel version management
2. **Enable Remote Caching** for faster builds in CI
3. **Use `--jobs` flag** to control parallelism
4. **Profile builds** with `--profile` flag
5. **Cache fetched repositories** with `--repository_cache`

## 🔄 Migration from WORKSPACE

If migrating from old WORKSPACE setup:

1. Create `MODULE.bazel` with module declaration
2. Move repository rules to `extensions.bzl`
3. Add `--enable_bzlmod` to `.bazelrc`
4. Update BUILD files to use new target names
5. Clean and rebuild

## 📝 Summary

The modern Bazel module system provides:
- ✅ **Automatic dependency fetching** from GitHub
- ✅ **Better dependency version management**
- ✅ **Cleaner configuration** with MODULE.bazel
- ✅ **Improved reproducibility** with lock files
- ✅ **Native support** in Bazel 6+

This configuration automatically fetches ImGui and ImGui Test Engine from their GitHub repositories, eliminating manual downloads while maintaining full control over versions and build configurations.
