--- @class ScalarSetEditor : PropertyEditorDefinition
local ScalarSetEditor = {}

function ScalarSetEditor:Supports(type)
    return type.Kind == "Set"
end

function ScalarSetEditor:Create(holder, path, key, value, type, setter)
    local propertyPath = path:CreateChild(key)
    for i=1,#value do
        local child = Ext.Types.GetHashSetValueAt(value, i)
        local subpropSetter = function (value, vKey, vPath)
            setter(value, vKey or i, vPath or propertyPath)
        end
        self.Factory:CreateEditor(holder, propertyPath, i, child, type.ElementType, subpropSetter)
    end
end

return ScalarSetEditor
