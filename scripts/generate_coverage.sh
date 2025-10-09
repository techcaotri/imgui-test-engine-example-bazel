#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Generating Coverage Report${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo -e "${YELLOW}Warning: lcov not found. Installing...${NC}"
    sudo apt-get update && sudo apt-get install -y lcov
fi

if ! command -v genhtml &> /dev/null; then
    echo -e "${YELLOW}Warning: genhtml not found (should come with lcov)${NC}"
    exit 1
fi

# Get bazel output base
OUTPUT_BASE=$(bazel info output_base 2>/dev/null)
EXEC_ROOT=$(bazel info execution_root 2>/dev/null)

echo -e "${GREEN}Looking for coverage data...${NC}"

# Find coverage data files - try multiple locations
COVERAGE_FILES=()

# Location 1: Combined coverage report
if [ -f "$OUTPUT_BASE/execroot/_main/bazel-out/_coverage/_coverage_report.dat" ]; then
    COVERAGE_FILES+=("$OUTPUT_BASE/execroot/_main/bazel-out/_coverage/_coverage_report.dat")
fi

# Location 2: Individual test coverage files
for file in $(find "$OUTPUT_BASE" -name "coverage.dat" -o -name "_coverage_report.dat" 2>/dev/null); do
    COVERAGE_FILES+=("$file")
done

# Location 3: Check bazel-out directly
if [ -f "bazel-out/_coverage/_coverage_report.dat" ]; then
    COVERAGE_FILES+=("bazel-out/_coverage/_coverage_report.dat")
fi

if [ ${#COVERAGE_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No coverage data found.${NC}"
    echo -e "${YELLOW}Coverage data locations checked:${NC}"
    echo -e "  - $OUTPUT_BASE/execroot/_main/bazel-out/_coverage/_coverage_report.dat"
    echo -e "  - bazel-out/_coverage/_coverage_report.dat"
    echo -e "  - $OUTPUT_BASE/**/*coverage*.dat"
    echo -e ""
    echo -e "${CYAN}To generate coverage data, run:${NC}"
    echo -e "  bazel coverage --config=coverage //:all_tests"
    echo -e ""
    echo -e "${YELLOW}Creating placeholder report...${NC}"
    
    OUTPUT_DIR="coverage_report"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/html"
    
    cat > "$OUTPUT_DIR/html/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Coverage Report - No Data</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 20px; border-radius: 5px; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>⚠️ No Coverage Data Available</h1>
    <div class="warning">
        <p><strong>Coverage data could not be found or generated.</strong></p>
        <p>This usually means:</p>
        <ul>
            <li>Tests have not been run with coverage instrumentation</li>
            <li>Tests failed before coverage could be collected</li>
            <li>Coverage files were not generated in expected locations</li>
        </ul>
        <p><strong>To generate coverage:</strong></p>
        <ol>
            <li>Run: <code>bazel coverage --config=coverage //:all_tests</code></li>
            <li>Then run: <code>./generate_coverage.sh</code></li>
        </ol>
        <p>Or use the all-in-one script: <code>./run_tests_coverage.sh</code></p>
    </div>
</body>
</html>
EOF
    
    echo -e "${YELLOW}Placeholder report created at: coverage_report/html/index.html${NC}"
    exit 1
fi

# Use the first (usually most recent) coverage file found
COVERAGE_FILE="${COVERAGE_FILES[0]}"
echo -e "${GREEN}Found coverage data: ${COVERAGE_FILE}${NC}"

if [ ${#COVERAGE_FILES[@]} -gt 1 ]; then
    echo -e "${CYAN}Note: Found ${#COVERAGE_FILES[@]} coverage files, using the first one${NC}"
fi

# Create output directory
OUTPUT_DIR="coverage_report"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Check if coverage file has any data
if [ ! -s "$COVERAGE_FILE" ]; then
    echo -e "${YELLOW}Warning: Coverage file is empty${NC}"
fi

# Generate HTML report with relaxed error handling
echo -e "${GREEN}Generating HTML report...${NC}"
set +e  # Don't exit on genhtml errors

genhtml "$COVERAGE_FILE" \
    --output-directory "$OUTPUT_DIR/html" \
    --title "ImGui Test Engine Coverage" \
    --legend \
    --show-details \
    --ignore-errors empty,source,mismatch \
    2>&1 | tee "$OUTPUT_DIR/genhtml.log"

GENHTML_EXIT=$?
set -e

if [ $GENHTML_EXIT -ne 0 ]; then
    echo -e "${YELLOW}Warning: genhtml completed with errors (exit code: $GENHTML_EXIT)${NC}"
    echo -e "${CYAN}Check $OUTPUT_DIR/genhtml.log for details${NC}"
    
    # Check if any HTML was generated despite errors
    if [ ! -f "$OUTPUT_DIR/html/index.html" ]; then
        echo -e "${RED}No HTML report was generated${NC}"
        
        # Create error report
        cat > "$OUTPUT_DIR/html/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Coverage Report - Generation Error</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; padding: 20px; border-radius: 5px; }
        pre { background: #f4f4f4; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>❌ Coverage Report Generation Failed</h1>
    <div class="error">
        <p><strong>genhtml failed to generate the coverage report.</strong></p>
        <p>Common causes:</p>
        <ul>
            <li>Coverage data file is empty or corrupted</li>
            <li>Source files could not be found</li>
            <li>Mismatch between coverage data and source files</li>
        </ul>
        <p><strong>Debug information:</strong></p>
        <pre>$(cat "$OUTPUT_DIR/genhtml.log" 2>/dev/null || echo "No log available")</pre>
    </div>
</body>
</html>
EOF
        exit 1
    else
        echo -e "${YELLOW}Partial HTML report was generated despite errors${NC}"
    fi
fi

# Generate summary
echo -e "${GREEN}Generating summary...${NC}"
lcov --summary "$COVERAGE_FILE" 2>/dev/null | tee "$OUTPUT_DIR/summary.txt" || \
    echo "Coverage summary not available" > "$OUTPUT_DIR/summary.txt"

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Coverage report generated!${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e ""
echo -e "${CYAN}Report files:${NC}"
echo -e "  HTML Report: $(pwd)/$OUTPUT_DIR/html/index.html"
echo -e "  Summary:     $(pwd)/$OUTPUT_DIR/summary.txt"
echo -e "  Gen Log:     $(pwd)/$OUTPUT_DIR/genhtml.log"
echo -e ""
echo -e "${CYAN}Open report with:${NC}"
echo -e "  xdg-open $OUTPUT_DIR/html/index.html"
echo -e "  or"
echo -e "  firefox $OUTPUT_DIR/html/index.html"

# Show summary if available
if [ -s "$OUTPUT_DIR/summary.txt" ]; then
    echo -e ""
    echo -e "${CYAN}Coverage Summary:${NC}"
    cat "$OUTPUT_DIR/summary.txt"
fi
