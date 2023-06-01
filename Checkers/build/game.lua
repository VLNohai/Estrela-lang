local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
test = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "test";
setmetatable(test,_overload_meta);
test.constructor = {};
test.public = {["x"] = true;};
function test:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(test, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
return new
end;
test.x = 1;
test.constructor[#test.constructor+1] = function(self)
end

_dep_overload.addOperator(test,nil,"__unm",function(a)
print(a.x .. ' Marioara');
end);
