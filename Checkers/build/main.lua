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
function love.load()
love.window.setTitle(game.title);
love.window.setMode(Math2D.screenWidth,Math2D.screenHeight);
end
function love.update()
end
function love.draw()
game:draw();
end
