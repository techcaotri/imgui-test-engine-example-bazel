#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}ImGui Test Engine - Tests & Coverage${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if Xvfb is installed
if ! command -v Xvfb &> /dev/null; then
    echo -e "${RED}ERROR: Xvfb not found${NC}"
    echo -e "${YELLOW}Install it with:${NC}"
    echo -e "  ${CYAN}sudo apt-get update && sudo apt-get install -y xvfb${NC}"
    exit 1
fi

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo -e "${YELLOW}Warning: lcov not found. Installing...${NC}"
    sudo apt-get update && sudo apt-get install -y lcov
fi

echo -e "${GREEN}Starting virtual display (Xvfb)...${NC}"
# Find an available display number
DISPLAY_NUM=99
while [ -e "/tmp/.X${DISPLAY_NUM}-lock" ]; do
    DISPLAY_NUM=$((DISPLAY_NUM + 1))
done

# Start Xvfb (suppress XKB warnings)
Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 2>/dev/null &
XVFB_PID=$!
export DISPLAY=:${DISPLAY_NUM}

# Wait for Xvfb to start
sleep 2

echo -e "${GREEN}Display :${DISPLAY_NUM} ready${NC}"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up Xvfb...${NC}"
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# Run tests (don't exit on failure)
echo -e "${GREEN}Running tests...${NC}"
set +e  # Don't exit on error
bazel test //:all_tests --test_output=all
TEST_EXIT_CODE=$?
set -e

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${YELLOW}Warning: Some tests failed (exit code: $TEST_EXIT_CODE)${NC}"
    echo -e "${CYAN}Continuing to generate reports...${NC}"
fi

# Run coverage (continue even if tests fail)
echo -e "${GREEN}Running coverage tests...${NC}"
set +e  # Don't exit on error
bazel coverage --config=coverage //:all_tests --combined_report=lcov
COVERAGE_EXIT_CODE=$?
set -e

if [ $COVERAGE_EXIT_CODE -ne 0 ]; then
    echo -e "${YELLOW}Warning: Coverage collection had errors (exit code: $COVERAGE_EXIT_CODE)${NC}"
fi

# Generate HTML report from whatever coverage data we have
echo -e "${GREEN}Generating HTML coverage report...${NC}"
OUTPUT_DIR="coverage_report"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/html"

# Try multiple locations for coverage data
COVERAGE_FILE=""
POSSIBLE_LOCATIONS=(
    "$(bazel info output_base)/execroot/_main/bazel-out/_coverage/_coverage_report.dat"
    "$(bazel info output_base)/execroot/_main/bazel-out/k8-dbg/testlogs/*/coverage.dat"
    "bazel-out/_coverage/_coverage_report.dat"
)

for loc in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -f "$loc" ] || ls $loc 2>/dev/null | head -1 | grep -q .; then
        COVERAGE_FILE=$(ls $loc 2>/dev/null | head -1)
        break
    fi
done

if [ -n "$COVERAGE_FILE" ] && [ -f "$COVERAGE_FILE" ]; then
    echo -e "${GREEN}Found coverage data: $COVERAGE_FILE${NC}"
    
    # Generate HTML even if data is incomplete
    genhtml "$COVERAGE_FILE" \
        --output-directory "$OUTPUT_DIR/html" \
        --title "ImGui Test Engine Coverage" \
        --legend \
        --show-details \
        --ignore-errors empty,source 2>&1 | tee "$OUTPUT_DIR/genhtml.log"
    
    GENHTML_EXIT=$?
    if [ $GENHTML_EXIT -ne 0 ]; then
        echo -e "${YELLOW}genhtml reported warnings, but report may still be useful${NC}"
    fi
else
    echo -e "${RED}No coverage data found${NC}"
    echo -e "${YELLOW}Creating placeholder report...${NC}"
    
    cat > "$OUTPUT_DIR/html/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Coverage Report - No Data</title></head>
<body>
<h1>No Coverage Data Available</h1>
<p>Coverage data could not be generated. This usually means:</p>
<ul>
<li>Tests failed before coverage could be collected</li>
<li>No code was executed during tests</li>
<li>Coverage instrumentation was not enabled</li>
</ul>
<p>Check test logs for more details.</p>
</body>
</html>
EOF
fi

# Collect test results
echo -e "${GREEN}Collecting test results...${NC}"
TEST_RESULTS_DIR="test_results"
rm -rf "$TEST_RESULTS_DIR"
mkdir -p "$TEST_RESULTS_DIR"

# Copy all test logs and XML reports
find bazel-testlogs -name "test.xml" -o -name "test.log" 2>/dev/null | while read file; do
    cp "$file" "$TEST_RESULTS_DIR/$(basename $(dirname $file))_$(basename $file)" 2>/dev/null || true
done

# Create summary
cat > "$TEST_RESULTS_DIR/summary.txt" << EOF
Test Run Summary
================
Date: $(date)
Test Exit Code: $TEST_EXIT_CODE
Coverage Exit Code: $COVERAGE_EXIT_CODE

Test Results:
$(find bazel-testlogs -name "test.xml" 2>/dev/null | wc -l) XML reports generated
$(find bazel-testlogs -name "test.log" 2>/dev/null | wc -l) log files generated

EOF

echo -e "${BLUE}======================================${NC}"
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${YELLOW}Some tests failed - check reports for details${NC}"
fi
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${CYAN}Test Results Directory:${NC}"
echo -e "  $(pwd)/$TEST_RESULTS_DIR/"
echo -e ""
echo -e "${CYAN}Individual Test Logs:${NC}"
ls -1 bazel-testlogs/*/test.xml 2>/dev/null | while read f; do
    TEST_NAME=$(basename $(dirname $f))
    STATUS=$(grep -o 'failures="[0-9]*"' $f | cut -d'"' -f2)
    if [ "$STATUS" = "0" ]; then
        echo -e "  ${GREEN}✓${NC} $TEST_NAME: $f"
    else
        echo -e "  ${RED}✗${NC} $TEST_NAME: $f ($STATUS failures)"
    fi
done
echo -e ""
echo -e "${CYAN}Coverage Report:${NC}"
if [ -f "$OUTPUT_DIR/html/index.html" ]; then
    echo -e "  $(pwd)/$OUTPUT_DIR/html/index.html"
    echo -e ""
    echo -e "${CYAN}Open reports:${NC}"
    echo -e "  xdg-open $OUTPUT_DIR/html/index.html"
    echo -e "  cat $TEST_RESULTS_DIR/summary.txt"
else
    echo -e "  ${YELLOW}No coverage report generated${NC}"
fi

# Exit with original test status for CI/CD
exit $TEST_EXIT_CODE
