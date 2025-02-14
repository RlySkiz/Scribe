local U = Utils
local ObjectPath = U.ObjectPath
local GetEntityName = U.GetEntityName

local w = Ext.IMGUI.NewWindow("Mouseover Inspector")

--- @class LocalPropertyInterface
LocalPropertyInterface = {}


Scribe = {}
Scribe.__index = Scribe
---@return Scribe
---@param intf LocalPropertyInterface
function Scribe:New(intf)
	local o = {
		Window = nil,
        LeftContainer = nil,
        RightContainer = nil,
        TargetLabel = nil,
        TreeView = nil,
        PropertiesPane = nil,
        Target = nil,
        PropertyInterface = intf
	}
	setmetatable(o, self)
    self.__index = self
    return o
end

function Scribe:GetOrCreate(entity, intf)
    if self.Instances[entity] ~= nil then
        return self.Instances[entity]
    end

    local i = self:New(intf)
    i:Init(tostring(entity))
    i:UpdateInspectTarget(entity)
    return i
end

function Scribe:Init(instanceId)
    self.Window = Ext.IMGUI.NewWindow("Mouseover Inspector")
    self.Window.IDContext = instanceId
    self.Window:SetSize({500, 500}, "FirstUseEver")
    self.Window.Closeable = true
    local layoutTab = self.Window:AddTable("", 2)
    local layoutRow = layoutTab:AddRow()
    local leftCol = layoutRow:AddCell()
    local rightCol = layoutRow:AddCell()
    self.LeftContainer = leftCol:AddChildWindow("")
    self.RightContainer = rightCol:AddChildWindow("")
    self.TargetLabel = self.LeftContainer:AddText("")
    self.TreeView = self.LeftContainer:AddTree("Hierarchy")
    self.PropertiesPane = self.RightContainer:AddTable("Properties", 2)
    self.PropertiesPane.PositionOffset = {5, 2}
    self.PropertiesPane:AddColumn("Name")
    self.PropertiesPane:AddColumn("Value")

    self.Window.OnClose = function (e)
        self:UpdateInspectTarget(nil)
        self.Window:Destroy()
    end
end

---@param target EntityHandle?
function Scribe:UpdateInspectTarget(target)
    if self.TreeView ~= nil then
        self.LeftContainer:RemoveChild(self.TreeView)
        self.TreeView = nil
    end

    if self.Target ~= nil then
        self.Instances[self.Target] = nil
    end

    if target ~= nil then
        self.Target = target
        self.Instances[self.Target] = self
        self.TreeView = self.LeftContainer:AddTree(GetEntityName(target) or tostring(target))
        self.TreeView.UserData = { Path = ObjectPath:New(target) }
        self.TreeView.OnExpand = function (e) self:ExpandNode(e) end
        self.TreeView.IDContext = Ext.Math.Random()
        self.Window.Label = "Object Inspector - " .. (GetEntityName(target) or tostring(target))
    else
        self.Window.Label = "Object Inspector"
    end
end

Ext.Events.ResetCompleted:Subscribe(function (e)
    --local i = Inspector:New(NetworkPropertyInterface)
    local i = Scribe:New(LocalPropertyInterface)
    i:Init("Root")
    i:MakeGlobal()
    i:UpdateInspectTarget(Ext.Entity.Get("79669055-1acb-86a3-4036-4f729f710707"))
    --i:UpdateInspectTarget("5470029e-1d8e-dbcb-a681-182799239089")
    i:ExpandNode(i.TreeView)
    i.TreeView.DefaultOpen = true
end)


local function createScribeMCMTab(treeParent)
    treeParent:AddDummy(20,1)
    local openButton = treeParent:AddButton(Ext.Loca.GetTranslatedString("h83db5cf7gfce3g475egb16fg37d5f05005e3", "Open/Close"))
    openButton.OnClick = function(b)
        if w.Open == true then
            w.Open = false 
        else
            w.Open = true 
        end
    end
end
Ext.RegisterNetListener("MCM_Server_Send_Configs_To_Client", function(_, payload)
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Scribe", createScribeMCMTab)
end)