local H = Ext.Require("Lib/Norbyte/Helpers.lua")

--- @class EntityEditor : PropertyEditorDefinition
local EntityEditor = {
    OnEntityClick = nil
}

function EntityEditor:Supports(type)
    return type.TypeName == "EntityHandle" or type.TypeName == "EntityRef"
end

function EntityEditor:Create(holder, path, key, value, type, setter, onEntityClick)
    local name
    if value == nil then
        name = "(No entity)"
    else
        name = H.GetEntityName(value) or tostring(value)
    end

    local inspectBtn = holder:AddButton(name)
    inspectBtn.ItemWidth = -5
    inspectBtn.UserData = { Target = value }
    inspectBtn.IDContext = tostring(value)
    self.OnEntityClick = onEntityClick
    inspectBtn.OnClick = function (btn)
        if btn.UserData.Target ~= nil then
            if self.OnEntityClick then
                self.OnEntityClick(btn.UserData.Target)
            end
        end
    end
end

return EntityEditor
