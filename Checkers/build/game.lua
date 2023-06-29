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
end

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
end

end
function Score:draw()
Color:setColorELA(Black:new(1));
love.graphics.setFont(love.graphics.newFont(12));
love.graphics.print('Black Pieces:' .. self.blackPlayer,12,20);
Color:setColorELA(Red:new(1));
love.graphics.print('Red Pieces:' .. self.redPlayer,12,Math2D.screenHeight - 20 - 14);
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
Markers.originalCache = Pair:new(1,- 1,- 1);
Markers.currentCache = Pair:new(1,- 1,- 1);
Markers.color = Red:new(1);
Markers.shouldDraw = 'none';
Markers.points = {};
Markers.road = {};
Markers.constructor[#Markers.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Markers:draw()
if self.shouldDraw == 'road' then
Color:setColorELA(self.color);
local temp = Math2D:getSquareCenter(DragAndDrop.originalPosition.first,DragAndDrop.originalPosition.second);
local startX = temp.first;
local startY = temp.second;
local endX = nil;
local endY = nil;
if # self.road == 0 then
temp = Math2D:getSquareCenter(DragAndDrop.currentPosition.first,DragAndDrop.currentPosition.second);
else
temp = Math2D:getSquareCenter(_dep_defaults.safe("Pair",_default_Pair,self.road[1]).first,_dep_defaults.safe("Pair",_default_Pair,self.road[1]).second);
end

if temp.first == - 1 or temp.second == - 1 then
return ;
end

endX = temp.first;
endY = temp.second;
local index = 1;
repeat
index = index + 1;
love.graphics.line(startX,startY,endX,endY);
local angle = math.atan2(endY - startY,endX - startX);
local arrowSize = 25;
local arrowPoints = {endX - arrowSize * math.cos(angle - math.pi / 6);endY - arrowSize * math.sin(angle - math.pi / 6);endX;endY;endX - arrowSize * math.cos(angle + math.pi / 6);endY - arrowSize * math.sin(angle + math.pi / 6);};
love.graphics.polygon('fill',arrowPoints);
startX = endX;
startY = endY;
if _dep_defaults.safe("Pair",_default_Pair,self.road[index]) then
temp = Math2D:getSquareCenter((_dep_defaults.safe("Pair",_default_Pair,self.road[index]).first or - 1),(_dep_defaults.safe("Pair",_default_Pair,self.road[index]).second or - 1));
endX = temp.first;
endY = temp.second;
end

until index > # self.road;
elseif self.shouldDraw == 'points' then
Color:setColorELA(Green:new(1));
for i=1, # self.points, 1 do
local temp = Math2D:getSquareCenter(_dep_defaults.safe("Pair",_default_Pair,self.points[i]).first,_dep_defaults.safe("Pair",_default_Pair,self.points[i]).second);
love.graphics.circle('fill',temp.first,temp.second,15);
end
end

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
Game.arrowColor = 'red';
Game.willMoveOnRelease = false;
Game.canAskForNext = true;
Game.constructor[#Game.constructor+1] = function(self)
self.board = PopulateBoard(self.board);
self.drawables[# self.drawables + 1] = self.background;
self.drawables[# self.drawables + 1] = self.board;
self.drawables[# self.drawables + 1] = self.markers;
self.drawables[# self.drawables + 1] = self.score;
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
Game.originalPosCache = Pair:new(1,- 2,- 2);
Game.newPosCache = Pair:new(1,- 2,- 2);
Game.roadCache = {};
Game.coroutineSave = (_default_thread or _dep_defaults.get("thread"));
function Game:canMovePieceTo(piece,newx,newy)
if (Pair:new(1,piece.x,piece.y) == self.originalPosCache) and (Pair:new(1,newx,newy) == self.newPosCache) then
return self.roadCache;
end

self.originalPosCache = Pair:new(1,piece.x,piece.y);
self.newPosCache = Pair:new(1,newx,newy);
self.roadCache = {};
local numberTable = self.board:convertToNumbers();
local co = _dep_defaults.safe("thread",_default_thread,_dep_cast.cast(coroutine.create(piece.Turn),"thread"));
self.coroutineSave = co;
local result = {coroutine.resume(co,piece,numberTable,piece.x,piece.y,newx,newy);};
if (result[2]) then
for i=1, # result[2][6], 1 do
self.roadCache[# self.roadCache + 1] = Pair:new(1,_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][6][i][1],"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][6][i][2],"number")));
end
return self.roadCache;
end

self.roadCache = {};
return self.roadCache;
end
function Game:nextRoad()
local result = {coroutine.resume(self.coroutineSave);};
if result[2] and luaType(result[2]) == 'table' then
self.roadCache = {};
for i=1, # result[2][6], 1 do
self.roadCache[# self.roadCache + 1] = Pair:new(1,_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][6][i][1],"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][6][i][2],"number")));
end
end

return self.roadCache;
end
Game.allMovesCache = {};
function Game:allPossibleMoves(piece)
self.roadCache = {};
if (Pair:new(1,piece.x,piece.y) == self.originalPosCache) then
return self.allMovesCache;
end

self.originalPosCache = Pair:new(1,piece.x,piece.y);
self.allMovesCache = {};
local numberTable = self.board:convertToNumbers();
local co = _dep_defaults.safe("thread",_default_thread,_dep_cast.cast(coroutine.create(piece.Turn),"thread"));
local result = {coroutine.resume(co,piece,numberTable,piece.x,piece.y);};
while result[2] do
self.allMovesCache[# self.allMovesCache + 1] = Pair:new(1,_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][4],"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(result[2][5],"number")));
result = {coroutine.resume(co);};
end

return self.allMovesCache;
end
function Game:takePieces(piece)
local pieceX = piece.x;
local pieceY = piece.y;
for i=1, # self.markers.road, 1 do
if math.abs(pieceX - _dep_defaults.safe("Pair",_default_Pair,self.markers.road[i]).first) > 1 then
local midX = (pieceX + _dep_defaults.safe("Pair",_default_Pair,self.markers.road[i]).first) / 2;
local midY = (pieceY + _dep_defaults.safe("Pair",_default_Pair,self.markers.road[i]).second) / 2;
if (_dep_cast.validate(piece.color,"Red") and _dep_cast.validate(_dep_defaults.safe("Piece",_default_Piece,_dep_defaults.safe("Piece_of_1",_default_Piece_of_1,self.board.pieces.fields[midY])[midX]).color,"Black")) or (_dep_cast.validate(piece.color,"Black") and _dep_cast.validate(_dep_defaults.safe("Piece",_default_Piece,_dep_defaults.safe("Piece_of_1",_default_Piece_of_1,self.board.pieces.fields[midY])[midX]).color,"Red")) then
self.board.pieces.fields[midY][midX] = (_default_Piece or _dep_defaults.get("Piece"));
end

pieceX = _dep_defaults.safe("Pair",_default_Pair,self.markers.road[i]).first;
pieceY = _dep_defaults.safe("Pair",_default_Pair,self.markers.road[i]).second;
end

end
end
function Game:movePiece(piece,newx,newy)
local func = self.takePieces;
func(self,piece);
self.board.pieces.fields[piece.y][piece.x] = (_default_Piece or _dep_defaults.get("Piece"));
piece.x = newx;
piece.y = newy;
if (newy == 1) or (newy == 8) then
local newCrownedPiece = CrownPiece:new(1,piece);
self.board = self.board + newCrownedPiece;
else
self.board = self.board + piece;
end

end
function Game:draw()
for i=1, # self.drawables, 1 do
self.drawables[i]:draw();
end
end

