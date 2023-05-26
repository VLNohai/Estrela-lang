local utils = {};

function utils.remove_first_n(tb, n)
    local result = table.pack(table.unpack(tb, n + 1));
    result.n = nil;
    return result;
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

return utils;