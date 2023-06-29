local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
require("piece");
local _default_Piece = BlankPiece:new(1)
PieceMatrix = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "PieceMatrix";
setmetatable(PieceMatrix,_overload_meta);
PieceMatrix.constructor = {};
function PieceMatrix:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(PieceMatrix, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
PieceMatrix.fields = {};
PieceMatrix.constructor[#PieceMatrix.constructor+1] = function(self)
for i=1, 8, 1 do
self.fields[i] = {};
end
end
function PieceMatrix:get(x,y)
local piece = _dep_defaults.safe("Piece",_default_Piece,_dep_defaults.safe("Piece_of_1",_default_Piece_of_1,self.fields[y])[x]);
return piece;
end
function PieceMatrix:set(x,y,piece)
piece.x = x;
piece.y = y;
self.fields[y][x] = piece;
end
function PieceMatrix:free(x,y)
self.fields[y][x] = (_default_Piece or _dep_defaults.get("Piece"));
end

Board = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Board";
setmetatable(Board,_overload_meta);
Board.constructor = {};
function Board:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Board, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
Board.pieces = PieceMatrix:new(1);
Board.constructor[#Board.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Board:convertToNumbers()
local result = {{};{};{};{};{};{};{};{};};
for j=1, 8, 1 do
for i=1, 8, 1 do
local targetPiece = self.pieces:get(_dep_defaults.safe("number",_default_number,_dep_cast.cast(i,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(j,"number")));
if _dep_cast.validate(targetPiece.color,"Red") then
result[j][i] = 2;
elseif _dep_cast.validate(targetPiece.color,"Black") then
result[j][i] = 1;
else
result[j][i] = 0;
end

end
end
return result;
end
function Board:draw()
for j=1, 8, 1 do
for i=1, 8, 1 do
if (i + j) % 2 == 0 then
Color:setColorELA(Beige:new(1));
else
Color:setColorELA(Brown:new(1));
end

local leftCorner = Math2D:getSquareCorner(_dep_defaults.safe("number",_default_number,_dep_cast.cast(i,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(j,"number")));
love.graphics.rectangle('fill',leftCorner.first,leftCorner.second,Math2D.tableWidth / 8,Math2D.tableHeight / 8);
end
end
for j=1, 8, 1 do
for i=1, 8, 1 do
local currentPiece = _dep_utils.deepCopy(self.pieces:get(_dep_defaults.safe("number",_default_number,_dep_cast.cast(i,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(j,"number"))));
currentPiece:draw();
end
end
end

_dep_overload.addOperator(Board,nil,"__unm",function(board)
local reds = 0;
local blacks = 0;
for j=1, 8, 1 do
for i=1, 8, 1 do
local targetPiece = board.pieces:get(_dep_defaults.safe("number",_default_number,_dep_cast.cast(i,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(j,"number")));
if _dep_cast.validate(targetPiece.color,"Red") then
reds = reds + 1;
elseif _dep_cast.validate(targetPiece.color,"Black") then
blacks = blacks + 1;
end

end
end
return Pair:new(1,reds,blacks);
end);
_dep_overload.addOperator(Board,BlackPiece,"__add",function(board,piece)
board.pieces:set(piece.x,piece.y,piece);
return board;
end);
_dep_overload.addOperator(Board,RedPiece,"__add",function(board,piece)
board.pieces:set(piece.x,piece.y,piece);
return board;
end);
_dep_overload.addOperator(Board,CrownPiece,"__add",function(board,piece)
board.pieces:set(piece.x,piece.y,piece);
return board;
end);
_dep_overload.addOperator(Board,Piece,"__add",function(board,piece)
board.pieces:set(piece.x,piece.y,piece);
return board;
end);
