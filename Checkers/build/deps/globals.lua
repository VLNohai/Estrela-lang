local utils = require('deps.utils');

luaType = type;
type = function (var)
    if luaType(var) == "table" and getmetatable(var) and getmetatable(var).typename then
        return getmetatable(var).typename;
    end
    return luaType(var);
end

function log(item)
    utils.dump_print(item);
end