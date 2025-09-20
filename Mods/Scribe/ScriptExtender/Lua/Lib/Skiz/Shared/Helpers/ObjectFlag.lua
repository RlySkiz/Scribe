---@class ObjectFlag: MetaClass
---@field ServerCharacterFlags table<string, integer>
---@field ServerCharacterFlags2 table<string, integer>
---@field ServerCharacterFlags3 table<string, integer>
---@field ServerItemFlags table<string, integer>
---@field ServerItemFlags2 table<string, integer>
---@field SceneryFlags table<string, integer>
---@field Is fun(self, name:string):string?, string?
local ObjectFlag = _Class:Create("ObjectFlag", nil, {
})

---@param name string
---@return string?, string?
function ObjectFlag:Is(name)
    for flagType in pairs(self.LookUp) do
        if self.LookUp[flagType][name] then
            return tostring(name),tostring(flagType)
        end
    end
    return nil, nil
end

ObjectFlag.LookUp = {
    ["ServerCharacterFlags"] = Ext.Enums.ServerCharacterFlags,
    ["ServerCharacterFlags2"] = Ext.Enums.ServerCharacterFlags2,
    ["ServerCharacterFlags3"] = Ext.Enums.ServerCharacterFlags3,
    ["ServerItemFlags"] = Ext.Enums.ServerItemFlags,
    ["ServerItemFlags2"] = Ext.Enums.ServerItemFlags2,
    ["SceneryFlags"] = Ext.Enums.SceneryFlags
}

return ObjectFlag