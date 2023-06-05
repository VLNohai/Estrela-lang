local utils = {};

function utils.remove_first_n(tb, n)
    local result = {}
    for i = n + 1, #tb do
        result[i - n] = tb[i]
    end
    return result
end


function utils.equal_lists(list1, list2)
    if list1 == nil and list2 == nil then
      return true
    elseif type(list1) ~= "table" or type(list2) ~= "table" then
      return list1 == list2
    elseif list1.head == nil and list2.head == nil then
      return true
    elseif list1.head == nil or list2.head == nil then
      return false
    else
      return utils.equal_lists(list1.head, list2.head) and
             utils.equal_lists(list1.tail, list2.tail)
    end
  end
  

function utils.createStack()
    local stack = {size = 0, values = {}, top = nil};
    print('created new stack with size ' .. stack.size);

    function stack:push(element)
        print('pushed ' .. element);
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

function utils.reverse(tb)
    local rez = {};
    local _, array = ipairs(tb);
    for index, value in ipairs(tb)  do
        rez[#array - index + 1] = value; 
    end
    return rez;
end

function utils.dump(o)
    local type = luaType or type;
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if k ~= 'father' then
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. utils.dump(v) .. ','
        end
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function utils.dump_print(o)
    print(utils.dump(o));
end

function utils.length_with_holes(tb)
    local count = 0;
    for i, v in ipairs(tb) do
        count = count + 1
    end
    return count;
end

function utils.homogeouns_array(map, maxn)
    local array = {}
    for i = 1, maxn do
        if map[i] then
            array[#array + 1] = map[i]
        end
    end
    return array;
end

function utils.deepCopy(originalTable, targetTable, _copyCache, skipStatic)
    targetTable = targetTable or {}
    _copyCache = _copyCache or {}
    skipStatic = skipStatic or false

    for key, value in pairs(originalTable) do
        if type(value) == "table" then
            if _copyCache[value] then
                targetTable[key] = _copyCache[value]
            else
                local newTable = {}
                _copyCache[value] = newTable
                targetTable[key] = utils.deepCopy(value, newTable, _copyCache, skipStatic)
            end
        else
            if not (skipStatic and key == "static") then
                if targetTable[key] == nil then
                    targetTable[key] = value
                end
            end
        end
    end

    return targetTable
end


function utils.deepCopyWithoutStatic(orig, target)
    return utils.deepCopy(orig, target, visited, true);
end

return utils;