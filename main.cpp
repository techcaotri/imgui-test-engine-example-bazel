// main.cpp - Simplified test application for ImGui Test Engine
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include "imgui_test_engine/imgui_te_engine.h"
#include "imgui_test_engine/imgui_te_context.h"
#include "imgui_test_engine/imgui_te_ui.h"
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <string>
#include <vector>

// Simple application state
struct AppState {
    char text_input[256] = "";
    bool checkbox_value = false;
    float slider_value = 0.5f;
    int combo_selection = 0;
    int selected_item = -1;
    std::vector<std::string> items = {"Item 1", "Item 2", "Item 3"};
    bool show_demo_window = false;
    
    void Reset() {
        text_input[0] = '\0';
        checkbox_value = false;
        slider_value = 0.5f;
        combo_selection = 0;
        selected_item = -1;
    }
};

// Global app state for tests
static AppState* g_app_state = nullptr;

// Register tests
static void RegisterTests(ImGuiTestEngine* engine) {
    ImGuiTest* t = nullptr;
    
    // Test 1: Basic Input
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "Basic Input");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        ctx->ItemInputValue("Text Input", "Hello Test");
        IM_CHECK_STR_EQ(g_app_state->text_input, "Hello Test");
    };
    
    // Test 2: Checkbox
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "Checkbox");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        ctx->ItemClick("Test Checkbox");
        IM_CHECK_EQ(g_app_state->checkbox_value, true);
        ctx->ItemClick("Test Checkbox");
        IM_CHECK_EQ(g_app_state->checkbox_value, false);
    };
    
    // Test 3: Button Click
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "Button");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        AppState initial = *g_app_state;
        ctx->ItemClick("Reset");
        IM_CHECK_EQ(g_app_state->slider_value, 0.5f);
    };
    
    // Test 4: Combo Selection
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "Combo");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        ctx->ItemClick("Combo");
        ctx->ItemClick("//##Combo_01/Option 2");
        IM_CHECK_EQ(g_app_state->combo_selection, 1);
    };
    
    // Test 5: List Selection
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "List");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        ctx->ItemClick("##listbox/Item 2");
        IM_CHECK_EQ(g_app_state->selected_item, 1);
    };
    
    // Test 6: Menu Navigation
    t = ImGuiTestEngine_RegisterTest(engine, "Demo", "Menu");
    t->TestFunc = [](ImGuiTestContext* ctx) {
        ctx->SetRef("Test Window");
        ctx->MenuClick("File/Reset");
        IM_CHECK_EQ(g_app_state->checkbox_value, false);
    };
}

// Main application window
void ShowTestWindow(AppState& state) {
    ImGui::Begin("Test Window", nullptr, ImGuiWindowFlags_MenuBar);
    
    // Menu bar
    if (ImGui::BeginMenuBar()) {
        if (ImGui::BeginMenu("File")) {
            if (ImGui::MenuItem("Reset")) {
                state.Reset();
            }
            if (ImGui::MenuItem("Exit")) {
                // Exit
            }
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("View")) {
            ImGui::MenuItem("Demo Window", nullptr, &state.show_demo_window);
            ImGui::EndMenu();
        }
        ImGui::EndMenuBar();
    }
    
    // Input widgets
    ImGui::SeparatorText("Input Widgets");
    
    ImGui::InputText("Text Input", state.text_input, sizeof(state.text_input));
    ImGui::Checkbox("Test Checkbox", &state.checkbox_value);
    ImGui::SliderFloat("Slider", &state.slider_value, 0.0f, 1.0f);
    
    const char* combo_items[] = {"Option 1", "Option 2", "Option 3"};
    ImGui::Combo("Combo", &state.combo_selection, combo_items, IM_ARRAYSIZE(combo_items));
    
    // List box
    ImGui::SeparatorText("List Box");
    if (ImGui::BeginListBox("##listbox")) {
        for (int i = 0; i < (int)state.items.size(); i++) {
            const bool is_selected = (state.selected_item == i);
            if (ImGui::Selectable(state.items[i].c_str(), is_selected)) {
                state.selected_item = i;
            }
        }
        ImGui::EndListBox();
    }
    
    // Buttons
    ImGui::SeparatorText("Actions");
    if (ImGui::Button("Reset")) {
        state.Reset();
    }
    ImGui::SameLine();
    if (ImGui::Button("Test Button")) {
        // Action
    }
    
    // Status
    ImGui::SeparatorText("Status");
    ImGui::Text("Checkbox: %s", state.checkbox_value ? "true" : "false");
    ImGui::Text("Slider: %.2f", state.slider_value);
    ImGui::Text("Selected: %d", state.selected_item);
    
    ImGui::End();
    
    // Show demo window if enabled
    if (state.show_demo_window) {
        ImGui::ShowDemoWindow(&state.show_demo_window);
    }
}

