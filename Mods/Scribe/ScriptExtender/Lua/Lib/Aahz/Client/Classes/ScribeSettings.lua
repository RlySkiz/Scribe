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
    if testInspector then
        testInspector.Window.Open = not testInspector.Window.Open
        testInspector.Window.Visible = testInspector.Window.Open
    end
end

---@type WatchWindow?
WatchWindow = nil
local function openCloseWatchWindow()
    if WatchWindow and WatchWindow.Window then
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
    local hypersImg = middleCell:AddImage("hypers", {64,64})
    middleCell:AddText("We makin' mods? LFG").SameLine = true
    el:AddSeparator()
    local function getUVsForFrame(index)
        local iconsPerRow = 3
        local iconSize = 96
        local textureSize = 288
    
        local iconX = index % iconsPerRow
        local iconY = math.floor(index / iconsPerRow)
    
        iconY = iconY % iconsPerRow -- safety wrap?
    
        local uStart = iconX * iconSize / textureSize
        local vStart = iconY * iconSize / textureSize
        local uEnd = (iconX + 1) * iconSize / textureSize
        local vEnd = (iconY + 1) * iconSize / textureSize
    
        return uStart, vStart, uEnd, vEnd
    end
    local scheduler = RX.CooperativeScheduler.Create()
    
    local animObservable = RX.Observable.FromCoroutine(function()
        local i = 0
        while true do
            coroutine.yield(i)
            if i >= 7 then
                i = 0
            else
                i = i + 1
            end
        end
    end, scheduler)
    
    animObservable:Subscribe(function(i)
            -- local txt = catText
            if hypersImg ~= nil then
                -- txt.Label = string.format("Frame: %s", i)
                local currentU0,currentV0,currentU1,currentV1 = getUVsForFrame(i)
                hypersImg.ImageData.UV0 = { currentU0, currentV0}
                hypersImg.ImageData.UV1 = { currentU1, currentV1}
            end
        end)
    
    local fixedTime = 0 -- Ext.Timer to drive the scheduler's internal clock every 1/60 second (0.016)
    -- Ext.Timer.WaitForRealtime(16, function() scheduler:update(.016) fixedTime = fixedTime+.016 end, 16)
    Ext.Timer.WaitForRealtime(30, function() scheduler:Update(.03) fixedTime = fixedTime+.03 end, 30) -- slow down 1/40
end

function Scribe.GenerateSettingsWindow()
    -- FIXME Get NorbInspect ready, this should go in a main Scribe.lua somewhere...
    testInspector = Inspector:GetOrCreate(_C(), LocalPropertyInterface)
    testInspector:MakeGlobal()
    testInspector.Window.Open = false

    Scribe.SettingsWindow = Ext.IMGUI.NewWindow(Ext.Loca.GetTranslatedString("hb23f384926b64c349bd61fd84f23c88c3d4d", "Scribe Settings"))
    Scribe.SettingsWindow.Open = false
    Scribe.SettingsWindow.Closeable = true
    -- settingsWindow.AlwaysAutoResize = true -- TODO need saved settings
    Scribe.SettingsWindow.AlwaysAutoResize = LocalSettings:GetOr(true, Static.Settings.SettingsAutoResize)

    table.insert(Scribe.AllWindows, Scribe.SettingsWindow) -- FIXME
    hypers(Scribe.SettingsWindow)

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
    keybindingsGroup:AddText("Open Watch Window") -- Testing
    keybindWatchWindow = KeybindingManager:CreateAndDisplayKeybind(keybindingsGroup,
        "OpenCloseWatchWindow", "Y", { "Alt"}, openCloseWatchWindow)

    Scribe.SettingsWindow:AddSeparatorText("ImguiThemes")
    ImguiThemeManager:CreateUpdateableDisplay(Scribe.SettingsWindow)

    return Scribe.SettingsWindow
end