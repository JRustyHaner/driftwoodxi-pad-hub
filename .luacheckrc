-- vim: ft=lua
std = 'luajit'

files['addons/dwhub'] = {
    globals = {
        'addon',
        'ashita',
        'bit',
        'imgui',
        'chat',
        'T',
        -- ImGui enums commonly used by Ashita addons
        'ImGuiCol_WindowBg',
        'ImGuiCol_Border',
        'ImGuiCol_Text',
        'ImGuiCol_TitleBg',
        'ImGuiCol_TitleBgActive',
        'ImGuiCol_FrameBg',
        'ImGuiCol_Button',
        'ImGuiCol_ButtonHovered',
        'ImGuiCol_ButtonActive',
        'ImGuiCol_Header',
        'ImGuiCol_HeaderHovered',
        'ImGuiCol_HeaderActive',
        'ImGuiCol_ScrollbarBg',
        'ImGuiCol_ScrollbarGrab',
        'ImGuiStyleVar_WindowRounding',
        'ImGuiStyleVar_FrameRounding',
        'ImGuiStyleVar_WindowBorderSize',
        'ImGuiStyleVar_WindowPadding',
        'ImGuiStyleVar_ItemSpacing',
        'ImGuiCond_FirstUseEver',
        'ImGuiWindowFlags_NoCollapse',
        'ImGuiWindowFlags_NoScrollbar',
        'ImGuiInputTextFlags_EnterReturnsTrue',
        'ImGuiKey_UpArrow',
        'ImGuiKey_DownArrow',
        'ImGuiKey_Enter',
        'ImGuiKey_GamepadFaceDown',
        'ImGuiKey_GamepadFaceRight',
        'ImGuiKey_GamepadDpadUp',
        'ImGuiKey_GamepadDpadDown',
        'ImGuiKey_Escape',
        'ImGuiConfigFlags_NavEnableGamepad',
        'ImGuiConfigFlags_NavEnableKeyboard',
    },
}

files['spec'] = {
    std = '+busted',
}

exclude_files = {
    '.lua/**',
}
