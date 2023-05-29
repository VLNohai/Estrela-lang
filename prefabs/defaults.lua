local defaults = {};

defaults.defaultValues = {
    ['number'] = 0;
    ['string'] = '';
    ['boolean'] = false;
    ['table'] = {};
    ['function'] = function() print('undefined') end;
    ['thread'] = coroutine.create(function() end);
};

function defaults.set(typename, value)
    defaults.defaultValues[typename] = value;
end

function defaults.get(typename)
    return defaults.defaultValues[typename];
end

function defaults.safe(typename, value)
    return value or defaults.defaultValues[typename];
end

return defaults;