int main(int argc, char** argv) {
    // Parse arguments
    bool run_tests = false;
    bool headless = false;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--test") == 0) run_tests = true;
        if (strcmp(argv[i], "--headless") == 0) headless = true;
    }
    
    // Initialize GLFW
    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return -1;
    }
    
    // Configure GLFW
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    
    if (headless) {
        glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
    }
    
    // Create window
    GLFWwindow* window = glfwCreateWindow(1280, 720, "ImGui Test Application", nullptr, nullptr);
    if (!window) {
        fprintf(stderr, "Failed to create window\n");
        glfwTerminate();
        return -1;
    }
    
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);
    
    // Setup ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    
    // Setup backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");
    
    // Setup style
    ImGui::StyleColorsDark();
    
    // Create app state
    AppState app_state;
    g_app_state = &app_state;
    
    // Setup Test Engine
    ImGuiTestEngine* engine = ImGuiTestEngine_CreateContext();
    ImGuiTestEngineIO& test_io = ImGuiTestEngine_GetIO(engine);
    test_io.ConfigVerboseLevel = ImGuiTestVerboseLevel_Info;
    test_io.ConfigVerboseLevelOnError = ImGuiTestVerboseLevel_Debug;
    
    // Start engine and register tests
    ImGuiTestEngine_Start(engine, ImGui::GetCurrentContext());
    RegisterTests(engine);
    
    // Queue tests if requested
    if (run_tests) {
        ImGuiTestEngine_QueueTests(engine, ImGuiTestGroup_Tests);
    }
    
    // Main loop
    if (headless && run_tests) {
        // Run tests in headless mode
        printf("Running tests in headless mode...\n");
        
        // Run until tests complete (simplified)
        for (int frame = 0; frame < 100; frame++) {
            glfwPollEvents();
            
            ImGui_ImplOpenGL3_NewFrame();
            ImGui_ImplGlfw_NewFrame();
            ImGui::NewFrame();
            
            ShowTestWindow(app_state);
            ImGuiTestEngine_PostSwap(engine);
            
            ImGui::Render();
            ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
            
            glfwSwapBuffers(window);
            
            // Check if tests are done
            if (!ImGuiTestEngine_IsTestQueueEmpty(engine)) {
                continue;
            } else {
                break;
            }
        }
        
        printf("Tests completed!\n");
    } else {
        // Interactive mode
        while (!glfwWindowShouldClose(window)) {
            glfwPollEvents();
            
            ImGui_ImplOpenGL3_NewFrame();
            ImGui_ImplGlfw_NewFrame();
            ImGui::NewFrame();
            
            ShowTestWindow(app_state);
            
            // Show test engine UI
            if (!headless) {
                ImGuiTestEngine_ShowTestEngineWindows(engine, nullptr);
            }
            
            ImGuiTestEngine_PostSwap(engine);
            
            ImGui::Render();
            int display_w, display_h;
            glfwGetFramebufferSize(window, &display_w, &display_h);
            glViewport(0, 0, display_w, display_h);
            glClearColor(0.45f, 0.55f, 0.60f, 1.00f);
            glClear(GL_COLOR_BUFFER_BIT);
            ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
            
            glfwSwapBuffers(window);
        }
    }
    
    // FIXED: Correct cleanup order
    // 1. Stop test engine
    ImGuiTestEngine_Stop(engine);
    
    // 2. Shutdown ImGui backends
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    
    // 3. Destroy ImGui context FIRST
    ImGui::DestroyContext();
    
    // 4. THEN destroy test engine context
    ImGuiTestEngine_DestroyContext(engine);
    
    // 5. Cleanup GLFW
    glfwDestroyWindow(window);
    glfwTerminate();
    
    return 0;
}
