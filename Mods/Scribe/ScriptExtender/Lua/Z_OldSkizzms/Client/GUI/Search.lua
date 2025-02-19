--------------------------------------------------------------------------------------
--
--
--                                    Search
--
--
---------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------
--                                    Constructor
------------------------------------------------------------------------------------------------


Search = {}
Search.__index = Search


function Search:new()
    local instance = setmetatable({}, Search)
    return instance
end


--------------------------------------------------------------------------------------------
--                                     Variables
---------------------------------------------------------------------------------------------

-- TODO - make sure this gets reset correctly

-- key: label
-- value: sortedTable
-- local sortedTables = {}

--------------------------------------------------------------------------------------------
--                                     Getters
---------------------------------------------------------------------------------------------

-- function Search:GetSortedTables()
--     return sortedTables
-- end


-- function Search:GetSortedTable(tabLabel)
--     return sortedTables[tabLabel]
-- end

--------------------------------------------------------------------------------------------
--                                     Setters
---------------------------------------------------------------------------------------------

-- function Search:SetSortedTable(tabLabel, sortedTable)
--     sortedTables[tabLabel] == sortedTable
-- end

--------------------------------------------------------------------------------------------
--                                     Methods
---------------------------------------------------------------------------------------------


-- hides all children
function Search:HideAllChildren(tab)
    local tree = GetScribeRootTree(tab.Label)
    for i=1, #tree.Children do
        tree.Children[i].Visible = false
    end      
end


-- unhides all children that are part of the filteredTable
-- function Search:UnhideFilteredChildren(tab, sortedTable)
--     local tree = GetScribeRootTree(tab.Label)
--     for i=1 in #tree.Children do
--         for _, entry in pairs(sortedTable) do
--             if entry.label == tree.Children[i].Label then
--                 tree.Children[i].Visible = true
--             end
--         end
--     end
-- end


-- todo - belongs in utils
function ForAllChildren(root, fun, param)
    -- end reached
    if #root.Children == 0 then
       -- _D(param)
        fun(root, param)
    else
        for i=1, #root.Children do
            ForAllChildren(root.Children[i], fun)
        end    
    end  
end



function UnhideFilteredChild(child, subTable)

    local success, iterator = pcall(pairs, subTable)
    if success == true and (type(subTable) == "table" or type(subTable) == "userdata") then

        for _, entry in pairs(subTable) do

            -- always check label since it will vanish during the recursion
            if entry.label == child.Label then
              --  _P("match")
                child.Visible = true


            -- end reached
            elseif entry.content == null then
               -- _P("content is nil")
                if entry.label == child.Label then
                    child.Visible = true
                end
            else
               -- _P("No match ", entry.label, " ", child.Label)
                UnhideFilteredChild(child, entry.content)
            end
        end

    else
       -- _P("not a table")
        if subTable == child.Label then
            child.Visible = true
        end
    end
end

----------------------------------

-- Helper function to recursively unhide filtered children
-- local function UnhideChildrenRecursive(node, sortedTable)
--     for i = 1, #node.Children do
--         local child = node.Children[i]

--         -- Check if the child should be visible
--         for _, entry in pairs(sortedTable) do
--             if entry.label == child.Label then
--                 child.Visible = true
--                 --break
--             end
--         end

--         -- Recursively call the function for the child's children
--         UnhideChildrenRecursive(child, sortedTable)
--     end
-- end

-- Unhides all children that are part of the sortedTable
-- function Search:UnhideFilteredChildren(tab, sortedTable)
--     local tree = GetScribeRootTree(tab.Label)
    
--     -- Start the recursive unhiding process from the root node
--     UnhideChildrenRecursive(tree, sortedTable)
-- end


----------------------------------


function Search:AddSearchFunctionalityToAllTabs()

    for i,tab in pairs(Tab:getAllTabs()) do
        tab.search.OnChange = function()
            local originalTable = GetScribeDumpText(tab.tab.Label)
            _P("Search Term " , tab.search.Text)
            local sortedTable = Sorting:filter(tab.search.Text, originalTable)
            --_D(sortedTable)
            Search:HideAllChildren(tab.tab)
            ForAllChildren(GetScribeRootTree(tab.tab.Label), UnhideFilteredChild, sortedTable)
            --Search:UnhideFilteredChildren(entry.tab, sortedTable)
        --updateScribeTree(entry.tab.Label, sortedTable) 
        
        end
    end
end



