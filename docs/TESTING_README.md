# ImGui Test Engine - Testing & Coverage Guide

## Running Tests

### 1. Run All Tests
```bash
bazel test //:all_tests --test_output=all
```

### 2. Run Specific Test Suites
```bash
# Widget tests only
bazel test //:test_widgets --test_output=all

# Integration tests only
bazel test //:test_integration --test_output=all

# Performance tests
bazel test //:test_performance --test_output=all
```

### 3. Run Tests with GUI (Interactive Mode)
```bash
# Build and run with test engine UI
bazel build //:imgui_test_app
./bazel-bin/imgui_test_app --test
```

### 4. Run Tests Headless
```bash
./bazel-bin/imgui_test_app --test --headless
```

## Test Reports

### XML Test Reports (JUnit format)
Bazel generates XML test reports automatically:

```bash
# Run tests
bazel test //:all_tests

# Reports are in:
# bazel-testlogs/imgui_test/test.xml
# bazel-testlogs/test_widgets/test.xml
# bazel-testlogs/test_integration/test.xml
# bazel-testlogs/test_performance/test.xml
```

### View Test Summary
```bash
bazel test //:all_tests --test_summary=detailed
```

## Coverage Reports

### Method 1: Using the build script (Recommended)
```bash
./scripts/build_bazel.sh --coverage --test
```

This will:
1. Build with coverage instrumentation
2. Run all tests
3. Generate HTML coverage report
4. Output location: `coverage_report/html/index.html`

### Method 2: Manual Coverage Generation

#### Step 1: Run tests with coverage
```bash
bazel coverage --config=coverage //:all_tests
```

#### Step 2: Generate HTML report
```bash
# Make script executable
chmod +x generate_coverage.sh

# Generate report
./generate_coverage.sh
```

#### Step 3: View the report
```bash
# Open in browser
xdg-open coverage_report/html/index.html

# Or with Firefox
firefox coverage_report/html/index.html

# Or with Chrome
google-chrome coverage_report/html/index.html
```

### Method 3: Using lcov directly

```bash
# Run coverage
bazel coverage --config=coverage //:all_tests

# Find the coverage file
COVERAGE_FILE=$(bazel info output_base)/*/testlogs/all_tests/coverage.dat

# Generate HTML
mkdir -p coverage_report/html
genhtml $COVERAGE_FILE --output-directory coverage_report/html

# Open report
xdg-open coverage_report/html/index.html
```

## Coverage Report Contents

The HTML coverage report shows:
- **Line Coverage**: Percentage of code lines executed
- **Function Coverage**: Percentage of functions called
- **Branch Coverage**: Percentage of decision branches taken
- **File-by-file breakdown**: Detailed coverage for each source file
- **Color-coded source**: Green (covered), Red (not covered), Orange (partially covered)

## Tips

### Improve Coverage
1. Run tests with GUI to ensure all UI elements are exercised:
   ```bash
   ./bazel-bin/imgui_test_app --test
   ```

2. Add more test cases to cover edge cases

3. Check which files have low coverage:
   ```bash
   # After generating coverage report
   grep -r "headerCovTableEntry" coverage_report/html/*.html | grep -v "100.0 %"
   ```

### Continuous Integration
For CI pipelines, use:
```bash
# Run tests and generate machine-readable coverage
bazel coverage --config=coverage //:all_tests --combined_report=lcov

# Convert to Cobertura format (if needed)
lcov_cobertura coverage.dat -o coverage.xml
```

### Quick Test During Development
```bash
# Fast feedback loop
bazel test //:test_widgets --test_output=errors --cache_test_results=no
```

## Troubleshooting

### "lcov not found"
```bash
# Install lcov
sudo apt-get update && sudo apt-get install -y lcov
```

### "No coverage data found"
Make sure you ran with coverage config:
```bash
bazel coverage --config=coverage //:all_tests
```

### Coverage report is empty
Check that tests actually ran:
```bash
bazel test //:all_tests --test_output=all
```

### Tests timeout
Increase timeout:
```bash
bazel test //:all_tests --test_timeout=300
```
