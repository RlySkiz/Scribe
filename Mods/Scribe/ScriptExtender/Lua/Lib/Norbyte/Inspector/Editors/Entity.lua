local H = Ext.Require("Lib/Norbyte/Helpers.lua")

--- @class EntityEditor : PropertyEditorDefinition
local EntityEditor = {
}

function EntityEditor:Supports(type)
    return type.TypeName == "EntityHandle" or type.TypeName == "EntityRef"
end

function EntityEditor:Create(holder, path, key, value, type, setter)
    local name
    if value == nil then
        name = "(No entity)"
    else
        name = H.GetEntityName(value) or tostring(value)
    end

    local inspectBtn = holder:AddButton(name) --[[@as ExtuiButton]]
    inspectBtn.ItemWidth = -5
    inspectBtn.UserData = { Target = value }
    inspectBtn.IDContext = tostring(value)
    inspectBtn.OnClick = function (btn)
        if btn.UserData.Target ~= nil then
            local i = Scribe:GetOrCreateInspector(value, LocalPropertyInterface)
            i.Window.Open = true
            i.Window.Visible = true
            i:ExpandNode(i.TreeView)
            i.TreeView.DefaultOpen = true
            i.Window:SetFocus()
        end
    end
    if value == path.Root or value == "**RECURSION**" then
        inspectBtn.Disabled = true
        inspectBtn:Tooltip():AddText("\t".."Recursion: Disabled")
    end
end

return EntityEditor
