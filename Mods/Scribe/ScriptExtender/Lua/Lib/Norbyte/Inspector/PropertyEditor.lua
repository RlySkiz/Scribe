local builtins = {
    require("Lib.Norbyte.Inspector.Editors.Bitfield"),
    require("Lib.Norbyte.Inspector.Editors.Boolean"),
    require("Lib.Norbyte.Inspector.Editors.Entity"),
    require("Lib.Norbyte.Inspector.Editors.Enum"),
    require("Lib.Norbyte.Inspector.Editors.Float"),
    require("Lib.Norbyte.Inspector.Editors.Integer"),
    require("Lib.Norbyte.Inspector.Editors.Nullable"),
    require("Lib.Norbyte.Inspector.Editors.ScalarArray"),
    require("Lib.Norbyte.Inspector.Editors.ScalarSet"),
    require("Lib.Norbyte.Inspector.Editors.Text"),
    require("Lib.Norbyte.Inspector.Editors.Vec3"),
    require("Lib.Norbyte.Inspector.Editors.Vec4")
}

--- @class PropertyEditorDefinition
--- @field Factory PropertyEditorFactory
--- @field Supports fun(self: PropertyEditorDefinition, type: TypeInformationRef): boolean
--- @field Create fun(self: PropertyEditorDefinition, holder: ExtuiTreeParent, path: ObjectPath, key: any, value: any, type: TypeInformationRef, setter: fun(value: any), onEntityClick: fun(path:ObjectPath)): ExtuiRenderable
PropertyEditorDefinition = {}


--- @class PropertyEditorFactory
--- @field Editors PropertyEditorDefinition[]
PropertyEditorFactory = {
    Editors = {}
}

for i,editor in ipairs(builtins) do
    -- TODO proper registration etc. later
    editor.Factory = PropertyEditorFactory
    PropertyEditorFactory.Editors[i] = editor
end

function PropertyEditorFactory:CreateEditor(holder, path, key, value, type, setter, onEntityClick)
    for n,editor in pairs(self.Editors) do
        if editor:Supports(type) then
            return editor:Create(holder, path, key, value, type, setter, onEntityClick) --[[@as ExtuiStyledRenderable]]
        end
    end

    print("UNSUPPORTED: " .. tostring(type.Kind) .. " - " .. type.TypeName)
    print(value)
    return holder:AddText(tostring(value))
end

return PropertyEditorFactory
