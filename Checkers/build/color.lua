local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
Color = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Color";
setmetatable(Color,_overload_meta);
Color.constructor = {};
function Color:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Color, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Color.r,Color.g,Color.b = (_default_number or _dep_defaults.get("number")),(_default_number or _dep_defaults.get("number")),(_default_number or _dep_defaults.get("number"));
Color.constructor[#Color.constructor+1] = function(self,r,g,b)
self.r = r;
self.g = g;
self.b = b;
end
function Color:setColorELA(color)
love.graphics.setColor(color.r,color.g,color.b);
end

_dep_defaults.set("Color",Color:new(1,0,0,0));

Red = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Red";
setmetatable(Red,_overload_meta);
Red.constructor = {};
function Red:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Red, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Red.constructor[#Red.constructor+1] = function(self)
local r,g,b;
r = 0.8;
g = 0.1;
b = 0.1;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

Black = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Black";
setmetatable(Black,_overload_meta);
Black.constructor = {};
function Black:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Black, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Black.constructor[#Black.constructor+1] = function(self)
local r,g,b;
r = 0.1;
g = 0.1;
b = 0.1;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

Beige = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Beige";
setmetatable(Beige,_overload_meta);
Beige.constructor = {};
function Beige:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Beige, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Beige.constructor[#Beige.constructor+1] = function(self)
local r,g,b;
r = 250 / 255;
g = 240 / 255;
b = 230 / 255;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

Brown = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Brown";
setmetatable(Brown,_overload_meta);
Brown.constructor = {};
function Brown:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Brown, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Brown.constructor[#Brown.constructor+1] = function(self)
local r,g,b;
r = 217 / 255;
g = 185 / 255;
b = 155 / 255;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

Gold = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Gold";
setmetatable(Gold,_overload_meta);
Gold.constructor = {};
function Gold:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Gold, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Gold.constructor[#Gold.constructor+1] = function(self)
local r,g,b;
r = 255 / 255;
g = 215 / 255;
b = 5 / 255;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

Green = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Green";
setmetatable(Green,_overload_meta);
Green.constructor = {};
function Green:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Green, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Green.constructor[#Green.constructor+1] = function(self)
local r,g,b;
r = 0 / 255;
g = 250 / 255;
b = 5 / 255;
self = _dep_utils.deepCopyWithoutStatic(Color, self)
Color.constructor[1](self,r,g,b)
end

