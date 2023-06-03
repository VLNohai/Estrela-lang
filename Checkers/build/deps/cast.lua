local declaredTypes = require('deps.types');

local cast = {};

local basicTypes = {
    ['nil'] = true, 
    ['boolean'] = true, 
    ['number'] = true, 
    ['string'] = true, 
    ['table'] = true, 
    ['function'] = true, 
    ['userdata'] = true, 
    ['thread'] = true,
    ['any'] = true
}

function cast.cast(var, castTo)
    if basicTypes[castTo] then
        if type(var) == castTo then
            return var;
        else
            return nil;
        end
    else
        if type(var) ~= "table" then return nil end;
        local typename = getmetatable(var or {}).typename or '';
        local canCastTo = declaredTypes[typename];
        if not canCastTo[castTo] then return nil end;
        var.class = castTo;
        return var;
    end
end

function cast.validate(var, castTo)
    if cast.cast(var, castTo) then
        return true;
    else
        return false;
    end
end

return cast;