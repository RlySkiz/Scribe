
local firstTimeWindow = Imgui.CreateCommonWindow("Scribe: First-time Use Agreement", {
    Size = {500, 500},
    AlwaysAutoResize = true,
})

firstTimeWindow.NoCollapse = true
local p = Ext.IMGUI.GetViewportSize()
p = {p[1]/2-250, (p[2]/2) - 250}
firstTimeWindow:SetPos(p, "Always")

Imgui.CreateMiddleAlign(firstTimeWindow, 350, function(el)
    local txt = el:AddText([[
I agree that Scribe is meant to be a developer's tool, and is not meant for the average player or fixing game saves.

I acknowledge my usage of this tool is at my own risk.
]])
    txt.TextWrapPos = 360
    local chk = el:AddCheckbox("I Agree", false)
    el:AddDummy(80, 1)
    local closeButton = el:AddButton("Thanks, let's get going.")
    closeButton.Visible = false
    chk.OnChange = function()
        closeButton.Visible = chk.Checked
    end
    closeButton.OnClick = function()
        FirstTime:OnNext(chk.Checked)
        LocalSettings:AddOrChange(Static.Settings.FirstTimeAgreed, true)
        firstTimeWindow:Destroy()
    end
    firstTimeWindow.OnClose = function()
        if chk.Checked then
            closeButton:OnClick()
        end
    end
end)
return firstTimeWindow