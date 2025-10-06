# ImGui Test Engine - Test Mode Options

## Quick Comparison

| Mode | Script | Use Case | Reports | Time |
|------|--------|----------|---------|------|
| **Headless** | `run_tests_coverage.sh` | CI/CD, automated testing | ✓ Complete | ~30s |
| **GUI Only** | `run_tests_gui_coverage.sh` | Visual debugging, manual testing | ⚠ Partial | ~2min |
| **Hybrid** | `run_tests_gui_then_coverage.sh` | Best of both worlds | ✓ Complete | ~3min |

## Setup (One Time)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y xvfb lcov

# Make all scripts executable
chmod +x run_tests_coverage.sh
chmod +x run_tests_gui_coverage.sh
chmod +x run_tests_gui_then_coverage.sh
chmod +x xvfb_test_wrapper.sh
chmod +x generate_coverage.sh
```

## Option 1: Headless Mode (Fastest, Most Reliable)

**When to use:**
- Automated testing / CI/CD
- Quick feedback during development
- Accurate coverage metrics needed
- No GUI environment available

**Run:**
```bash
./run_tests_coverage.sh
```

**Pros:**
- Fast execution
- Reliable coverage data
- Works without display
- Best for automation

**Cons:**
- Can't see tests visually
- Harder to debug UI issues

**Output:**
- `test_results/` - All test logs and XML
- `coverage_report/html/index.html` - Coverage report

---

## Option 2: GUI Only Mode (Visual Inspection)

**When to use:**
- Debugging visual issues
- Want to see tests execute
- Manual testing
- Checking for UI glitches

**Run:**
```bash
./run_tests_gui_coverage.sh
```

**Pros:**
- See tests in real-time
- Interactive debugging
- Catch visual bugs
- Manual interaction possible

**Cons:**
- Coverage may be incomplete
- Slower
- Requires display

**Output:**
- `test_results_gui/session_info.txt` - Session summary
- `coverage_report/html/index.html` - Partial coverage (if available)

**Note:** Coverage in GUI mode may be unreliable because:
- Coverage data written on process exit
- Manual window close may not flush data properly
- For accurate coverage, use headless or hybrid mode

---

## Option 3: Hybrid Mode (Recommended for Thorough Testing)

**When to use:**
- Want visual inspection AND accurate metrics
- Thorough testing before release
- Debugging + documentation
- Best overall coverage

**Run:**
```bash
./run_tests_gui_then_coverage.sh
```

**Workflow:**
1. **Phase 1 (GUI):** Tests run with visual feedback
   - Watch tests execute
   - Manually test interactions
   - Check for visual issues
   - Close when done

2. **Phase 2 (Headless):** Same tests run automatically
   - Accurate coverage collected
   - Complete test reports generated
   - No user interaction needed

**Pros:**
- Best of both worlds
- Complete coverage data
- Visual verification included
- Thorough testing

**Cons:**
- Takes longer (~3 min total)
- Requires manual interaction for GUI phase

**Output:**
- `test_results/summary.txt` - Full session report
- `test_results/*.xml` - Individual test results
- `coverage_report/html/index.html` - Complete coverage

---

## Manual GUI Testing (Interactive)

If you just want to play with the GUI and manually run tests:

```bash
# Build the app
bazel build //:imgui_test_app

# Run with test engine UI
./bazel-bin/imgui_test_app --test

# Or run without auto-starting tests
./bazel-bin/imgui_test_app
```

In the GUI:
- Open **"Test Engine"** window from menu
- Browse available tests
- Click individual tests to run them
- Watch execution in real-time

---

## Viewing Reports

```bash
# Open coverage report
xdg-open coverage_report/html/index.html

# View test summary
cat test_results/summary.txt

# Check specific test results
cat test_results/imgui_test_test.xml
ls -l test_results/

# View detailed test logs
cat bazel-testlogs/imgui_test/test.log
```

---

## Recommended Workflow

### During Development
```bash
# Quick feedback loop
./run_tests_coverage.sh
```

### Before Committing
```bash
# Thorough check with visual inspection
./run_tests_gui_then_coverage.sh
```

### In CI/CD
```bash
# Automated, reliable
./run_tests_coverage.sh
```

### Debugging Issues
```bash
# Visual debugging
./run_tests_gui_coverage.sh

# Or manual testing
./bazel-bin/imgui_test_app --test
```

---

## Troubleshooting

### "Failed to initialize GLFW" in headless mode
The Xvfb wrapper should handle this automatically. If it still fails:
```bash
# Start Xvfb manually
Xvfb :99 -screen 0 1280x720x24 &
export DISPLAY=:99

# Run tests
bazel test //:all_tests
```

### GUI mode shows no coverage
This is expected - use hybrid mode for accurate coverage with GUI inspection.

### Tests timeout
Increase timeout:
```bash
bazel test //:all_tests --test_timeout=600
```

### No display for GUI mode
Use headless mode instead:
```bash
./run_tests_coverage.sh
```
