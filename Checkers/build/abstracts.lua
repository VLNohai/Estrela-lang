local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
_dep_defaults.set("number",0);

local _default_number = - 1
Pair = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Pair";
setmetatable(Pair,_overload_meta);
Pair.constructor = {};
function Pair:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Pair, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Pair.first,Pair.second = (_default_number or _dep_defaults.get("number")),(_default_number or _dep_defaults.get("number"));
Pair.constructor[#Pair.constructor+1] = function(self,first,second)
self.first = first;
self.second = second;
end

_dep_overload.addOperator(Pair,Pair,"__eq",function(pair1,pair2)
return ((pair1.first == pair2.first) and (pair1.second == pair2.second));
end);
Drawable = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Drawable";
setmetatable(Drawable,_overload_meta);
Drawable.constructor = {};
Drawable.constructor[#Drawable.constructor+1] = function(self)
end

Math2D = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Math2D";
setmetatable(Math2D,_overload_meta);
Math2D.constructor = {};
function Math2D:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Math2D, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Math2D.screenHeight = 720;
Math2D.screenWidth = 960;
Math2D.tableHeight = 680;
Math2D.tableWidth = 680;
Math2D.pieceRadius = 35;
function Math2D:getOffsetToCenterHorizontally(width)
return (Math2D.screenWidth - width) / 2;
end
function Math2D:getOffsetToCenterVertically(height)
return (Math2D.screenHeight - height) / 2;
end
function Math2D:getSquareCorner(x,y)
local squareLeftCornerX = Math2D:getOffsetToCenterHorizontally(Math2D.tableWidth) + ((Math2D.tableWidth / 8) * (x - 1));
local squareLeftCornerY = Math2D:getOffsetToCenterVertically(Math2D.tableHeight) + ((Math2D.tableHeight / 8) * (y - 1));
return Pair:new(1,squareLeftCornerX,squareLeftCornerY);
end
function Math2D:getSquareCenter(x,y)
local corner = Math2D:getSquareCorner(x,y);
local centerX = corner.first + Math2D.tableWidth / 16;
local centerY = corner.second + Math2D.tableHeight / 16;
return Pair:new(1,centerX,centerY);
end
function Math2D:getSquareCoordinates(x,y)
local tableX = (Math2D.screenWidth - Math2D.tableWidth) / 2;
local tableY = (Math2D.screenHeight - Math2D.tableHeight) / 2;
if (x < tableX) or (x > (tableX + Math2D.tableWidth)) or (y < tableY) or (y > (tableY + Math2D.tableHeight)) then
return (Pair:new(1,- 1,- 1));
end

local squareSize = Math2D.tableWidth / 8;
local squareX = _dep_defaults.safe("number",_default_number,_dep_cast.cast((math.floor((x - tableX) / squareSize) + 1),"number"));
local squareY = _dep_defaults.safe("number",_default_number,_dep_cast.cast((math.floor((y - tableY) / squareSize) + 1),"number"));
return Pair:new(1,squareX,squareY);
end

