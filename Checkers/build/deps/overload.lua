local utils = require('deps.utils');
local overload = {}
local operators = {};

function overload.addOperator(class, term, field, func)
    if luaType(term) == "table" then
        term = getmetatable(term).typename or 'table';
    else
        term = 'nil';
    end
    operators[getmetatable(class).typename .. '/' .. field .. '/' .. term] = func;
end

local function fieldDecision(field)
    return function (a, b)
        local bType = '';
        if field == '__unm' or field == '__len' then
            bType = 'nil';
            b = nil;
        elseif luaType(b) == 'table' then
            if not getmetatable(b) then
                bType = 'table';
            else
                bType = getmetatable(b).typename;
            end
        else
            bType = luaType(b);
        end
        return operators[getmetatable(a).typename .. '/' .. field .. '/' .. bType](a, b);
    end
end

local metatable = {
    __unm = fieldDecision("__unm");
    __len = fieldDecision("__len");
    __add = fieldDecision("__add");
    __sub = fieldDecision("__sub");
    __mul = fieldDecision("__mul");
    __div = fieldDecision("__div");
    __mod = fieldDecision("__mod");
    __pow = fieldDecision("__pow");
    __eq = fieldDecision("__eq");
    __concat = fieldDecision("__concat");
}

function overload.getMeta()
    return utils.deepCopy(metatable);
end

return overload;