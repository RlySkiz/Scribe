
local GetEntityName = Helpers.GetEntityName
local PropertyListView = require("Lib.Norbyte.Inspector.PropertyListView")

-- FIXME Need to settle on global Scribe somewhere and annotate :concernedsip:
--- @class Scribe
--- @field Window ExtuiWindow
--- @field LeftContainer ExtuiChildWindow
--- @field RightContainer ExtuiChildWindow
--- @field TargetLabel ExtuiText
--- @field TreeView ExtuiTree
--- @field PropertiesView PropertyListView
--- @field Target EntityHandle?
--- @field PropertyInterface LocalPropertyInterface|NetworkPropertyInterface
--- @field IsGlobal boolean
--- @field WindowName string
--- @field Inspectors table<EntityHandle,Inspector>
Scribe = Scribe or {}
Scribe.__index = Scribe
Scribe.AllWindows = Scribe.AllWindows or {}
Scribe.WindowName = "Scribe"
Scribe.Inspectors = {}

-- Load and Ready-up the FirstTime agreement window
Scribe.FirstTimeWindow = require("Client.FirstTimeWindow")
FirstTime:Subscribe(function(v)
    if v then Scribe.FirstTimeWindow = nil end
end)

function Scribe:OpenClose()
    if self.FirstTimeWindow then
        self.FirstTimeWindow.Open = not self.FirstTimeWindow.Open
    else
        self.Window.Open = not self.Window.Open
    end
end

function Scribe:Initialize()
    self.Window = self.Window or Imgui.CreateCommonWindow(self.WindowName, {
        IDContext = "MainScribe",
    })
    self:ChangeInterface(LocalPropertyInterface)
    self:CreateMenus()

    local layoutTab = self.Window:AddTable("", 2)
    layoutTab:AddColumn("InspectorTreeView", "WidthStretch", 14) -- proportional
    layoutTab:AddColumn("InspectorPropertyView", "WidthStretch", 20) -- proportional
    local layoutRow = layoutTab:AddRow()
    local leftCol = layoutRow:AddCell()
    local rightCol = layoutRow:AddCell()
    self.LeftContainer = leftCol:AddChildWindow("")
    self.RightContainer = rightCol:AddChildWindow("")
    -- Hover targets
    self.TargetGroup = self.LeftContainer:AddGroup("TargetGroup")
    self.TargetHoverLabel = self.TargetGroup:AddText("Hovered: ")
    self.TargetLabel = self.TargetGroup:AddText("")
    self.TargetLabel.SameLine = true
    self.TargetGroup.Visible = false
    -- Mouse subscriptions to update scribe target
    self:SetupMouseSubscriptions()

    self.EntityCardContainer = self.LeftContainer:AddGroup("")
    self.TreeView = self.LeftContainer:AddTree("Hierarchy")
    self.PropertiesView = PropertyListView:New(self.PropertyInterface, self.RightContainer)

    self.Window.OnClose = function (e)
        -- self:UpdateInspectTarget(nil)
    end

    Scribe.SettingsWindow = Scribe.GenerateSettingsWindow()
    Scribe:UpdateInspectTarget(_C() --[[@as EntityHandle]])

    Scribe.ScribeLogger = ScribeLogger:New()

    -- Ready up
    -- RPrint("Readying up...")
    ScribeReady:OnNext(true)
end
function Scribe:CreateMenus()
    -- Create main menu
    local windowMainMenu = self.Window:AddMainMenu()
    local fileMenu = windowMainMenu:AddMenu(Ext.Loca.GetTranslatedString("h6d62ce733f1349ed8ca2d41e743dd9af2656", "File"))
    local settingsMenu = fileMenu:AddItem(Ext.Loca.GetTranslatedString("hca001b2e6e7a49e9b152735a3a799083281g", "Settings"))
    local openCloseLogger = fileMenu:AddItem(Ext.Loca.GetTranslatedString("h0a751a9f868d4b378b2e2616dca4672f4120", "Open/Close Logger"))

    -- Add Debug Reset button to right/end of menubar
    if Ext.Debug.IsDeveloperMode() then
        -- Right align button :deadge:
        Imgui.CreateRightAlign(windowMainMenu, 75, function(c)
            local resetButton = c:AddButton(Ext.Loca.GetTranslatedString("hc491ab897f074d7b9d7b147ce12b92fa32g5", "Reset"))
            resetButton:Tooltip():AddText("\t\t"..Ext.Loca.GetTranslatedString("hec0ec5eaf174476886e2b4487f7e4a50e5b5", "Performs an Ext.Debug.Reset() (like resetting in the console)"))
            resetButton.OnClick = function() Ext.Debug.Reset() end
        end)
    end
    openCloseLogger.OnClick = function()
        if self.ScribeLogger == nil then return end
        self.ScribeLogger.Window.Open = not self.ScribeLogger.Window.Open
    end
    settingsMenu.OnClick = function ()
        if Scribe and Scribe.SettingsWindow ~= nil then
            Scribe.SettingsWindow.Open = not Scribe.SettingsWindow.Open
        end
    end
end

