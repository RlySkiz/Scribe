--- @class ScalarSetEditor : PropertyEditorDefinition
local ScalarSetEditor = {}

function ScalarSetEditor:Supports(type)
    return type.Kind == "Set"
end

function ScalarSetEditor:Create(holder, path, key, value, typeInfo, setter)
    local propertyPath = path:CreateChild(key)
    for i=1,#value do
        local child
        if type(value) == "table" then
            child = value[i]
        else
            child = Ext.Types.GetHashSetValueAt(value, i)
        end
        local subpropSetter = function (value, vKey, vPath)
            setter(value, vKey or i, vPath or propertyPath)
        end
        self.Factory:CreateEditor(holder, propertyPath, i, child, typeInfo.ElementType, subpropSetter)
    end
end

return ScalarSetEditor
