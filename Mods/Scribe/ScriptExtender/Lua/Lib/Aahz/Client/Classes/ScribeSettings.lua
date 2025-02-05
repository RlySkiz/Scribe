-- TODO figure out where class is defined :thonkers:
Scribe = Scribe or {}
Scribe.SettingsWindow = nil ---@type ExtuiWindow|nil
local keybindScribe ---@type Keybinding
local keybindNorbScribe ---@type Keybinding
local keybindWatchWindow ---@type Keybinding

local function openCloseScribe()
    if Scribe and Scribe.Window then
        Scribe.Window.Open = not Scribe.Window.Open
        Scribe.Window.Visible = Scribe.Window.Open
    end
end
local function openCloseScribeChanged()
    --TODO update for scribe/newscribe/newnewscribe/newscribenew
    -- keybind changed, update shortcut
    -- if module.GivenWindow ~= nil and module.GivenWindow.UserData ~= nil and module.GivenWindow.UserData.OpenCloseItem ~= nil then
    --     local newShortcut = ""
    --     local skOpenCloseSettings = LocalSettings:Get(EDSettings.OpenCloseDyeWindow) --[[@as Keybinding]]
    --     if skOpenCloseSettings ~= nil then
    --         if skOpenCloseSettings.Modifiers ~= nil and skOpenCloseSettings.Modifiers[1] ~= nil and skOpenCloseSettings.Modifiers[1] ~= "NONE" then
    --             newShortcut = string.format("%s+", skOpenCloseSettings.Modifiers[1])
    --         end
    --         newShortcut = newShortcut..skOpenCloseSettings.ScanCode
    --     end
    --     EDDebug("Changing shortcut: %s", newShortcut)
    --     module.GivenWindow.UserData.OpenCloseItem.Shortcut = newShortcut
    -- end
end
local testInspector
local function launchNorbScribe()
    testInspector = Inspector:GetOrCreate(_C(), LocalPropertyInterface)
end

---@type WatchWindow?
WatchWindow = nil
local function openCloseWatchWindow()
    if WatchWindow and WatchWindow.Window then
        WatchWindow.Window.Open = not WatchWindow.Window.Open
        WatchWindow.Window.Visible = WatchWindow.Window.Open
    end
end

function Scribe.GenerateSettingsWindow()
    Scribe.SettingsWindow = Ext.IMGUI.NewWindow(Ext.Loca.GetTranslatedString("hb23f384926b64c349bd61fd84f23c88c3d4d", "Scribe Settings"))
    Scribe.SettingsWindow.Open = false
    Scribe.SettingsWindow.Closeable = true
    -- settingsWindow.AlwaysAutoResize = true -- TODO need saved settings
    Scribe.SettingsWindow.AlwaysAutoResize = LocalSettings:GetOr(true, Static.Settings.SettingsAutoResize)
    Imgui.NewStyling(Scribe.SettingsWindow)

    local viewportMinConstraints = {250, 850}
    Scribe.SettingsWindow:SetStyle("WindowMinSize", viewportMinConstraints[1], viewportMinConstraints[2])
    local viewportMaxConstraints = Ext.IMGUI.GetViewportSize()
    viewportMaxConstraints[1] = math.floor(viewportMaxConstraints[1] / 3) -- 1/3 of width, max?
    viewportMaxConstraints[2] = math.floor(viewportMaxConstraints[2] *0.9) -- 9/10 of height, max?
    Scribe.SettingsWindow:SetSizeConstraints(viewportMinConstraints,viewportMaxConstraints)

    local keybindingsGroup = Scribe.SettingsWindow:AddGroup("KeybindingsGroup")
    keybindingsGroup:AddText(Ext.Loca.GetTranslatedString("h9727f426570b4fe39ae10934eb6510996b0d", "Open/Close Scribe"))
    keybindScribe = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseScribe", "SLASH", {"None"}, openCloseScribe, openCloseScribeChanged)

    keybindingsGroup:AddText("Launch Norbscribe")
    keybindNorbScribe = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "LaunchNorbScribe", "T", {"Shift"}, launchNorbScribe)

    WatchWindow = require("Lib.Aahz.Client.Classes.WatchWindow")
    keybindWatchWindow = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseWatchWindow", "Y", { "Alt"}, openCloseWatchWindow)

    return Scribe.SettingsWindow
end