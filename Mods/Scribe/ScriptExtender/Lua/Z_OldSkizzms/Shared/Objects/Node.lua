-- Not loaded
-- TODO - remove IDContext and bullet


Node = {}
Node.__index = Node



--------------------------------------------------------------------------------
--                                      Constructor
--------------------------------------------------------------------------------

---@param name string
---@param parent node
---@param children list
---@param IDContext string
---@param bullet boolean
function Node:new(name, parent, children, IDContext, bullet)
    local instance = setmetatable({
        name = name,
        parent = parent,
        children = children,
        IDContext = IDContext,
        bullet = bullet,
    }, Node)
    return instance
end


--------------------------------------------------------------------------------
--                               Getters and setters
--------------------------------------------------------------------------------


-- Returns the Nodes Name
---@return name string
function Node:getName()
    return self.name
end

-- Returns the Nodes Parent
---@return parent node
function Node:getParent()
    return self.parent
end

-- Returns the Nodes Children
---@return children list
function Node:getChildren()
    return self.children
end

-- Returns the Nodes ID
function Node:getID()
    return self.ID
end


-- Returns whether the Node has the Bullet Property
function Node:getBullet()
    return self.Bullet
end


-- Adds a new child to the nodes list of children
---@param newChild node
function Node:addChild(newChild)
    table.insert(self.children, newChild)
end



--------------------------------------------------------------------------------
--                               Methods
--------------------------------------------------------------------------------


local IDContext = 1
-- converts a tree to a node using the custom Node class, called by TreeToNode internally
--@param tree Dump    - original dump to be converted
--@param parent Node  - parent Node
local function treeToNodeRecurse(tree, parent)
    success, iterator = pcall(pairs, tree)
    if success == true and (type(tree) == "table" or type(tree) == "userdata") then
        for label,content in pairs(tree) do
            if content then
                -- special case for empty table
                local stringify = Ext.Json.Stringify(content, STRINGIFY_OPTIONS)
                if stringify == "{}" then
                    local child = parent.addChild(Node:new("{}", parent, {}, label.IDContext, 1))
                    _P("Generated new Node with ID: ", child.IDContext)
                else
                    _P(label)
                    _P(parent)
                    _P(label.IDContext)
                    local child = parent.addChild(Node:new(tostring(label), parent, {}, label.IDContext, 1))
                    _P("Generated new Node with ID: ", child.IDContext)
                    treeToNodeRecurse(content, child)
                end
            else
                local child = parent.addChild(Node:new(tostring(label), parent, {}, label.IDContext, 0))
                _P("Generated new Node with ID: ", child.IDContext)
            end
        end
    else
        local child = parent.addChild(Node:new(tostring(tree), parent, {}, tree.IDContext, 1))
        _P("Generated new Node with ID: ", child.IDContext)
    end
end

-- converts a table to a tree using the custom Node class - calls treeToNodeRecurse
--@param treeRoot str - optional name for the parent, else root is chosen
--@param tree table    - original table to be converted
--@return tree Node   - the Node with all of the information in the table
function TreeToNode(treeRoot, tree)

    local parentName = "root"
    if treeRoot then
        parentName = treeRoot
    end

    local parent = Node:new(treeRoot, {}, 1, 0)
    _P("Generated new Node with ID: ", parent.IDContext)
    treeToNodeRecurse(tree, parent, 1)

    -- reset ID for next function call
    ID = 1

    -- parent appended with children
    return parent
end




-- imguiobj.Label -- visual name (editable)
-- imguiobj.Handle -- specific numbercombination assigned on creation
-- imguiobj.IDContext -- editable id
