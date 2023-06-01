local utils = require('deps.utils');
local overload = {}
local operators = {};

function overload.addOperator(class, term, field, func)
    if type(term) == "table" then
        term = getmetatable(term).typename;
    else
        term = 'nil';
    end
    operators[getmetatable(class).typename .. '/' .. field .. '/' .. term] = func;
end

local function fieldDecision(field)
    return function (a, b)
        local bType = '';
        if field == '__unm' then
            bType = 'nil';
            b = nil;
        elseif type(b) == 'table' then
            bType = getmetatable(b).typename;
        else
            bType = type(b);
        end
        return operators[getmetatable(a).typename .. '/' .. field .. '/' .. bType](a, b);
    end
end

local metatable = {
    __unm = fieldDecision("__unm");
    __add = fieldDecision("__add");
    __sub = fieldDecision("__sub");
    __mul = fieldDecision("__mul");
    __div = fieldDecision("__div");
    __mod = fieldDecision("__mod");
    __pow = fieldDecision("__pow");
    __concat = fieldDecision("__concat");
}

function overload.getMeta()
    return utils.deepCopy(metatable);
end

return overload;