--------------------------------------------------------------------------------------
--
--
--                                    Tabs
--
--
---------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------
--                                    Constructor
------------------------------------------------------------------------------------------------


Tab = {}
Tab.__index = Tab


function Tab:new(label, tabbar)
    local instance = self:initialize(label, tabbar)
    return instance
end


--------------------------------------------------------------------------------------------
--                                     Variables
--------------------------------------------------------------------------------------------

--  {tab = tab, table = table, search = search}
local allTabs = {}

--------------------------------------------------------------------------------------------
--                                     Getters and Setters
---------------------------------------------------------------------------------------------

function Tab:getAllTabs()
    return allTabs
end



--@param label string
function Tab:getTab(label)
    for i,entry in pairs(allTabs) do
        if entry.tab.Label == label then
            return entry.tab
        end
    end
end


--@param label string
function Tab:getContentArea(label)
    for i,entry in pairs(allTabs) do
        if entry.tab.Label == label then
            return entry.contentArea
        end
    end
end



--@param label string
function Tab:getSearch(label)
    for i,entry in pairs(allTabs) do
        if entry.tab.Label == label then
            return entry.search
        end
    end
end


function Tab:setTab(tab)
    table.insert(allTabs, tab)
end


--------------------------------------------------------------------------------------------
--                                     Methods
---------------------------------------------------------------------------------------------

-- initialize a tab according to Skiz' preferences and add it to "allTabs"
--@param label  string
--@param tabbar Tabbar
function Tab:initialize(label, tabbar)
    local tab = tabbar:AddTabItem(label)
    tab.Visible = false
    local search -- Placeholder until search gets implemented

    -- local search = tab:AddInputText("")
    -- search.Text = "Search"
    -- local uuid = tab:AddText(label .. "UUID: ")

    -- tab:AddSeparator()

    local contentArea = tab:AddTable("",2)
    -- contentArea.SizingStretchProp = true
    -- contentArea.SizingFixedFit = true
    -- contentArea.ScrollY = true

    -- search.OnChange = function()

    -- end

    table.insert(allTabs, {tab = tab, contentArea = contentArea, search = search})
    return tab
end