local defaults = {};

defaults.defaultValues = {
    ['number'] = 0;
    ['string'] = '';
    ['boolean'] = false;
    ['table'] = {};
    ['function'] = function() print('undefined') end;
    ['thread'] = coroutine.create(function() end);
    ['any'] = nil;
};

function defaults.set(typename, value)
    defaults.defaultValues[typename] = value;
end

function defaults.get(typename)
    return defaults.defaultValues[typename];
end

function defaults.safe(typename, localDefault ,value)
    if string.find(typename, '|') and (not localDefault) and (not defaults.defaultValues[typename]) then
        return {};
    end
    return (value or localDefault) or defaults.defaultValues[typename];
end

return defaults;