#!/bin/bash
set -e
set -x  # Enable command tracing

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Setting up Bazel 8.3.1 Configuration${NC}"
echo -e "${BLUE}======================================${NC}"

# Check Bazel version
echo -e "${CYAN}[DEBUG] Checking Bazel version...${NC}"
BAZEL_VERSION=$(bazel version | grep "Build label:" | cut -d' ' -f3)
echo -e "${GREEN}Bazel version: $BAZEL_VERSION${NC}"
echo -e "${CYAN}[DEBUG] Full Bazel version output:${NC}"
bazel version

# Check if version is 8.x
MAJOR_VERSION=$(echo $BAZEL_VERSION | cut -d'.' -f1)
echo -e "${CYAN}[DEBUG] Major version: $MAJOR_VERSION${NC}"
if [ "$MAJOR_VERSION" -lt "8" ]; then
	echo -e "${RED}Error: Bazel 8.x required. Found version $BAZEL_VERSION${NC}"
	echo -e "${YELLOW}Please upgrade Bazel to version 8.3.1 or higher${NC}"
	exit 1
fi

# Check current directory
echo -e "${CYAN}[DEBUG] Current directory: $(pwd)${NC}"
echo -e "${CYAN}[DEBUG] Directory contents:${NC}"
ls -la

# Create necessary files
echo -e "${GREEN}Creating configuration files...${NC}"

# Check if files exist
if [ ! -f "MODULE.bazel" ]; then
	echo -e "${RED}MODULE.bazel not found!${NC}"
	exit 1
fi
echo -e "${CYAN}[DEBUG] MODULE.bazel found${NC}"
echo -e "${CYAN}[DEBUG] MODULE.bazel contents:${NC}"
cat MODULE.bazel

if [ ! -f "extensions.bzl" ]; then
	echo -e "${RED}extensions.bzl not found!${NC}"
	exit 1
fi
echo -e "${CYAN}[DEBUG] extensions.bzl found (first 50 lines):${NC}"
head -50 extensions.bzl

if [ ! -f "BUILD.bazel" ]; then
	echo -e "${RED}BUILD.bazel not found!${NC}"
	exit 1
fi
echo -e "${CYAN}[DEBUG] BUILD.bazel found${NC}"

# Create .bazelversion file
echo "8.3.1" >.bazelversion
echo -e "${GREEN}Created .bazelversion (pinned to 8.3.1)${NC}"

# Add to .gitignore
if ! grep -q "MODULE.bazel.lock" .gitignore 2>/dev/null; then
	cat >>.gitignore <<'EOF'

# Bazel files
MODULE.bazel.lock
bazel-*
.bazelrc.user

# Coverage files
coverage_report/
*.gcov
*.gcda
*.gcno
EOF
	echo -e "${GREEN}Updated .gitignore${NC}"
fi

# Clean to ensure fresh start
echo -e "${YELLOW}Cleaning Bazel cache...${NC}"
bazel clean --expunge
rm -f MODULE.bazel.lock

# Fetch external repositories with verbose output
echo -e "${GREEN}Fetching external repositories (verbose mode)...${NC}"
echo -e "${CYAN}[DEBUG] Running: bazel fetch //... --verbose_failures --announce_rc${NC}"
bazel fetch //... --verbose_failures --announce_rc 2>&1 | tee /tmp/bazel_fetch.log

echo -e "${CYAN}[DEBUG] Checking what was fetched:${NC}"
ls -la ~/.cache/bazel/_bazel_*/*/external/ 2>/dev/null || echo "Cache not found in expected location"

# List external repositories
echo -e "${CYAN}[DEBUG] Querying external repositories:${NC}"
bazel query --output=build //external:* 2>&1 || true

# Check if imgui and test engine were fetched
echo -e "${CYAN}[DEBUG] Checking for imgui repository:${NC}"
find ~/.cache/bazel -name "imgui" -type d 2>/dev/null | head -5 || echo "Not found in cache"

echo -e "${CYAN}[DEBUG] Checking for imgui_test_engine repository:${NC}"
find ~/.cache/bazel -name "imgui_test_engine" -type d 2>/dev/null | head -5 || echo "Not found in cache"

# Build to verify with detailed output
echo -e "${GREEN}Verifying build configuration (verbose mode)...${NC}"
echo -e "${CYAN}[DEBUG] Running: bazel build //:imgui_test_app --verbose_failures --subcommands --sandbox_debug${NC}"
bazel build //:imgui_test_app --verbose_failures --subcommands 2>&1 | tee /tmp/bazel_build.log

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}======================================${NC}"

echo -e "\n${GREEN}Quick commands:${NC}"
echo "  Build:     bazel build //:imgui_test_app"
echo "  Test:      bazel test //:all_tests"
echo "  Coverage:  bazel run //:coverage"
echo "  Run:       ./bazel-bin/imgui_test_app"

echo -e "\n${CYAN}[DEBUG] Log files saved:${NC}"
echo "  Fetch log: /tmp/bazel_fetch.log"
echo "  Build log: /tmp/bazel_build.log"

echo -e "\n${YELLOW}Note: If you see dependency version warnings, they are informational.${NC}"
echo -e "${YELLOW}The build will still work correctly with the newer versions.${NC}"
