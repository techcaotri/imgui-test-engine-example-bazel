// app_logic.h - Application logic separated from main
#ifndef APP_LOGIC_H
#define APP_LOGIC_H

#include <string>
#include <vector>

// Application state
struct AppState {
    char text_input[256] = "";
    bool checkbox_value = false;
    float slider_value = 0.5f;
    int combo_selection = 0;
    int selected_item = -1;
    std::vector<std::string> items = {"Item 1", "Item 2", "Item 3"};
    bool show_demo_window = false;
    
    void Reset();
};

// Function to show the test window
void ShowTestWindow(AppState& state);

// Main application entry point (called from main)
int RunApplication(int argc, char** argv);

#endif // APP_LOGIC_H
