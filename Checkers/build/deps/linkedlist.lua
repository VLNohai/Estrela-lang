local utils = require('deps.utils');
local linkedList = {};

local function imbricate(list, index)
    local head = list[index];
    if type(head) == "table" then
        head = linkedList:new(head);
    end
    if index > #list then
        return {};
    end
    if index == #list then
        return {head = head, tail = {}}
    end
    return {head = head, tail = imbricate(list, index + 1)};
end

function linkedList:new(tb)
    local list = { head = nil, tail = {} };
    if type(tb) == "table" then
        local _, array = ipairs(tb);
        if(#array > 0) then
            list.head = array[1];
            if type(list.head) == 'table' then
                list.head = linkedList:new(array[1]);
            end
            list.tail = imbricate(utils.remove_first_n(array, 1), 1);
        else
            return {};
        end
    end
    setmetatable(list, self);
    self.__index = self;
    return list;
end

function linkedList:pop()
    self.head = self.tail.head;
    self.tail = self.tail.tail or {};
end

function linkedList:push(elem)
    if not self.head then
        self.head = elem;
        return;
    end
    self = {head = elem, tail = self};
end

local function linkedlist_to_string(list)
    if type(list) ~= 'table' then
        return list or '';
    end
    local asString = '[';
    if list.head then
       asString = asString .. linkedlist_to_string(list.head);
       list = list.tail;
       if list then
        while list.head do
            asString = asString .. ', ' .. linkedlist_to_string(list.head);
            list = list.tail;
        end
       end
       asString = asString .. ']';
    end
    return asString;
end

function linkedList:print()
    utils.dump_print(linkedlist_to_string(self));
end

function linkedList.list_print(list)
    utils.dump_print(linkedlist_to_string(list));
end

return linkedList;