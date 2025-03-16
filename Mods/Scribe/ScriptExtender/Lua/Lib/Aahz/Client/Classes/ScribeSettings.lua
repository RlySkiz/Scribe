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

local function openCloseWatchWindow()
    if Scribe and Scribe.FirstTimeWindow then
        Scribe:OpenClose()
    elseif Scribe.PropertyWatch then
        Scribe.PropertyWatch.Window.Open = not Scribe.PropertyWatch.Window.Open
        Scribe.PropertyWatch.Window.Visible = Scribe.PropertyWatch.Window.Open
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

    keybindingsGroup:AddText("Open Watch Window") -- Testing
    keybindWatchWindow = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseWatchWindow", "Y", { "Alt"}, openCloseWatchWindow)

    local generalSettingsGroup = Scribe.SettingsWindow:AddGroup("GeneralSettings")
    generalSettingsGroup:AddText(Ext.Loca.GetTranslatedString("h415a6f6f4a3943478768502bf2e5e9a78d7b", "General Settings"))
    local tagFlagCheck = generalSettingsGroup:AddCheckbox(Ext.Loca.GetTranslatedString("hf3f0081755c94d6aab8f745bbebe900182bb", "Separate Tag and Flag Components"))
    if LocalSettings:Get("SeparateTagsAndFlags") then -- If it already exists and is set to true set default to be checked
        tagFlagCheck.Checked = true
    end
    tagFlagCheck.OnChange = function()
        if tagFlagCheck.Checked then
            LocalSettings:AddOrChange("SeparateTagsAndFlags", true)
            -- Scribe.UpdateAllInstances()
        else
            LocalSettings:AddOrChange("SeparateTagsAndFlags", false)
            -- Scribe.UpdateAllInstances()
        end
    end

    Scribe.SettingsWindow:AddSeparatorText("ImguiThemes")
    ImguiThemeManager:CreateUpdateableDisplay(Scribe.SettingsWindow)

    return Scribe.SettingsWindow
end

--- [Not functional][DoNotUse]
-- Function to update all instances at once for general settings to apply
-- function Scribe.UpdateAllInstances()
--     if Scribe and #Scribe.Inspectors > 0 then
--         for _,instance in pairs(Scribe.Inspectors) do
--             instance:UpdateInspectTarget(instance.Target)
--         end
--     end
--     if Inspector and #Inspector.Inspectors > 0 then
--         for _,instance in pairs(Inspector.Inspectors) do
--             instance:UpdateInspectTarget(instance.Target)
--         end
--     end
-- end