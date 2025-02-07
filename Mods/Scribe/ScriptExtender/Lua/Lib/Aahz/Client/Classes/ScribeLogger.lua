--- Main Log window, holds tabs for different log types
--- @class ScribeLogger : ImguiLogger
--- @field Window ExtuiWindow
--- @field MainMenu ExtuiMenu
--- @field MenuFile ExtuiMenu
--- @field MainTabBar ExtuiTabBar
--- @field Ready boolean
ScribeLogger = _Class:Create("ScribeLogger", nil, {
    Ready = false,
})

function ScribeLogger:Init()
    self.Ready = false
    self:CreateWindow()
    self:InitializeLayout()
end
function ScribeLogger:CreateWindow()
    if self.Window ~= nil then return end -- only create once
    self.Window = Ext.IMGUI.NewWindow("Scribe Log")
    self.Window.IDContext = "Scribe_Log"
    self.Window:SetSize({600,550}, "FirstUseEver")
    self.Window.Open = false
    self.Window.Closeable = true
    self.Window.AlwaysAutoResize = true
    
    table.insert(Scribe.AllWindows, self.Window)

    local viewportMinConstraints = {500, 500}
    self.Window:SetStyle("WindowMinSize", viewportMinConstraints[1], viewportMinConstraints[2])
    local viewportMaxConstraints = Ext.IMGUI.GetViewportSize()
    viewportMaxConstraints[1] = math.floor(viewportMaxConstraints[1] / 2) -- 1/3 of width, max?
    viewportMaxConstraints[2] = math.floor(viewportMaxConstraints[2] *0.85) -- 9/10 of height, max?
    self.Window:SetSizeConstraints(viewportMinConstraints,viewportMaxConstraints)

    self.Window.OnClose = function(w)
        if w and w.UserData and w.UserData.Closed then
            w.UserData.Closed(w)
        end
    end

    -- Create MainMenu
    self.MainMenu = self.Window:AddMainMenu()
    self.MenuFile = self.MainMenu:AddMenu(Ext.Loca.GetTranslatedString("File", "File"))
    local openClose = self.MenuFile:AddItem(Ext.Loca.GetTranslatedString("Open/Close", "Open/Close"))
    openClose.OnClick = function(_)
        self.Window.Open = false
    end
end

function ScribeLogger:InitializeLayout()
    if self.Ready then return end -- only initialize once
    self.MainTabBar = self.Window:AddTabBar("Scribe_LoggerTabBar")
    -- self.MainTabBar.AutoSelectNewTabs = true

    self.TabECS = self.MainTabBar:AddTabItem("ECS")
    self.LoggerECS = ImguiECSLogger:New{}
    self.LoggerECS:CreateTab(self.TabECS)

    self.TabServerEvents = self.MainTabBar:AddTabItem("Server Events")
    self.LoggerServerEvents = ImguiServerEventLogger:New{}
    self.LoggerServerEvents:CreateTab(self.TabServerEvents)

    self.Ready = true
end
MainScribeLogger = nil
Ext.Events.SessionLoaded:Subscribe(function()
    MainScribeLogger = ScribeLogger:New()
end)