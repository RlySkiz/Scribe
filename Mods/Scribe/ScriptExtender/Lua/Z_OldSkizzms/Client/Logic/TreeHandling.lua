--------------------------------------------------------------------------------------
--
--
--                 Handling IMGUI Trees and Custom Node Trees
--
--
---------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------
--                                          Methods
---------------------------------------------------------------------------------------



-- finds a value based on the key in a tree
-- @param tree table - the tree to be searched
-- @param searchTerm any - the value to be searched
-- @return value any - the value that matches the search term
-- local function find(child, searchTerm, tree)
--     success, iterator = pcall(pairs, tree)
--     if success == true and (type(tree) == "table" or type(tree) == "userdata") then
--         for label, content in pairs(tree) do
--             --_P("Checking if ", label, " == ", searchTerm)
--             if label == searchTerm then
--                 _P(" Found content is ", content)
--                 PopulateTree(child,content)
--                 return content
--             else
--                 local result = find(searchTerm, content)
--             end
--         end
--     else
--         if tree == searchTerm then
--             return tree
--         end
--     end
-- end

-- Adds the OnClick function that populates all direct descendandts of a tree
--@param treeRoot tree - parent
-- function populateChildrenOnClick(treeRoot)

--     local dump
--     if treeRoot.IDContext == "MouseoverRootTree" then
--         dump = GetCopiedTable(treeRoot.Label)
--     elseif treeRoot.IDContext == "EntityRootTree" then
--         dump = GetCopiedTable(treeRoot.Label)
--     elseif treeRoot.IDContext == "VisualRootTree" then
--         dump = GetCopiedTable(treeRoot.Label)
--     end


--     for i=1, #treeRoot.Children do
        
--         local child = treeRoot.Children[i]
--         local childLabel = child.Label

        
        
--         -- if child label matches any label of the dump then 
--             -- populate child with corresponding mouseOverContent
            
--         child.OnClick = function()

--             mouseoverContent = find(child, childLabel, dump)
--             populateChildrenOnClick(child)
--             _P("mouseoverContent: " , mouseoverContent)
    
--             _P("Done with iteration ", i)
--         end
--     end
-- end




-- local ID = 0
-- Populate a tree
--@param tree userdata/Tree      - tree that the children will be added to
--@param currentTable table      - table with the label, content pairs
-- function PopulateTree(tree, currentTable)

--     success, iterator = pcall(pairs, currentTable)
--     if success == true and (type(currentTable) == "table" or type(currentTable) == "userdata") then
--         for label,content in pairs(currentTable) do
--             if content then
--                 -- special case for empty table
--                 local stringify = Ext.Json.Stringify(content, STRINGIFY_OPTIONS)
--                 if stringify == "{}" then
--                     local newTree = tree:AddTree(tostring(label))
--                     newTree.Bullet = true
--                 else
--                     local newTree = tree:AddTree(tostring(label))
--                 end
--             else
--                 local newTree = tree:AddTree(tostring(label))
--                 newTree.Bullet = true
--             end

--         end
--     else
--         local newTree = tree:AddTree(tostring(currentTable))
--         newTree.Bullet = true

--     end
--     -- Add OnClickFunctionality
--     --populateChildrenOnClick(tree)
-- end



-- Recursive function - not used anymore because of memory usage

-- Populate a tree
--@param tree userdata/Tree      - tree that the children will be added to
--@param currentTable table      - table with the label, content pairs
--@param recursive bool          - whether to populate recursively or not (used for large data)
-- function PopulateTree(tree, currentTable, recursive)

--     success, iterator = pcall(pairs, currentTable
--     if success == true and (type(currentTable) == "table" or type(currentTable) == "userdata") then
--         for label,content in pairs(currentTable) do
--                 if content then

--                     -- special case for empty table
--                     local stringify = Ext.Json.Stringify(content, STRINGIFY_OPTIONS)
--                     if stringify == "{}" then
--                         local newTree = tree:AddTree(tostring(label))
--                         if recursive then
--                             PopulateTree(newTree, "{}")
--                         end
--                     else
                
--                         local newTree = tree:AddTree(tostring(label))
--                         if recursive then
--                             PopulateTree(newTree, content)
--                         end
--                     end
--                 else
--                     local newTree = tree:AddTree(tostring(label))
--                     newTree.Bullet = true
--                 end
--         end
--     else
--         local newTree = tree:AddTree(tostring(currentTable))
--         newTree.Bullet = true
--     end
-- end




-- refreshes tab if a search term is searched
--@param tab TabItem         - name of the tab that the components will be displayed under
--@param updatedTable table - the new information
-- function RefreshTree(tab, updatedTable)
--     local rootTree = getRootTree(tab)
--     local rootCell = getRootCell(tab)
--     rootCell:RemoveChild(rootTree.Handle)
--     local newRootTree = rootCell:AddTree(tab.Label)
--     newRootTree.IDContext = tab.Label .. "RootTree"
--     PopulateTree(newRootTree, updatedTable)

--     if tab.Label == "Entity" then
--         setSavedEntityTree(newRootTree)
--         local entityTree = getSavedEntityTree()
--     end
--     if tab.Label == "Mouseover" then
--         mouseoverDumpInfo.Label = Ext.DumpExport(GetMouseover())
--     elseif tab.Label == "Entity" then
--         entityDumpInfo.Label = Ext.DumpExport(Ext.Entity.Get(getUUIDFromUserdata(getSavedEntity())):GetAllComponents())
--     end

--     -- local rowToPopulate = getRowToPopulate(tab.Label)

--     -- -- Get initial root for deletion of previous dump
--     -- local initRootRow = ReturnInitRootRow()
--     -- local initRootCell = ReturnInitRootCell()
--     -- local initRootTree = ReturnInitRootTree()

--     -- -- Destroy previous dump if it exist

--     -- -- Remove leftover tree
--     -- initRootCell:RemoveChild(initRootTree.Handle)
--     -- -- Create new tree
--     -- local rootTree = initRootCell:AddTree(tab.Label)
--     -- setInitRootTree(rootTree)

--     -- PopulateTree(rootTree, updatedTable)

--     -- if tab.Label == "Entity" then
--     --     setSavedEntityTree(rootTree)
--     --     local entityTree = getSavedEntityTree()
--     -- end

--     -- --initRootCell:RemoveChild(initRootTree.Handle)

--     -- -- Create new tree
--     -- local rootTree = initRootCell[2]:AddTree(tab.Label)
--     -- setInitRootTree(rootTree)
--     -- PopulateTree(rootTree, updatedTable)


--     -- if tab.Label == "Mouseover" then
--     --     mouseoverDumpInfo.Label = Ext.DumpExport(GetMouseover())
--     -- elseif tab.Label == "Entity" then
--     --     entityDumpInfo.Label = Ext.DumpExport(Ext.Entity.Get(getUUIDFromUserdata(getSavedEntity())):GetAllComponents())
--     -- end
    
-- end

-- function UpdateChild(child, updatedTable)

-- end