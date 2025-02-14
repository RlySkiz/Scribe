--------------------------------------------------------------------------------------
--
--
--                                      Main Class
--                                 Interaction Handling
--
---------------------------------------------------------------------------------------

-- FIXME Need to settle on global Scribe somewhere and annotate :concernedsip:
Scribe = Scribe or {}
Scribe.__index = Scribe
Scribe.AllWindows = Scribe.AllWindows or {}
Scribe.ImguiTheme = DefaultImguiTheme

Scribe.Window = Imgui.CreateCommonWindow("Scribe")
Scribe.MainInspector = Inspector:GetOrCreate(_C(), LocalPropertyInterface, {
    Window = Scribe.Window,
    WindowName = "Scribe",
    IsGlobal = true,
})
Scribe.MainInspector:MakeGlobal()

local function initializeScribe(scribeWin)
    -- Create main menu
    local windowMainMenu = scribeWin:AddMainMenu()
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

    -- FIXME Initialize Settings window...?
    Scribe.SettingsWindow = Scribe.GenerateSettingsWindow()
    openCloseLogger.OnClick = function()
        if MainScribeLogger == nil then return end
        MainScribeLogger.Window.Open = not MainScribeLogger.Window.Open
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
        local openButton = treeParent:AddButton(Ext.Loca.GetTranslatedString("h83db5cf7gfce3g475egb16fg37d5f05005e3", "Open/Close"))
        openButton.OnClick = function()
            Scribe.Window.Open = not Scribe.Window.Open
        end
    end)
end)

initializeScribe(Scribe.Window)