-- Insert Scribe into MCM when MCM is ready
Ext.RegisterNetListener("MCM_Server_Send_Configs_To_Client", function(_, payload)
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Scribe", function(treeParent)
        treeParent:AddDummy(20,1)
        local openButton = treeParent:AddButton(Ext.Loca.GetTranslatedString("h9727f426570b4fe39ae10934eb6510996b0d", "Open/Close Scribe"))
        openButton.OnClick = function()
            Scribe:OpenClose()
        end

        local descriptionText = openButton:Tooltip():AddText(Ext.Loca.GetTranslatedString("ha726ac21329648d38f68321f51209253g4g7",
        [[
Open a window and inspect an entity via middle mouse click.
Only works while the window is open.
Check the small "!" buttons to look up additional information about resources.
Component names are clickable to be put on a watchlist.
Themes and an Event Logger can be found in the menu bar.
]]))
    end)
end)


---@param intf LocalPropertyInterface|NetworkPropertyInterface
function Scribe:ChangeInterface(intf)
    -- Do other stuff for networking possibly?
    self.PropertyInterface = intf
end

function Scribe:GetOrCreateInspector(entity, intf, o)
    if self.Inspectors[entity] ~= nil then
        return self.Inspectors[entity]
    end

    local i = Inspector:New(intf, o)
    i:Init(tostring(entity))
    i:UpdateInspectTarget(entity)
    ImguiThemeManager:Apply(i.Window)
    return i
end

function Scribe:SetupMouseSubscriptions()
    Ext.Events.Tick:Subscribe(function ()
        local picker = Ext.UI.GetPickingHelper(1)
        if picker == nil then return end

        local target = picker.Inner.Inner[1].GameObject
        local name = ""

        if target ~= nil then
            name = GetEntityName(target) or "Unnamed Entity"
        end

        self.TargetLabel.Label = name
    end)

    Ext.Events.MouseButtonInput:Subscribe(function (e)
        if e.Button == 2 and e.Pressed then
            local picker = Ext.UI.GetPickingHelper(1)
            local target = picker.Inner.Inner[1].GameObject
            self:UpdateInspectTarget(target)
        end
    end)
end

Scribe.AddExpandedChild = Inspector.AddExpandedChild
Scribe.ExpandNode = Inspector.ExpandNode
Scribe.ViewNodeProperties = Inspector.ViewNodeProperties

---@param target EntityHandle|string?
function Scribe:UpdateInspectTarget(target)
    if self.EntityCardContainer ~= nil then
        Imgui.ClearChildren(self.EntityCardContainer)
    end
    if self.TreeView ~= nil then
        self.LeftContainer:RemoveChild(self.TreeView)
        self.TreeView = nil
    end

    local targetEntity = target --[[@as EntityHandle]]
    if type(target) == "string" then
        targetEntity = Ext.Entity.Get(target)
    end

    if self.Target ~= nil then
        self.Inspectors[self.Target] = nil
    end

    local entityName
    if targetEntity ~= nil then
        self.Target = targetEntity
        self.TargetId = target
        self:GenerateEntityCard(targetEntity)
        self.TreeView = self.LeftContainer:AddTree(GetEntityName(targetEntity) or tostring(targetEntity))
        self.TreeView.UserData = { Path = ObjectPath:New(target) }
        self.TreeView.OnExpand = function (e) self:ExpandNode(e) end
        self.TreeView.IDContext = Ext.Math.Random()
        entityName = (GetEntityName(targetEntity) or tostring(targetEntity))
    end
    self.Window.Label = self.WindowName..(entityName and string.format(" (%s)", entityName) or "")
end

---Generates an entity card for the left-top Scribe container
---@param entity EntityHandle
function Scribe:GenerateEntityCard(entity)
    local c = self.EntityCardContainer
    c:AddSeparatorText("Entity Info:")
    local dumpButton = c:AddButton("Dump")
    c:AddText(string.format("Name: %s", GetEntityName(entity) or "Unknown")).SameLine = true
    dumpButton.OnClick = function()
        Helpers.Dump(entity)
    end

    c:AddText("Uuid:")
    local uuidText = c:AddInputText("", entity.Uuid and entity.Uuid.EntityUuid or "None")
    uuidText.SizeHint = {-1, 32}
    uuidText.SameLine = true
    uuidText.ReadOnly = true
    if entity.GameObjectVisual then
        if entity.GameObjectVisual.Icon and not entity.ClientCharacter and not entity.ServerCharacter then
            -- Sends a console warning if it can't find icon, and no portraits, boo.
            c:AddImage(entity.GameObjectVisual.Icon, {64, 64}):Tooltip():AddText("\t\t"..tostring(entity.GameObjectVisual.Icon))
        end
    end
    if entity.GameObjectVisual then
        c:AddText("RootTemplateId:")
        local templateUuidText = c:AddInputText("", entity.GameObjectVisual and entity.GameObjectVisual.RootTemplateId or "None")
        templateUuidText.SizeHint = {-1, 32}
        templateUuidText.SameLine = true
        templateUuidText.ReadOnly = true
    end
    local raceResource = entity.Race and Ext.StaticData.Get(entity.Race.Race, "Race") --[[@as ResourceRace]]
    if raceResource then
        c:AddText(string.format("Race: %s", raceResource.DisplayName:Get()))
    end
    -- TODO Maybe: Tag component, Transform, UserReservedFor, marker components
    c:AddSeparatorText("Entity Hierarchy:")
end

Scribe:Initialize()