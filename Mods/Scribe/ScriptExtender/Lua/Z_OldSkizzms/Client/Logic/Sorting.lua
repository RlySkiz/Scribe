-------------------------------------------------------------------------------------------------------
-- 
-- 	                                    Tabel Sorting
--
-- 
---------------------------------------------------------------------------------------------------------



Sorting = {}
Sorting.__index = Sorting


------------------------------------------------------------------------------------------------
--                                    Constructor
------------------------------------------------------------------------------------------------

function Sorting:new()
    local instance = setmetatable({}, Sorting)
    return instance
end



------------------------------------------------------------------------------------------------
--                                     Methods
------------------------------------------------------------------------------------------------

-- Recursively filters a table based on a search term
--@param searchTerm string         - the searchTerm by what to filter
--@param tableToFilter table       - the original table
--@return table                    - returns a new table containing only the elements that include the search term
function Sorting:filter(searchTerm, tableToFilter)

    local foundInKey = false
    local filteredTable = {}


    local success, iterator = pcall(pairs, tableToFilter)
    if success == true and (type(tableToFilter) == "table" or type(tableToFilter) == "userdata") then
        for key, value in pairs(tableToFilter) do
            local foundInKey = false

            -- Check for search term in the key
            if CaseInsensitiveSearch(tostring(key), searchTerm) then
                print("found ", searchTerm, " in key ", key)
                foundInKey = true
            end

            -- Continue processing only if the key search was not successful
            if (type(value) == "table") and (not foundInKey) then
                -- Recursively filter subtables
                local result = Sorting:filter(searchTerm, value)
                if next(result) ~= nil then
                    filteredTable[key] = result
                end
            elseif not foundInKey then
                -- Check the value if it's not a table
                if CaseInsensitiveSearch(tostring(value), searchTerm) then
                    filteredTable[key] = value
                end
            else
                filteredTable[key] = value
            end

        end
    else
        -- Non-table values, compare directly
        if CaseInsensitiveSearch(tostring(tableToFilter), searchTerm) then
            return tableToFilter
        end
    end

    _D("sorted table " , #sortedTable )
    return filteredTable
end
