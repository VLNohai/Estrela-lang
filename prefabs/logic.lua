local list = require('deps.linkedlist');
local logic = {};
local utils = require('deps.utils');
local CURRENT_ADRESS = 1;
local CURRENT_SCOPE_ID = 0;
local bigInteger = 2^31 - 1;
_Logic_stack_depth = 0;

local function allocate_new(key, value, bindings)
   bindings[key] = CURRENT_ADRESS;
   bindings[CURRENT_ADRESS] = value;
   CURRENT_ADRESS = CURRENT_ADRESS + 1;
   if CURRENT_ADRESS == bigInteger - 1 then
      CURRENT_ADRESS = 1;
   end
end

local function get_value(key, bindings)
   if not bindings[key] then
      return nil;
   end
   return bindings[bindings[key]];
end

function logic.unify(a, b, bindings)
   if a == b then
      return bindings
   elseif  type(a) == "string" and type(b) == "string" then
         if bindings[a] and bindings[b] and (bindings[a] == bindings[b]) then
            return bindings;
         elseif (not bindings[a]) and (not bindings[b]) then
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
         bindings[bindings[b]] = logic.substituteAtoms(a, bindings);
      else
         allocate_new(b, a, bindings);
      end
   elseif type(a) == "string" then
      if not b then return nil end
      if bindings[a] then
         if get_value(a, bindings) then
            return logic.unify(get_value(a, bindings), b, bindings);
         end
         bindings[bindings[a]] = logic.substituteAtoms(b, bindings);
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
   local result = {};
   local elems = {...};
   for index, elem in pairs(elems) do
      if type(elem) == "table"then
         elem = list:new(elem);
      end
      result[index] = elem;
   end
   return unpack(result);
end

function logic.unify_many(list1, list2, bindings)
   if not (list1 and list2) then return nil end;
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

function logic.substituteAtoms(value, bindings)
   if type(value) == "string" then
      local bound_value = get_value(value, bindings)
      if type(bound_value) == 'table' then
         return logic.substituteAtoms(bound_value, bindings);
      end
      return bound_value or value
   elseif type(value) == "table" then
      local new_head = logic.substituteAtoms(value.head, bindings)
      local new_tail = logic.substituteAtoms(value.tail, bindings)
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

function logic.run(funcs, args)
   for index, func in ipairs(funcs) do
      local co = coroutine.create(func);
      while coroutine.status(co) ~= "dead" do
         local _, temp = coroutine.resume(co, unpack(args));
         coroutine.yield(temp);
      end
   end
end

function logic.is_list(arg, bindings)
   return (type(get_value(arg, bindings)) == 'table');
end

function logic.atom(arg, bindings)
   return not(logic.is_list(arg, bindings));
end

function logic.listToArray(current)
   local array = {}
   if not current then return end
   while current.head do
       if type(current.head) == "table" and current.head.head then
           array[#array+1] = logic.listToArray(current.head);
       else
           array[#array+1] = current.head;
       end
       current = current.tail
   end

   return array
end

function logic.listOfListsToArray(lists)
   if not lists then return end
   for i = 1, #lists, 1 do
      if type(lists[i]) == "table" then
         lists[i] = logic.listToArray(lists[i]);
      end
   end
   return lists;
end

return logic;