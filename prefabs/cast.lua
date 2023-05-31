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
        local typeInfo = declaredTypes[castTo];
        for key, _ in pairs(typeInfo) do
            if not var.public[key] then
                return nil;
            end
        end
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