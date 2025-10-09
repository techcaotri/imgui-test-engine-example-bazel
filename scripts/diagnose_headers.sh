#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Diagnosing ImGui Headers Issue${NC}"
echo -e "${BLUE}======================================${NC}"

# Clean everything first
echo -e "${YELLOW}Cleaning Bazel cache...${NC}"
bazel clean --expunge
rm -f MODULE.bazel.lock

# Fetch only
echo -e "${GREEN}Fetching repositories...${NC}"
bazel fetch //... 2>&1 | grep -v "WARNING: For repository" || true

# Get bazel output base
OUTPUT_BASE=$(bazel info output_base 2>/dev/null)
echo -e "${CYAN}Bazel output base: $OUTPUT_BASE${NC}"

# Find the imgui repository location
echo -e "\n${CYAN}[1] Locating ImGui repository...${NC}"
IMGUI_PATH="$OUTPUT_BASE/external/+git_repos_ext+imgui"

if [ ! -d "$IMGUI_PATH" ]; then
    echo -e "${RED}ImGui repository not found at expected location!${NC}"
    echo -e "${YELLOW}Searching for it...${NC}"
    find "$OUTPUT_BASE/external" -type d -name "*imgui*" 2>/dev/null || echo "Not found"
    exit 1
fi

echo -e "${GREEN}ImGui path: $IMGUI_PATH${NC}"

# List all .h files in imgui
echo -e "\n${CYAN}[2] Headers in ImGui repository:${NC}"
ls -1 "$IMGUI_PATH"/*.h 2>/dev/null | sort

# Check specifically for imgui_internal.h
echo -e "\n${CYAN}[3] Checking for imgui_internal.h:${NC}"
if [ -f "$IMGUI_PATH/imgui_internal.h" ]; then
    echo -e "${GREEN}✓ imgui_internal.h EXISTS${NC}"
    
    # Check for the specific flags we need
    echo -e "\n${CYAN}[4] Searching for ImGuiItemStatusFlags in imgui_internal.h:${NC}"
    grep -n "enum ImGuiItemStatusFlags_" "$IMGUI_PATH/imgui_internal.h" | head -5
    echo -e "${CYAN}Specific flags we need:${NC}"
    grep -n "ImGuiItemStatusFlags_Openable\|ImGuiItemStatusFlags_Opened\|ImGuiItemStatusFlags_Checkable\|ImGuiItemStatusFlags_Checked" "$IMGUI_PATH/imgui_internal.h" | head -10
else
    echo -e "${RED}✗ imgui_internal.h DOES NOT EXIST${NC}"
    exit 1
fi

# Check BUILD file
echo -e "\n${CYAN}[5] Generated BUILD.bazel for imgui:${NC}"
if [ -f "$IMGUI_PATH/BUILD.bazel" ]; then
    cat "$IMGUI_PATH/BUILD.bazel"
else
    echo -e "${RED}BUILD.bazel not found${NC}"
fi

# Find test engine repository
echo -e "\n${CYAN}[6] Locating ImGui Test Engine repository...${NC}"
TEST_ENGINE_PATH="$OUTPUT_BASE/external/+git_repos_ext+imgui_test_engine"

if [ ! -d "$TEST_ENGINE_PATH" ]; then
    echo -e "${RED}Test Engine repository not found at expected location!${NC}"
    exit 1
fi

echo -e "${GREEN}Test Engine path: $TEST_ENGINE_PATH${NC}"

# Check what imgui_te_context.cpp includes
echo -e "\n${CYAN}[7] Checking includes in imgui_te_context.cpp:${NC}"
if [ -f "$TEST_ENGINE_PATH/imgui_test_engine/imgui_te_context.cpp" ]; then
    echo -e "${YELLOW}First 30 lines:${NC}"
    head -30 "$TEST_ENGINE_PATH/imgui_test_engine/imgui_te_context.cpp"
else
    echo -e "${RED}imgui_te_context.cpp not found${NC}"
fi

# Check the test engine's header
echo -e "\n${CYAN}[8] Checking imgui_te_context.h includes:${NC}"
if [ -f "$TEST_ENGINE_PATH/imgui_test_engine/imgui_te_context.h" ]; then
    head -30 "$TEST_ENGINE_PATH/imgui_test_engine/imgui_te_context.h" | grep "#include"
fi

# Check BUILD file for test engine
echo -e "\n${CYAN}[9] Generated BUILD.bazel for test engine:${NC}"
if [ -f "$TEST_ENGINE_PATH/BUILD.bazel" ]; then
    cat "$TEST_ENGINE_PATH/BUILD.bazel"
else
    echo -e "${RED}BUILD.bazel not found${NC}"
fi

echo -e "\n${BLUE}======================================${NC}"
echo -e "${GREEN}Diagnosis complete!${NC}"
echo -e "${BLUE}======================================${NC}"

echo -e "\n${YELLOW}Next: Try a test compile to see exact error${NC}"
