local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
require("game");
local game = Game:new(1);
local whatDoIPrint = 'nothing';
local function switchTurn()
if game.arrowColor == 'red' then
game.arrowColor = 'black';
else
game.arrowColor = 'red';
end

end
local debug = '';
local function trackCursor(x,y)
local temp = Math2D:getSquareCoordinates(x,y);
DragAndDrop.currentPosition.first = temp.first;
DragAndDrop.currentPosition.second = temp.second;
if (_dep_cast.validate(DragAndDrop.selectedPiece.color,"Red") and (game.arrowColor == 'red')) or (_dep_cast.validate(DragAndDrop.selectedPiece.color,"Black") and (game.arrowColor == 'black')) then
game.markers.shouldDraw = 'points';
game.willMoveOnRelease = false;
if DragAndDrop.originalPosition == DragAndDrop.currentPosition then
whatDoIPrint = 'same square';
game.markers.points = game:allPossibleMoves(DragAndDrop.selectedPiece);
else
whatDoIPrint = 'other square ';
game.markers.shouldDraw = 'road';
debug = DragAndDrop.currentPosition.first .. ':' .. DragAndDrop.currentPosition.second .. ' <- ' .. DragAndDrop.originalPosition.first .. ':' .. DragAndDrop.originalPosition.second;
local road = game:canMovePieceTo(DragAndDrop.selectedPiece,DragAndDrop.currentPosition.first,DragAndDrop.currentPosition.second);
if # road > 0 then
game.willMoveOnRelease = true;
game.markers.road = road;
game.markers.color = Green:new(1);
if love.keyboard.isDown('space') and game.canAskForNext then
game.markers.road = game:nextRoad();
game.canAskForNext = false;
end

else
whatDoIPrint = 'cannot move';
game.markers.color = Red:new(1);
game.markers.road = {};
IS_GOOD = 'NOGOOD';
end

end

else
game.markers.shouldDraw = 'none';
game.willMoveOnRelease = false;
end

end
function love.mousepressed(x,y,button)
if button == 1 then
local temp = Math2D:getSquareCoordinates(_dep_defaults.safe("number",_default_number,_dep_cast.cast(x,"number")),_dep_defaults.safe("number",_default_number,_dep_cast.cast(y,"number")));
DragAndDrop.originalPosition.first = temp.first;
DragAndDrop.originalPosition.second = temp.second;
DragAndDrop.selectedPiece = game.board.pieces:get(DragAndDrop.originalPosition.first,DragAndDrop.originalPosition.second);
end

end
function love.mousereleased(x,y,button)
game.markers.shouldDraw = 'none';
if game.willMoveOnRelease then
game:movePiece(DragAndDrop.selectedPiece,DragAndDrop.currentPosition.first,DragAndDrop.currentPosition.second);
switchTurn();
end

end
function love.keyreleased(key)
if key == 'space' then
game.canAskForNext = true;
end

end
function love.load()
love.window.setTitle(game.title);
love.window.setMode(Math2D.screenWidth,Math2D.screenHeight);
end
function love.update()
if love.mouse.isDown(1) then
local currentX = _dep_defaults.safe("number",_default_number,_dep_cast.cast(love.mouse.getX(),"number"));
local currentY = _dep_defaults.safe("number",_default_number,_dep_cast.cast(love.mouse.getY(),"number"));
trackCursor(currentX,currentY);
end

local score = - game.board;
game.score.redPlayer = score.first;
game.score.blackPlayer = score.second;
end
function love.draw()
game:draw();
love.graphics.setColor(0,0,0);
love.graphics.print(whatDoIPrint);
love.graphics.print(debug,0,100);
end
