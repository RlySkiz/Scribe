

-- contains commented out functions and such


--------------------------------------------------------------------------------------
--
--
--                             Handling the IMGUI "Tabs"
--
--
---------------------------------------------------------------------------------------


-- TODO - way too large

--------------------------------------------------------------------------------------------
--                                      VARIABLES
---------------------------------------------------------------------------------------------



-- -- copied tables 
-- -- key : label name
-- -- value: table
-- local copiedTables = {}

-- local savedNodes = {}


-- local initRootRow
-- local initRootCell
-- local initRootTree
-- local savedEntity

-- -- A "Do Once" for InitializeTree
-- local doOnce = 0 



-- Combined map for linking both DATA and IMGUI tables to SlotName
-- Access this like so:
-- helmetDATA = VISUALDATA_TABLE["Helmet"].DATA
-- helmetTable = VISUALDATA_TABLE["Helmet"].IMGUI   -- these have been set in DATA_Window
-- local ScribeMap = {
--     ["Mouseover"] = { DATA = {}, ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
--     ["Entity"] = { DATA = {}, ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
--     ["Visual"] = { DATA = {}, ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
--     ["VisualBank"] = { DATA = {}, ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
--     ["Materials"] = { DATA = {}, ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
--     ["Textures"] = { DATA = {},  ROOTTREE = {}, SERIALIZEDTREE = {}, DUMPTEXT = {}},
-- }


-- ---------------------------------------------------------------------------------------------------
-- --                                           Getters
-- -------------------------------------------------------------------------------------------------

-- -- -- get the Initialized Root Row
-- -- --@return initRootRow userdata
-- -- function ReturnInitRootRow()
-- --     return initRootRow
-- -- end

-- -- -- get the Initialized Root Cell
-- -- --@return initRootCell userdata
-- -- function ReturnInitRootCell()
-- --     return initRootCell
-- -- end

-- -- -- get the Initialized Root Tree
-- -- --@return initRootTree userdata
-- -- function ReturnInitRootTree()
-- --     return initRootTree
-- -- end

-- -- -- get the saved entity
-- -- --@return sacedEntity string - uuid of the entity
-- -- local function getSavedEntity()
-- --     return savedEntity
-- -- end


-- -- -- retrieves the copied table
-- -- --@param label string - label of tabel that should be returned
-- -- --@param dump table   - values
-- -- function GetCopiedTable(label)
-- --     -- Entity dumps are too large, so they have to be retrieved from new everytime
-- --     if label == "Entity" then
-- --         local dump = Ext.Entity.Get(getSavedEntity()):GetAllComponents()
-- --         return dump
-- --     else
-- --         for key, value in pairs(copiedTables) do
-- --             if key == label then
-- --                 return value
-- --             end
-- --         end
-- --     end
-- --     print("[Datahandling.lua] Error: table doesn't exist")
-- --     return nil    
-- -- end

-- -- function GetSavedNodes()
-- --     return savedNodes
-- -- end

-- function GetScribeMap()
--     return ScribeMap
-- end

-- -- Returns the DATA table based on slot name
-- -- @param slot string - allowed string (see ScribeMap keys)
-- -- @return dataTable table or nil if slot does not exist
-- function GetScribeData(tab)
--     local entry = ScribeMap[tab]
--     if entry then
--         return entry.DATA
--     else
--         _P("[DataHandling.lua] - Error - GetScribeData() - ", tab, " is not a valid Tab")
--         return nil
--     end
-- end


-- -- TODO - yeet
-- -- Returns the TABLE table based on slot name
-- -- @param slot string - allowed string (see ScribeMap keys)
-- -- @return imguiTable table or nil if slot does not exist
-- -- function GetScribeTable(tab)
-- --     local entry = ScribeMap[tab]
-- --     if entry then
-- --         return entry.TABLE
-- --     else
-- --         _P("[DataHandling.lua] - Error - GetScribeTable() - ", tab, " is not a valid Tab")
-- --         return nil
-- --     end
-- -- end

-- -- Returns the TABLE table based on slot name
-- -- @param slot string - allowed string (see ScribeMap keys)
-- -- @return imguiTable table or nil if slot does not exist
-- function GetScribeRootTree(tab)
--     local entry = ScribeMap[tab]
--     if entry then
--         return entry.ROOTTREE
--     else
--         _P("[DataHandling.lua] - Error - GetScribeRootTree() - ", tab, " is not a valid Tab")
--         return nil
--     end
-- end

-- -- TODO - do we overwrite this? I need access to the original data for searching
-- -- Returns the TABLE table based on slot name
-- -- @param slot string - allowed string (see ScribeMap keys)
-- -- @return imguiTable table or nil if slot does not exist
-- function GetScribeDumpText(tab)
--     local entry = ScribeMap[tab]
--     if entry then
--         return entry.DUMPTEXT
--     else
--         _P("[DataHandling.lua] - Error - GetScribeDumpText() - ", tab, " is not a valid Tab")
--         return nil
--     end
-- end

-- function GetScribeSerializedTree(tab)
--     local entry = ScribeMap[tab]
--     if entry then
--         return entry.SERIALIZEDTREE
--     else
--         _P("[DataHandling.lua] - Error - GetScribeSerializedTree() - ", tab, " is not a valid Tab")
--         return nil
--     end
-- end

-- -- Adds the data from server to the DATA element
-- -- @param payload table - table containing slot and data 
-- local function setScribeData(payload)
--     _P("[DataHandling.lua] - setScribeData() - Populating table for Tab ", payload.tab)
--     ScribeMap[payload.tab].DATA = payload.data

--     -- _P("[DataHandling.lua] - setDATATable() - DUMP:")
--     -- _D(ScribeMap[payload.slot].DATA)
-- end

-- local function setScribeRootTree(tab, rootTree)
--     ScribeMap[tab].ROOTTREE = rootTree
-- end

-- local function setScribeDumpText(tab, dumpText)
--     ScribeMap[tab].DUMPTEXT = dumpText
-- end

-- local function setScribeSerializedTree(tab, rootTree)

-- end


-- -- local function setTreeChildren(tree)
-- --     _P("[DataHandling.lua] - setSCRIBETREECHILDREN() - Populating table for tree ", tree.Label)
-- --     ScribeMap[tab].CHILDREN = tree.Children
-- -- end

-- ---------------------------------------------------------------------------------------------------
-- --                                       Setters
-- -------------------------------------------------------------------------------------------------

-- -- set the Initialized Root Row
-- --@param row userdata
-- -- local function setInitRootRow(row)
-- --     initRootRow = row
-- -- end

-- -- -- set the Initialized Root Cell
-- -- --@param cell userdata
-- -- local function setInitRootCell(cell)
-- --     initRootCell = cell
-- -- end

-- -- -- set the Initialized Root Tree
-- -- --@param tree userdata
-- -- local function setInitRootTree(tree)
-- --     initRootTree = tree
-- -- end

-- -- -- set the entity
-- -- --@param entityUUID string
-- -- local savedEntity
-- -- local function setSavedEntity(entityUUID)
-- --     savedEntity = entityUUID
-- -- end

-- -- -- sets the copied table (deep copy necessary because of lifetime)
-- -- --@param label string - label of table that should be saved
-- -- --@param dump table   - values
-- -- local function setCopiedTable(label,dump)
-- --     copiedTables[label] = dump
-- -- end


-- ---------------------------------------------------------------------------------------------------
-- --                                      Helper Methods
-- ---------------------------------------------------------------------------------------------------

-- -- Perform a deep copy of a table - necessary when lifetime expires
-- --@param    orig table - orignial table
-- --@return   copy table - copied table
-- -- local copies = 0
-- -- local function DeepCopy(orig)
-- --     _P("Copies til now: ", copies)
-- --     copies = copies+1
-- --     local copy = {}

-- --     success, iterator = pcall(pairs, orig)
-- --     if success == true and (type(orig) == "table" or type(orig) == "userdata") then

-- --         for label, content in pairs(orig) do

-- --             if content then
-- --                  copy[DeepCopy(tostring(label))] = DeepCopy(content)
-- --             else
-- --                 copy[DeepCopy(label)] = "nil"
-- --             end

-- --         end
-- --         if copy and (not #copy == 0) then
-- --             setmetatable(copy, DeepCopy(getmetatable(orig)))
-- --         end
-- --     else
-- --         copy = orig
-- --     end
-- --     return copy
-- -- end

-- local function sortData(data)

--     if type(data) == "table" or type(data) == "userdata" then
--         local array = {}

--         for key, value in pairs(data)do
--         table.insert(array, {key = key, value = value})
--         end

--         table.sort(array, function(a, b)
--             -- Convert keys to numbers for comparison
--             local keyA, keyB = tonumber(a.key), tonumber(b.key)
--             -- If conversion is successful, compare numerically
--             if keyA and keyB then
--                 return keyA < keyB
--             else
--                 -- If conversion fails, compare as strings
--                 return a.key < b.key
--             end
--         end)

--         return array, data
--     else
--         return data, data
--     end
-- end


-- local characterVisual
-- Ext.Events.NetMessage:Subscribe(function(e) 
--     if (e.Channel == "SendCharacterVisualResourceID") then
--         -- _P("SendCharacterVisualResourceID recieved")
--         local characterVisualResourceID = Ext.Json.Parse(e.Payload)
--         -- _P(characterVisualResourceID)
--         local characterVisual = Ext.Resource.Get(characterVisualResourceID, "CharacterVisual")
--         ScribeMap["VisualBank"].DATA = DeepCopy(characterVisual)
--         -- _P("Saved VisualBank")
--         -- _D(ScribeMap["VisualBank"].DATA)
--         InitializeScribeTree("VisualBank")
--     end
-- end)

-- -- returns the DATA from the corresponding dump (sorted)
-- --@param tab string - tab name ex: "Mouseover"
-- --@return     table - unsorted data
-- --@return     table - sorted table
-- local function getData(tab)
--     if tab == "VisualBank" then
--         -- _P("Retrieved VisualBank")
--         -- _D(ScribeMap[tab].DATA)
--     end
--     return ScribeMap[tab].DATA, sortData(ScribeMap[tab].DATA)
    
-- end

-- -- saves the dump data in the corresponding list
-- --@param tab string - tab name ex: "Mouseover"
-- function SaveData(tab)
--     local data

--     if tab == "Mouseover"  then
--         data = GetMouseover()
--         ScribeMap[tab].DATA = DeepCopy(data)
        
--     elseif tab == "Entity" then
--         data = Ext.Entity.Get(getUUIDFromUserdata(GetMouseover())):GetAllComponents()
--         ScribeMap[tab].DATA = data
--     elseif tab == "Visual" then
--         data = Ext.Entity.Get(getUUIDFromUserdata(GetMouseover())).Visual
--         ScribeMap[tab].DATA = data
--     elseif tab == "VisualBank" then
--         local uuid = getUUIDFromUserdata(GetMouseover())
--         -- _P("UUID send for RequestCharacterVisualResourceID", uuid)
--         Ext.Net.PostMessageToServer("RequestCharacterVisualResourceID", Ext.Json.Stringify(uuid))
--         -- gets saved by listener

--     end
-- end

-- ---------------------------------------------------------------------------------------------------
-- --                                      Main Methods
-- ---------------------------------------------------------------------------------------------------


-- -- declared beforehand since they reference each other
-- local PopulateScribeTree
-- local populateScribeTree
-- local addTreeOnClick

-- -- key: tree
-- -- value : bool
-- local treeClicked = {}


-- addTreeOnClick = function(tree, currentTable)
--     tree.OnClick = function()
--         -- Only do the Onclick function once
--         if not treeClicked[tree] then
--             treeClicked[tree] = true

--             local sortedData = sortData(currentTable)
--             PopulateScribeTree(tree, sortedData)
--             --populateScribeTree(tree,currentTable)
--         end
--     end
-- end



-- -- TODO - add a nuch more, so we can get the race, the background etc.
-- -- if the string is a loca, append the translated loca
-- --@param str          string 
-- --@return translation string
-- local function addLoca(str)
--     local translation = str
--     local suffix = Ext.Loca.GetTranslatedString(str)
--     if suffix ~= "" then
--         translation = str .. " - " .. suffix
--     end
--     return translation
-- end

                

-- -- TODO - translate locas
-- -- local materialInstances = {}
-- -- populateScribeTree = function(tree, currentTable)    
-- --     local success, iterator = pcall(pairs, currentTable)
-- --     if success == true and (type(currentTable) == "table" or type(currentTable) == "userdata") then
-- --         for label,content in pairs(currentTable) do
-- --             if content then
-- --                 -- special case for empty table
-- --                 local stringify = Ext.Json.Stringify(content, STRINGIFY_OPTIONS)
-- --                 -- TOD: some nodes have a [] but that contains more data -> send into recursion
-- --                 if stringify == "{}" or stringify == "[]" then
-- --                     local newTree = tree:AddTree(tostring(addLoca(label)))
-- --                     local child = newTree:AddTree(tostring(stringify))
-- --                     child.Bullet = true
-- --                 -- regular case -> recursion    
-- --                 elseif (type(content) == "table") or (type(content) == "userdata") then
-- --                     local newTree = tree:AddTree(tostring(addLoca(label)))
-- --                     local status, result = pcall(Ext.Types.Serialize, content)
-- --                     if not status then
-- --                         result = DeepCopy(content)
-- --                     end
-- --                     addTreeOnClick(newTree, result)
-- --                 -- content is non-table
-- --                 else
-- --                     local newTree = tree:AddTree(tostring(addLoca(label)))
-- --                     addTreeOnClick(newTree, content)
-- --                 end
-- --             -- empty content -> only put label as tree
-- --             else
-- --                 _P("label ", label)
-- --                 _D(label)
-- --                 local newTree = tree:AddTree(tostring(addLoca(label)))
-- --                 newTree.Bullet = true
-- --             end
-- --         end
-- --     -- table is not table but bool, string etc -> recursion ends here
-- --     else
-- --         local newTree
-- --         if Ext.Types.GetObjectType(currentTable) == "Entity" then
-- --             newTree = tree:AddTree(tostring(Ext.Entity.HandleToUuid(currentTable)))
-- --         else
-- --             newTree = tree:AddTree(tostring(addLoca(currentTable)))
-- --         end
-- --         newTree.Bullet = true
-- --     end
-- -- end



-- -- TODO - visual  lacks most content. Visual.Visual is missing
-- PopulateScribeTree = function(tree, sortedTable)

--     -- during the first iteration, for sorting, labels are numbers. They can be discarded


--     local success, iterator = pcall(pairs, sortedTable)
--     if success == true and (type(sortedTable) == "table" or type(sortedTable) == "userdata") then

--         for index, entry in pairs(sortedTable) do 

--             local label = entry.key
--             local content = entry.value

--             if content then

--                 -- special case for empty table
--                 local stringify = Ext.Json.Stringify(content, STRINGIFY_OPTIONS)
--                 -- TODO: some nodes have a [] but that contains more data -> send into recursion
--                 -- maybe check the object type  to determine
--                 if stringify == "{}" or stringify == "[]" then
--                     local newTree = tree:AddTree(tostring(addLoca(label)))
--                     local child = newTree:AddTree(tostring(stringify))
--                     child.Bullet = true
--                 -- regular case -> recursion    
--                 elseif (type(content) == "table") or (type(content) == "userdata") then
--                     local newTree = tree:AddTree(tostring(addLoca(label)))
--                     local status, result = pcall(Ext.Types.Serialize, content)
--                     if not status then
--                         result = DeepCopy(content)
--                     end
--                     addTreeOnClick(newTree, result)
--                 -- content is non-table
--                 else
--                     local newTree = tree:AddTree(tostring(addLoca(label)))
--                     addTreeOnClick(newTree, content)
--                 end

--             else
--                 _P("label ", label)
--                 _D(label)
--                 local newTree = tree:AddTree(tostring(addLoca(label)))
--                 newTree.Bullet = true

--             end
--         end

--     else

--         local newTree
--         if Ext.Types.GetObjectType(sortedTable) == "Entity" then
--             newTree = tree:AddTree(tostring(Ext.Entity.HandleToUuid(sortedTable)))
--         else
--             newTree = tree:AddTree(tostring(addLoca(sortedTable)))
--         end
--         newTree.Bullet = true

--     end
-- end

-- local initializedBefore = false
-- local function updateScribeTree(tab)
--     --- satancomment -- local table = GetScribeTable(tab)
--     local table = Tab:getTable(tab)
--     for i=1, #table.Children do
--         table.Children[i]:Destroy()
--     end
--     ScribeMap[tab].DATA = {}
--     -- _P("Reset Data")
--     initializedBefore = false
--     -- _P("Re-Initializing Tree")
--     InitializeScribeTree(tab)
-- end

-- local previousTab
-- function InitializeScribeTree(tab)
--     if tab ~= previousTab then
--         previousTab = tab
--         initializedBefore = false
--     end
--     _P("Initializing Tab: ", tab)
--     -- _P("initializedBefore = ", initializedBefore)
--     if not (tab == "VisualBank") then
--         SaveData(tab)
--     end
--     -- if tab == "VisualBank" then
--     --     data = ScribeMap[tab].DATA
--     -- end


--     -- local data = GetScribeData(tab)
--     -- _P("InitializedBefore? ", initializedBefore)
--     if initializedBefore == false then
--         -- _P("Not initialized before ", tab)
--         --_D(ScribeMap[tab].DATA) -- exist here
--         --local table = GetScribeTable(tab) -- seizes to exist here
--         local table = Tab:getTable(tab)
--         --_D(table)
        
        
--         -- _P("[DataHandling.lua] - populateScribeTree() - data Dump:") -- DEBUG
--         -- _D(data)
--         -- if tab == "Entity" then
--         --     _P("BEFORE GETALLCOMPONENTS", data)
--         --     _D(data)
--         --     data = Ext.Entity.Get(data[1]):GetAllComponents()
--         --     _P(data)
--         --     _D(data)
--         -- end

--         -- How to access Column Definitions
--         -- table.ColumnDefs[1] = {IndentEnable = true, NoResize = false}

--         local tableRow = table:AddRow()
--         local rootTreeWrapperCell = tableRow:AddCell()
--         local dumpTextWrapperCell = tableRow:AddCell()

--         local rootTreeWrapperTable = rootTreeWrapperCell:AddTable("",1)
--         rootTreeWrapperTable.ScrollX = true
--         rootTreeWrapperTable.ScrollY = true
--         local dumpTextWrapperTable = dumpTextWrapperCell:AddTable("",1)
--         dumpTextWrapperTable.ScrollX = true
--         dumpTextWrapperTable.ScrollY = true
        
--         local rootTreeWrapperRow = rootTreeWrapperTable:AddRow()
--         local dumpTextWrapperRow = dumpTextWrapperTable:AddRow()

--         local rootTreeCell = rootTreeWrapperRow:AddCell()
--         local dumpTextCell = dumpTextWrapperRow:AddCell()
        
--         local rootTree = rootTreeCell:AddTree(tab)

--         local data, array = getData(tab)

--         -- if tab == "VisualBank" then
--         --         _P("------InitializeScribeTree - Tab VisualBank------")
--         --         _P("DATA")
--         --         _D(data)
--         --         _P("ARRAY")
--         --         _D(array)
--         -- end

--         local dumpText = dumpTextCell:AddText(Ext.DumpExport(data))
--         -- local dumpText = dumpTextCell:AddText(Ext.DumpExport(data))

--         setScribeRootTree(tab, rootTree)
--         setScribeDumpText(tab, dumpText)

--         -- during the first iteration, due to sorting, we want to discard the label
--         PopulateScribeTree(rootTree, array)
--             -- _D(data)
--             --_P("Total trees created: ", totalTrees)
--         totalTrees = 1

--         -- for i=1, #rootTree.Children do
--         --     rootTree.Children[i].OnClick = function()
--         --         populateScribeTree(rootTree.Children[i], data)
--         --     end
--         -- end
--         -- _P("InitializedBefore? ", initializedBefore)
--         initializedBefore = true
--         -- _P("InitializedBefore? ", initializedBefore)
--     else
--         -- _P("initializedBefore = ", initializedBefore)
--         -- _P("Updating Tree")
--         updateScribeTree(tab)
--     end
-- end



-- Ext.Events.NetMessage:Subscribe(function(e) 

--     if (e.Channel == "UpdateScribe") then
--         local payload = Ext.Json.Parse(e.Payload)
--             setScribeData(payload)
--             updateScribeTree(payload.tab)
--     end

--     if (e.Channel == "InitializeScribe") then
--         local payload = Ext.Json.Parse(e.Payload)

--             setScribeData(payload)
--             InitializeScribeTree(payload.tab)
--     end
-- end)
    

    
--     local tableToPopulate = table:AddTable("", 4)
--     tableToPopulate.ScrollY = true
--     for i, data in pairs(dataTable) do
--         local uuid = data.uuid
--         local icon = data.icon
--         local name = data.name

--         if cellAmount == 0 or cellAmount == tableToPopulate.Columns then -- create new row if there is none or if cellAmount reaches 6 (5 columns)
--             tableRow = tableToPopulate:AddRow()
--             cellAmount = 0
--         end

--         local tableCell = tableRow:AddCell()
--         tableCell.IDContext = cellAmount
--         cellAmount = cellAmount + 1
--         totalIcons = totalIcons + 1

--         local objInstanceTable = tableCell:AddTable("", 1)
--         objInstanceTable.Borders = true

--         --  Worki
--         -- local objInstanceRow = objInstanceTable:AddRow()
--         -- local objInstanceCell = objInstanceRow:AddCell()
--         -- local objInstanceName = objInstanceCell:AddText(name)

--         -- local objInstanceRow2 = objInstanceTable:AddRow()
--         -- local objInstanceCell2 = objInstanceRow2:AddCell()
--         -- local objInstanceButton = objInstanceCell2:AddButton("Select")

--         -- local objInstanceRow3 = objInstanceTable:AddRow()
--         -- local objInstanceCell3 = objInstanceRow3:AddCell()
--         -- local objInstanceIcon = objInstanceCell3:AddIcon(icon)

--         --  Not Worki - But better lookie
--         local objInstanceRow = objInstanceTable:AddRow()
--         local objInstanceCell = objInstanceRow:AddCell()
--         local objInstanceName = objInstanceCell:AddText(name)
        
--         local objInstanceRow2 = objInstanceTable:AddRow()
--         local objInstanceTableRow2Cell = objInstanceRow2:AddCell()
--         local objInstanceTableInner = objInstanceTableRow2Cell:AddTable("",2)
--         objInstanceTableInner.IDContext = "IconButtonWrapper"

--         local objInstanceTableInnerRow = objInstanceTableInner:AddRow()
--         local objInstanceTableInnerCell = objInstanceTableInnerRow:AddCell()
--         local objInstanceIcon = objInstanceTableInnerCell:AddIcon(icon)
--         local objInstanceTableInnerCell2 = objInstanceTableInnerRow:AddCell()
--         local objInstanceButton = objInstanceTableInnerCell2:AddButton("Select")
        
--         local imguiToPad
--         if slot == "Head" then
--             imguiToPad = CCBody
--             local dummyPadding = imguiToPad:AddDummy(0,5)
--         -- elseif slot == "Private Parts" then
--         --     imguiToPad = 
--         -- elseif slot  == "Piercing" then
--         --     imguiToPad = 
--         elseif slot  == "Hair" then
--             imguiToPad = CCHair
--             local dummyPadding = imguiToPad:AddDummy(0,5)
--         elseif slot  == "Beard" then
--             imguiToPad = CCBeard
--             local dummyPadding = imguiToPad:AddDummy(0,5)
--         elseif slot  == "Horns" then
--             imguiToPad = CCHorns
--             local dummyPadding = imguiToPad:AddDummy(0,5)
--         -- elseif slot  == "Tail" then
--         --     imguiToPad = CCTail
--         --     local dummyPadding = imguiToPad:AddDummy(0,5)
--         -- -- Equipment
--         -- elseif slot  == "Helmet" then
--         --     imguiToPad = 
--         -- elseif slot  == "Cloak" then
--         --     imguiToPad = 
--         -- elseif slot  == "Breast" then
--         --     imguiToPad = 
--         -- elseif slot  == "Gloves" then
--         --     imguiToPad = 
--         -- elseif slot  == "Boots" then
--         --     imguiToPad = 
--         -- elseif slot  == "VanityBody" then
--         --     imguiToPad = 
--         -- elseif slot  == "VanityBoots" then
--         --     imguiToPad = 
--         -- elseif slot  == "Underwear" then
--         --     imguiToPad = 
--         -- elseif slot  == "Amulet" then
--         --     imguiToPad = 
--         end
        
--         objInstanceButton.OnClick = function()
--             _P("[DataHandling.lua] - Button clicked for: ", name, " , with UUID: ", uuid, " clicked!")
--             Ext.Net.PostMessageToServer("RequestEquipmentChange", Ext.Json.Stringify(uuid))
--             _P("[DataHandling.lua] - 'RequestEquipmentChange' Event for item ", uuid, " send to server!")
--         end

--         -- objInstanceIcon.Size = {10,10}
--         -- objInstanceIcon.OnClick = function()
--         --     _P("[EQ_Events.lua] - ", objInstanceIcon, " clicked!")
--         -- end          
--     end

--     -- refreshButton.OnClick = function()
--     --     Ext.Net.PostMessageToServer("RefreshAllData", Ext.Json.Stringify(slot))
--     -- end

--     _P("[DataHandling.lua] - populateImGuiTable(", slot, ") executed!")
--     _P("[DataHandling.lua] - Total Icons created: ", totalIcons)
--     entryAmount.Label = "Loaded: " .. tostring(totalIcons) .. " items."
-- end


-- prints the labels
-- temporary function, can be deleted
-- local function printLabel(tree)
--     success, iterator = pcall(pairs, tree)
--     if success == true and (type(tree) == "table" or type(tree) == "userdata") then
--         for x,y in pairs(tree) do
--             if x == "Label" then
--                 print(y)
--             end
--             printLabel(y)
--         end
--     end
-- end


-- initializes a tab with all components as trees and subtrees
--@param tab TabItem   - name of the tab that the components will be displayed under
-- function InitializeTree(tab)



--     if ReturnInitRootTree() == nil then
--         _P("rootTree = nil")

--         local dump = getAndSaveDump(tab.Label)
--         local rowToPopulate = getRowToPopulate(tab.Label)

--         -- Get row, then create cell/tree and populate it
--         local rootRow = rowToPopulate
--         local rootCell = rootRow:AddCell()
--         local rootTree = rootCell:AddTree(tab.Label)
--         rootTree.IDContext = tab.Label .. "RootTree"

--         setInitRootRow(rootRow)
--         setInitRootCell(rootCell)
--         setInitRootTree(rootTree)

--         PopulateTree(rootTree, dump)

--         if doOnce == 0 then
--             -- Create dump info sidebar
--             mouseoverDumpInfo = MouseoverTableRow:AddCell():AddText("Pre-Populate")
--             entityDumpInfo = EntityTableRow:AddCell():AddText("Select Component of your choice \nto populate this field with its actual code.")
--             doOnce = doOnce+1
--         end

--         if tab.Label == "Mouseover" then
--             mouseoverDumpInfo.Label = Ext.DumpExport(GetMouseover())
--         elseif tab.Label == "Entity" then
--             entityDumpInfo.Label = Ext.DumpExport(Ext.Entity.Get(getUUIDFromUserdata(GetMouseover())):GetAllComponents())
--         end

--     else
--         local updatedTable = getAndSaveDump(tab.Label)
--         RefreshTree(tab, updatedTable)
--     end
-- end