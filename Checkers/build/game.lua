local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
require("board");
local function PopulateBoard(board)
for row=1, 8 do
for col=1, 8 do
if (row + col) % 2 == 1 then
if row <= 3 then
local black = BlackPiece:new(1,_dep_defaults.safe("number",_default_number,_dep_cast.cast(col,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(row,"number")));
board = board + black;
elseif row >= 6 then
local red = RedPiece:new(1,_dep_defaults.safe("number",_default_number,_dep_cast.cast(col,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(row,"number")));
board = board + red;
else

end

else

end

end
end
return board;
end
Score = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Score";
setmetatable(Score,_overload_meta);
Score.constructor = {};
function Score:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Score, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Score.redPlayer,Score.blackPlayer = (_default_number or _dep_defaults.get("number")),(_default_number or _dep_defaults.get("number"));
Score.constructor[#Score.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Score:won(color)
if _dep_cast.validate(color,"Red") then
self.redPlayer = self.redPlayer + 1;
elseif _dep_cast.validate(color,"Black") then
self.blackPlayer = self.blackPlayer + 1;
else

end

end
function Score:draw()
Color:setColorELA(Black:new(1));
love.graphics.setFont(love.graphics.newFont(14));
love.graphics.print('Black Score:' .. self.blackPlayer,12,20);
Color:setColorELA(Red:new(1));
love.graphics.print('Red Score:' .. self.blackPlayer,12,Math2D.screenHeight - 20 - 14);
end

Markers = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Markers";
setmetatable(Markers,_overload_meta);
Markers.constructor = {};
function Markers:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Markers, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Markers.fields = {};
Markers.constructor[#Markers.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Markers:mark(x,y)
self.fields[y][x] = true;
end
function Markers:unmark(x,y)
self.fields[y][x] = (_default_boolean or _dep_defaults.get("boolean"));
end
function Markers:draw()
end

Background = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Background";
setmetatable(Background,_overload_meta);
Background.constructor = {};
function Background:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Background, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Background.constructor[#Background.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Background:draw()
love.graphics.setColor(245 / 255,245 / 255,230 / 255);
love.graphics.rectangle('fill',0,0,Math2D.screenWidth,Math2D.screenHeight);
love.graphics.setColor(56 / 255,32 / 255,6 / 255);
love.graphics.rectangle('fill',Math2D:getOffsetToCenterHorizontally(Math2D.screenHeight),0,Math2D.screenHeight,Math2D.screenHeight);
end

Game = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Game";
setmetatable(Game,_overload_meta);
Game.constructor = {};
function Game:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Game, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Game.title = 'Checkers';
Game.board = Board:new(1);
Game.markers = Markers:new(1);
Game.score = Score:new(1);
Game.background = Background:new(1);
Game.drawables = {};
Game.constructor[#Game.constructor+1] = function(self)
self.board = PopulateBoard(self.board);
self.drawables[# self.drawables + 1] = self.background;
self.drawables[# self.drawables + 1] = self.board;
self.drawables[# self.drawables + 1] = self.markers;
self.drawables[# self.drawables + 1] = self.score;
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Game:draw()
for i=1, # self.drawables, 1 do
self.drawables[i]:draw();
end
end

