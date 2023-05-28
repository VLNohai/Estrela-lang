utils = {}
open = io.open;

function utils.makeTrue(...)
    return true;
end

function utils.createStack()
    local stack = {size = 0, values = {}, top = nil};

    function stack:push(element)
        self.size = self.size + 1; self.values[self.size] = element; self.top = element; 
    end

    function stack:pop()
        if self.size > 0 then
            self.size = self.size - 1;
            self.top = self.values[self.size];
        else
            self.top = nil;
        end
    end

    return stack;
end

function utils.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. utils.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function utils.dump_print(o)
    print(utils.dump(o));
end

function utils.reverse(list)
    for i=1, #list/2, 1 do
        list[i], list[#list - i + 1] = list[#list - i + 1], list[i];
    end
    return list;
end

function utils.flatten(o)
    if #o == 1 then
        o = o[1];
    end
    return o;
end

function utils.remove_first_n(tb, n)
    return table.pack(table.unpack(tb, n + 1));
end

function utils.extractField(tb, fieldname)
    local rez = {}
    for index, elem in ipairs(tb) do
        if elem[fieldname] then
            rez[#rez+1] = elem[fieldname];
        end
    end
    return rez;
end

function utils.listOfIdsToCommaString(tb, defaults_to_own_name)
    local string = '';
    local dton = nil;
    if not defaults_to_own_name then
        dton = '';
    end
    if #tb > 0 then
        string = string .. tb[1].id .. (dton or (' or "' .. tb[1].id .. '"'));
        for index, elem in ipairs(utils.remove_first_n(tb, 1)) do
            string = string .. ', ' .. elem.id .. (dton or (' or "' .. elem.id .. '"'));
        end
    end
    return string;
end

function utils.fromTypeNodeToString(matchedType)
    local varType = nil;
    if type(matchedType) == "string" then
        varType = matchedType;
    elseif type(matchedType) == "table" then
        local depth = 0;
        local currentType = matchedType;
        while type(currentType) == "table" do
           depth = depth + 1;
           currentType = currentType[1];
        end
        varType = currentType .. '|' .. depth;
    end
    return varType;
end

function utils.deepCopy(orig, target, copies, visited)
    copies = copies or {}
    visited = visited or {}
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = target or {}
            copies[orig] = copy
            visited[copy] = true
            for orig_key, orig_value in next, orig, nil do
                if copy[orig_key] == nil then
                    local orig_key_copy = utils.deepCopy(orig_key, nil, copies, visited)
                    local orig_value_copy = utils.deepCopy(orig_value, nil, copies, visited)
                    copy[orig_key_copy] = orig_value_copy
                end
            end
            local orig_metatable = getmetatable(orig)
            if orig_metatable and not visited[orig_metatable] then
                local metatable_copy = utils.deepCopy(orig_metatable, nil, copies, visited)
                setmetatable(copy, metatable_copy)
            end
        end
    else
        copy = orig
    end
    return copy
end

function utils.fileExists(filePath)
    local file = io.open(filePath, "r")
    if file then
      file:close()
      return true
    else
      return false
    end
  end

function utils.pathTo(filePath)
    return string.match(filePath, "(.-)/[^/]*$");
end

function utils.getModulePath(mainFilePath, requiredPath)
    requiredPath = string.gsub(requiredPath, "%.", "/");
    return mainFilePath .. '/' .. requiredPath .. '.ela';
end

return utils;