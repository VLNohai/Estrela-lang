local list = require('deps.linkedlist');
local logic = {};
local LOGIC_ADDRESSES = {};
local CURRENT_INDEX = 0;

function logic.toList(...)
    local elems = {...};
    local result = {};
    for index, elem in ipairs(elems) do
        if type(elem) == "table"then
            return list:new(elem);
        end
        result = result[#result];
    end
    return result;
end

function logic.unify(a, b, bindings)
    if bindings == nil then
      bindings = {}
    end
  
    if a == b then
      return bindings
    elseif type(a) == "string" then
      bindings[a] = b
      return bindings
    elseif type(b) == "string" then
      bindings[b] = a
      return bindings
    elseif type(a) == "table" and type(b) == "table" then
      bindings = logic.unify(a.head, b.head, bindings)
      return logic.unify(a.tail, b.tail, bindings)
    else
      return nil
    end
  end

function logic.to_value(elem)
    return LOGIC_ADDRESSES[elem];
end

return logic;