-- TODO figure out where class is defined :thonkers:
Scribe = Scribe or {}
Scribe.SettingsWindow = nil ---@type ExtuiWindow|nil
local keybindScribe ---@type Keybinding
local keybindNorbScribe ---@type Keybinding
local keybindWatchWindow ---@type Keybinding

local function openCloseScribe()
    if Scribe and Scribe.OpenClose then
        Scribe:OpenClose()
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

-- TODO move this to cleaner place
---@type WatchWindow?
WatchWindow = nil
local function openCloseWatchWindow()
    if Scribe and Scribe.FirstTimeWindow then
        Scribe:OpenClose()
    elseif WatchWindow and WatchWindow.Window then
        WatchWindow.Window.Open = not WatchWindow.Window.Open
        WatchWindow.Window.Visible = WatchWindow.Window.Open
    end
end

---Just a hypers for fun as a lil treat
---@param el ExtuiTreeParent
local function hypers(el)
    local layoutTable = el:AddTable("", 3)
    layoutTable:AddColumn("L", "WidthStretch", 2)
    layoutTable:AddColumn("M", "WidthStretch", 10)
    layoutTable:AddColumn("R", "WidthStretch", 2)
    local layoutRow = layoutTable:AddRow()
    local leftCell = layoutRow:AddCell()
    local middleCell = layoutRow:AddCell()
    local rightCell = layoutRow:AddCell()
    local hypersImg = Imgui.CreateAnimation(middleCell, "hypers", {64,64}, 96, 3, 288, 7)

    middleCell:AddText("We makin' mods? LFG").SameLine = true
    el:AddSeparator()
end

function Scribe.GenerateSettingsWindow()
    Scribe.SettingsWindow = Imgui.CreateCommonWindow(Ext.Loca.GetTranslatedString("hb23f384926b64c349bd61fd84f23c88c3d4d", "Scribe Settings"), {
        AlwaysAutoResize = LocalSettings:GetOr(true, Static.Settings.SettingsAutoResize),
        MinSize = {250, 850},
        MaxSizePercentage = { 0.333333, 0.85},
    })
    hypers(Scribe.SettingsWindow)

    local keybindingsGroup = Scribe.SettingsWindow:AddGroup("KeybindingsGroup")
    keybindingsGroup:AddText(Ext.Loca.GetTranslatedString("h9727f426570b4fe39ae10934eb6510996b0d", "Open/Close Scribe"))
    keybindScribe = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseScribe", "T", {"Shift"}, openCloseScribe, openCloseScribeChanged)

    WatchWindow = require("Lib.Aahz.Client.Classes.WatchWindow")
    keybindingsGroup:AddText("Open Watch Window") -- Testing
    keybindWatchWindow = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseWatchWindow", "Y", { "Alt"}, openCloseWatchWindow)

    Scribe.SettingsWindow:AddSeparatorText("ImguiThemes")
    ImguiThemeManager:CreateUpdateableDisplay(Scribe.SettingsWindow)

    return Scribe.SettingsWindow
end