local list = require('deps.linkedlist');
local logic = {};
local utils = require('deps.utils');
local CURRENT_ADRESS = 1;
local CURRENT_SCOPE_ID = 0;
_Logic_stack_depth = 0;

local function allocate_new(key, value, bindings)
   bindings[key] = CURRENT_ADRESS;
   bindings[CURRENT_ADRESS] = value;
   CURRENT_ADRESS = CURRENT_ADRESS + 1;
end

local function get_value(key, bindings);
   if not bindings[key] then
      return nil;
   end;
   return bindings[bindings[key]];
end

function logic.unify(a, b, bindings)
   if a == b then
      return bindings
   elseif bindings[a] and bindings[b] and (bindings[a] == bindings[b]) then
      return bindings;
   elseif  type(a) == "string" and type(b) == "string" then
         if (not bindings[a]) and (not bindings[b]) then
            allocate_new(a, nil, bindings);
            bindings[b] = bindings[a];
         elseif not bindings[a] then
            bindings[a] = bindings[b];
         elseif not bindings[b] then
            bindings[b] = bindings[a];
         elseif (not get_value(a, bindings)) and (not get_value(b, bindings)) then
            bindings[a] = bindings[b];
         else
            local next_a = get_value(a, bindings) or a;
            local next_b = get_value(b, bindings) or b;
            return logic.unify(next_a, next_b, bindings);
         end
   elseif type(b) == "string" then
      if not a then return nil end
      if bindings[b] then
         if get_value(b, bindings) then
            return logic.unify(a, get_value(b, bindings), bindings);
         end
         bindings[bindings[b]] = logic.substitute_vars(a, bindings);
      else
         allocate_new(b, a, bindings);
      end
   elseif type(a) == "string" then
      if not b then return nil end
      if bindings[a] then
         if get_value(a, bindings) then
            return logic.unify(get_value(a, bindings), b, bindings);
         end
         bindings[bindings[a]] = logic.substitute_vars(b, bindings);
      else
         allocate_new(a, b, bindings);
      end
   elseif type(a) == "table" and type(b) == "table" then
      bindings = logic.unify(a.head, b.head, bindings)
      if not bindings then
         return nil;
      end
      return logic.unify(a.tail, b.tail, bindings)
   else
      return nil
   end
      return bindings;
end

function logic.toList(...)
   local elems = {...};
   local result = {};
   for index, elem in ipairs(elems) do
      if type(elem) == "table"then
         elem = list:new(elem);
      end
      result[#result+1] = elem;
   end
   return table.unpack(result);
end

function logic.unify_many(list1, list2, bindings)
    if #list1 ~= #list2 then
        print('unequal lists provided!');
        return nil;
    end
    for i = 1, #list1, 1 do
        local new_bindings = logic.unify(list1[i], list2[i], bindings);
        if not new_bindings then
            return nil;
        end
        bindings = new_bindings;
    end
    return bindings;
end

function logic.check(a, b, op)
   if type(a) ~= "number" or type(b) ~= "number" then
      return nil;
   end
   if op == '==' then
      return a == b;
   elseif op == '~=' then
      return a ~= b;
   elseif op == '>=' then
      return a >= b;
   elseif op == '<=' then
      return a <= b;
   elseif op == '>' then
      return a > b;
   elseif op == '<' then
      return a < b;
   end
end

function logic.substitute_vars(value, bindings)
   if type(value) == "string" then
      local bound_value = get_value(value, bindings)
      return bound_value or value
   elseif type(value) == "table" then
      local new_head = logic.substitute_vars(value.head, bindings)
      local new_tail = logic.substitute_vars(value.tail, bindings)
      return {head = new_head, tail = new_tail}
   else
      return value
   end
end

function logic.newScopeId()
   CURRENT_SCOPE_ID = CURRENT_SCOPE_ID + 1;
   return CURRENT_SCOPE_ID
end

function logic.print_list(tb)
   list.list_print(tb);
end

return logic;