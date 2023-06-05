local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
require("abstracts");
require("color");
require("prologBasics");
Piece = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Piece";
setmetatable(Piece,_overload_meta);
Piece.constructor = {};
Piece.x,Piece.y = (_default_number or _dep_defaults.get("number")),(_default_number or _dep_defaults.get("number"));
Piece.color = Beige:new(1);
Piece.constructor[#Piece.constructor+1] = function(self)
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
Piece.constructor[#Piece.constructor+1] = function(self,posX,posY)
self.x = posX;
self.y = posY;
self = _dep_utils.deepCopyWithoutStatic(Drawable, self)
Drawable.constructor[1](self)
end
function Piece:FreeSquare(table, x, y)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
table, x, y = _dep_logic.toList(table or "table", x or "x", y or "y");
end
local function FreeSquare_1(table, x, y)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID},
{table, x, y}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.unify_many({'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_rez'..'#'..scID}, Prolog:getXY(_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
if not _dep_logic.check(_dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1), 0, '==') then return nil end;
return {_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = FreeSquare_1(table, x, y) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Piece:InBounds(x, y)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
x, y = _dep_logic.toList(x or "x", y or "y");
end
local function InBounds_1(x, y)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID},
{x, y}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), 1, '>=') then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), 8, '<=') then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), 1, '>=') then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), 8, '<=') then return nil end;
return {_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = InBounds_1(x, y) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Piece:GetInBetween(table, x1, y1, x2, y2, rez)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
table, x1, y1, x2, y2, rez = _dep_logic.toList(table or "table", x1 or "x1", y1 or "y1", x2 or "x2", y2 or "y2", rez or "rez");
end
local function GetInBetween_1(table, x1, y1, x2, y2, rez)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x1'..'#'..scID, '_y1'..'#'..scID, '_x2'..'#'..scID, '_y2'..'#'..scID, '_rez'..'#'..scID},
{table, x1, y1, x2, y2, rez}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.unify("_midx"..'#'..scID, (_dep_logic.substitute_vars('_x1'..'#'..scID, _logic_bindings_1)+_dep_logic.substitute_vars('_x2'..'#'..scID, _logic_bindings_1))/2, _logic_bindings_1) then return nil end;
if not _dep_logic.unify("_midy"..'#'..scID, (_dep_logic.substitute_vars('_y1'..'#'..scID, _logic_bindings_1)+_dep_logic.substitute_vars('_y2'..'#'..scID, _logic_bindings_1))/2, _logic_bindings_1) then return nil end;
if not _dep_logic.unify_many({'_table'..'#'..scID, '_midx'..'#'..scID, '_midy'..'#'..scID, '_rez'..'#'..scID}, Prolog:getXY(_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_midx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_midy'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
return {_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x1'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y1'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x2'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y2'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = GetInBetween_1(table, x1, y1, x2, y2, rez) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Piece:Jump(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local function Jump_1(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)+2, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)+2, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Jump_2(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)+2, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)-2, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Jump_3(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)-2, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)+2, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Jump_4(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)-2, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)-2, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {Jump_1,Jump_2,Jump_3,Jump_4,}, {x, y, newx, newy});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function Piece:Move(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local function Move_1(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)+1, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)+1, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Move_2(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)+1, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)-1, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Move_3(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)-1, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)+1, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local function Move_4(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify("_newx"..'#'..scID, _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1)-1, _logic_bindings_1) then
if _dep_logic.unify("_newy"..'#'..scID, _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1)-1, _logic_bindings_1) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {Move_1,Move_2,Move_3,Move_4,}, {x, y, newx, newy});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function Piece:Visited(x, y, visited)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
x, y, visited = _dep_logic.toList(x or "x", y or "y", visited or "visited");
end
local function Visited_1(x, y, visited)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, {head = { head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, tail = '_t'..'#'..scID}},
{x, y, visited}, {});
if not _logic_bindings_1 then return nil end;
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars({head = { head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, tail = '_t'..'#'..scID}, _logic_bindings_1)});

end
local function Visited_2(x, y, visited)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, {head = { head = '_a'..'#'..scID, tail = {head = '_b'..'#'..scID, tail = {}}}, tail = '_t'..'#'..scID}},
{x, y, visited}, {});
if not _logic_bindings_1 then return nil end;
local _logic_co_temp = coroutine.create(Prolog.equalPair);
local _logic_bindings_temp = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_temp, self,_dep_logic.substitute_vars({ head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, _logic_bindings_1), _dep_logic.substitute_vars({ head = '_a'..'#'..scID, tail = {head = '_b'..'#'..scID, tail = {}}}, _logic_bindings_1))
if not _dep_logic.unify_many({{ head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, { head = '_a'..'#'..scID, tail = {head = '_b'..'#'..scID, tail = {}}}}, temp_resume, _logic_bindings_1) then
_logic_bindings_1 = _logic_bindings_temp;
local _logic_co_2 = coroutine.create(Piece.Visited);
while coroutine.status(_logic_co_2) ~= "dead" do
local _logic_bindings_2 = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_2, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_t'..'#'..scID, _logic_bindings_2))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_t'..'#'..scID}, temp_resume, _logic_bindings_2) then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars({head = { head = '_a'..'#'..scID, tail = {head = '_b'..'#'..scID, tail = {}}}, tail = '_t'..'#'..scID}, _logic_bindings_2)});
 end end end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {Visited_1,Visited_2,}, {x, y, visited});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function Piece:TurnHelper(table, x, y, newx, newy, road, visited, index)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
table, x, y, newx, newy, road, visited, index = _dep_logic.toList(table or "table", x or "x", y or "y", newx or "newx", newy or "newy", road or "road", visited or "visited", index or "index");
end
local function TurnHelper_1(table, x, y, newx, newy, road, visited, index)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road'..'#'..scID, '_visited'..'#'..scID, '_index'..'#'..scID},
{table, x, y, newx, newy, road, visited, index}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.check(_dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_1), 1, '==') then
local _logic_co_2 = coroutine.create(Piece.Move);
while coroutine.status(_logic_co_2) ~= "dead" do
local _logic_bindings_2 = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_2, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_2))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_2) then
local _logic_co_3 = coroutine.create(self.DirectionByColor);
while coroutine.status(_logic_co_3) ~= "dead" do
local _logic_bindings_3 = _dep_utils.deepCopy(_logic_bindings_2);
_, temp_resume = coroutine.resume(_logic_co_3, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_3))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_3) then
local _logic_co_4 = coroutine.create(Piece.InBounds);
while coroutine.status(_logic_co_4) ~= "dead" do
local _logic_bindings_4 = _dep_utils.deepCopy(_logic_bindings_3);
_, temp_resume = coroutine.resume(_logic_co_4, self,_dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_4), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_4))
if _dep_logic.unify_many({'_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_4) then
local _logic_co_5 = coroutine.create(Piece.FreeSquare);
while coroutine.status(_logic_co_5) ~= "dead" do
local _logic_bindings_5 = _dep_utils.deepCopy(_logic_bindings_4);
_, temp_resume = coroutine.resume(_logic_co_5, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_5))
if _dep_logic.unify_many({'_table'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_5) then
if _dep_logic.unify('_road'..'#'..scID, {head = { head = '_newx'..'#'..scID, tail = {head = '_newy'..'#'..scID, tail = {}}}, tail = {}}, _logic_bindings_5) then
coroutine.yield({_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_road'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_visited'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_5)});
 end end end end end end end end end end
end
local function TurnHelper_2(table, x, y, newx, newy, road, visited, index)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road'..'#'..scID, '_visited'..'#'..scID, '_index'..'#'..scID},
{table, x, y, newx, newy, road, visited, index}, {});
if not _logic_bindings_1 then return nil end;
local _logic_co_2 = coroutine.create(Piece.Jump);
while coroutine.status(_logic_co_2) ~= "dead" do
local _logic_bindings_2 = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_2, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_2))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_2) then
local _logic_co_3 = coroutine.create(self.DirectionByColor);
while coroutine.status(_logic_co_3) ~= "dead" do
local _logic_bindings_3 = _dep_utils.deepCopy(_logic_bindings_2);
_, temp_resume = coroutine.resume(_logic_co_3, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_3))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_3) then
local _logic_co_4 = coroutine.create(Piece.InBounds);
while coroutine.status(_logic_co_4) ~= "dead" do
local _logic_bindings_4 = _dep_utils.deepCopy(_logic_bindings_3);
_, temp_resume = coroutine.resume(_logic_co_4, self,_dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_4), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_4))
if _dep_logic.unify_many({'_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_4) then
local _logic_co_5 = coroutine.create(Piece.FreeSquare);
while coroutine.status(_logic_co_5) ~= "dead" do
local _logic_bindings_5 = _dep_utils.deepCopy(_logic_bindings_4);
_, temp_resume = coroutine.resume(_logic_co_5, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_5))
if _dep_logic.unify_many({'_table'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID}, temp_resume, _logic_bindings_5) then
local _logic_co_temp = coroutine.create(Piece.Visited);
local _logic_bindings_temp = _dep_utils.deepCopy(_logic_bindings_5);
_, temp_resume = coroutine.resume(_logic_co_temp, self,_dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_visited'..'#'..scID, _logic_bindings_5))
if not _dep_logic.unify_many({'_newx'..'#'..scID, '_newy'..'#'..scID, '_visited'..'#'..scID}, temp_resume, _logic_bindings_5) then
_logic_bindings_5 = _logic_bindings_temp;
local _logic_co_6 = coroutine.create(Piece.GetInBetween);
while coroutine.status(_logic_co_6) ~= "dead" do
local _logic_bindings_6 = _dep_utils.deepCopy(_logic_bindings_5);
_, temp_resume = coroutine.resume(_logic_co_6, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_6))
if _dep_logic.unify_many({'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_color'..'#'..scID}, temp_resume, _logic_bindings_6) then
if _dep_logic.unify('_road'..'#'..scID, {head = { head = '_newx'..'#'..scID, tail = {head = '_newy'..'#'..scID, tail = {}}}, tail = {}}, _logic_bindings_6) then
local _logic_co_7 = coroutine.create(self.EnemyColor);
while coroutine.status(_logic_co_7) ~= "dead" do
local _logic_bindings_7 = _dep_utils.deepCopy(_logic_bindings_6);
_, temp_resume = coroutine.resume(_logic_co_7, self,_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_7))
if _dep_logic.unify_many({'_color'..'#'..scID}, temp_resume, _logic_bindings_7) then
coroutine.yield({_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_road'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_visited'..'#'..scID, _logic_bindings_7), _dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_7)});
 end end end end end end end end end end end end end end
end
local function TurnHelper_3(table, x, y, newx, newy, road, visited, index)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road'..'#'..scID, '_visited'..'#'..scID, '_index'..'#'..scID},
{table, x, y, newx, newy, road, visited, index}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.unify('_newVisited'..'#'..scID, {head = { head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, tail = '_visited'..'#'..scID}, _logic_bindings_1) then
local _logic_co_2 = coroutine.create(Piece.Jump);
while coroutine.status(_logic_co_2) ~= "dead" do
local _logic_bindings_2 = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_2, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_2))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID}, temp_resume, _logic_bindings_2) then
local _logic_co_temp = coroutine.create(Piece.Visited);
local _logic_bindings_temp = _dep_utils.deepCopy(_logic_bindings_2);
_, temp_resume = coroutine.resume(_logic_co_temp, self,_dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_visited'..'#'..scID, _logic_bindings_2))
if not _dep_logic.unify_many({'_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID, '_visited'..'#'..scID}, temp_resume, _logic_bindings_2) then
_logic_bindings_2 = _logic_bindings_temp;
local _logic_co_3 = coroutine.create(self.DirectionByColor);
while coroutine.status(_logic_co_3) ~= "dead" do
local _logic_bindings_3 = _dep_utils.deepCopy(_logic_bindings_2);
_, temp_resume = coroutine.resume(_logic_co_3, self,_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_3), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_3))
if _dep_logic.unify_many({'_x'..'#'..scID, '_y'..'#'..scID, '_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID}, temp_resume, _logic_bindings_3) then
local _logic_co_4 = coroutine.create(Piece.InBounds);
while coroutine.status(_logic_co_4) ~= "dead" do
local _logic_bindings_4 = _dep_utils.deepCopy(_logic_bindings_3);
_, temp_resume = coroutine.resume(_logic_co_4, self,_dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_4), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_4))
if _dep_logic.unify_many({'_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID}, temp_resume, _logic_bindings_4) then
local _logic_co_5 = coroutine.create(Piece.FreeSquare);
while coroutine.status(_logic_co_5) ~= "dead" do
local _logic_bindings_5 = _dep_utils.deepCopy(_logic_bindings_4);
_, temp_resume = coroutine.resume(_logic_co_5, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_5), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_5))
if _dep_logic.unify_many({'_table'..'#'..scID, '_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID}, temp_resume, _logic_bindings_5) then
local _logic_co_6 = coroutine.create(Piece.GetInBetween);
while coroutine.status(_logic_co_6) ~= "dead" do
local _logic_bindings_6 = _dep_utils.deepCopy(_logic_bindings_5);
_, temp_resume = coroutine.resume(_logic_co_6, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_6), _dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_6))
if _dep_logic.unify_many({'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID, '_color'..'#'..scID}, temp_resume, _logic_bindings_6) then
local _logic_co_7 = coroutine.create(self.EnemyColor);
while coroutine.status(_logic_co_7) ~= "dead" do
local _logic_bindings_7 = _dep_utils.deepCopy(_logic_bindings_6);
_, temp_resume = coroutine.resume(_logic_co_7, self,_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_7))
if _dep_logic.unify_many({'_color'..'#'..scID}, temp_resume, _logic_bindings_7) then
if _dep_logic.unify("_newIndex"..'#'..scID, _dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_7)+1, _logic_bindings_7) then
local _logic_co_8 = coroutine.create(Piece.TurnHelper);
while coroutine.status(_logic_co_8) ~= "dead" do
local _logic_bindings_8 = _dep_utils.deepCopy(_logic_bindings_7);
_, temp_resume = coroutine.resume(_logic_co_8, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_mid_newx'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_mid_newy'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_road_rec'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newVisited'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newIndex'..'#'..scID, _logic_bindings_8))
if _dep_logic.unify_many({'_table'..'#'..scID, '_mid_newx'..'#'..scID, '_mid_newy'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road_rec'..'#'..scID, '_newVisited'..'#'..scID, '_newIndex'..'#'..scID}, temp_resume, _logic_bindings_8) then
if _dep_logic.unify('_road'..'#'..scID, {head = { head = '_mid_newx'..'#'..scID, tail = {head = '_mid_newy'..'#'..scID, tail = {}}}, tail = '_road_rec'..'#'..scID}, _logic_bindings_8) then
coroutine.yield({_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_road'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_visited'..'#'..scID, _logic_bindings_8), _dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_8)});
 end end end end end end end end end end end end end end end end end end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {TurnHelper_1,TurnHelper_2,TurnHelper_3,}, {table, x, y, newx, newy, road, visited, index});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function Piece:Turn(table, x, y, newx, newy, road)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
table, x, y, newx, newy, road = _dep_logic.toList(table or "table", x or "x", y or "y", newx or "newx", newy or "newy", road or "road");
end
local function Turn_1(table, x, y, newx, newy, road)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road'..'#'..scID},
{table, x, y, newx, newy, road}, {});
if not _logic_bindings_1 then return nil end;
local _logic_co_2 = coroutine.create(Piece.TurnHelper);
while coroutine.status(_logic_co_2) ~= "dead" do
local _logic_bindings_2 = _dep_utils.deepCopy(_logic_bindings_1);
_, temp_resume = coroutine.resume(_logic_co_2, self,_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_road'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars({}, _logic_bindings_2), _dep_logic.substitute_vars(1, _logic_bindings_2))
if _dep_logic.unify_many({'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID, '_road'..'#'..scID, {}, 1}, temp_resume, _logic_bindings_2) then
coroutine.yield({_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_2), _dep_logic.substitute_vars('_road'..'#'..scID, _logic_bindings_2)});
 end end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {Turn_1,}, {table, x, y, newx, newy, road});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end

RedPiece = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "RedPiece";
setmetatable(RedPiece,_overload_meta);
RedPiece.constructor = {};
function RedPiece:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(RedPiece, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
RedPiece.constructor[#RedPiece.constructor+1] = function(self,x,y)
local posX,posY;
posX = x;
posY = y;
self.color = Red:new(1);
self = _dep_utils.deepCopyWithoutStatic(Piece, self)
Piece.constructor[2](self,posX,posY)
end
function RedPiece:draw()
local pair = Math2D:getSquareCenter(self.x,self.y);
Color:setColorELA(self.color);
love.graphics.circle('fill',pair.first,pair.second,Math2D.pieceRadius);
end
function RedPiece:DirectionByColor(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local function DirectionByColor_1(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.check(_dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), '<') then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {DirectionByColor_1,}, {x, y, newx, newy});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function RedPiece:EnemyColor(color)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
color = _dep_logic.toList(color or "color");
end
local function EnemyColor_1(color)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_color'..'#'..scID},
{color}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1), 1, '==') then return nil end;
return {_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = EnemyColor_1(color) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end

BlackPiece = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "BlackPiece";
setmetatable(BlackPiece,_overload_meta);
BlackPiece.constructor = {};
function BlackPiece:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(BlackPiece, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
BlackPiece.constructor[#BlackPiece.constructor+1] = function(self,x,y)
local posX,posY;
posX = x;
posY = y;
self.color = Black:new(1);
self = _dep_utils.deepCopyWithoutStatic(Piece, self)
Piece.constructor[2](self,posX,posY)
end
function BlackPiece:draw()
local pair = Math2D:getSquareCenter(self.x,self.y);
Color:setColorELA(self.color);
love.graphics.circle('fill',pair.first,pair.second,Math2D.pieceRadius);
end
function BlackPiece:DirectionByColor(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
local localDepth = _Logic_stack_depth;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local function DirectionByColor_1(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local temp_resume = nil;
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
if _dep_logic.check(_dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), '>') then
coroutine.yield({_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)});
 end
end
local _logic_run = coroutine.create(_dep_logic.run);
while coroutine.status(_logic_run) ~= "dead" do
local _, temp = coroutine.resume(_logic_run, {DirectionByColor_1,}, {x, y, newx, newy});
if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end
if temp then coroutine.yield(temp); end;
if localDepth == 1 then _Logic_stack_depth = 1 end
end
if localDepth == 1 then _Logic_stack_depth = 0 end

end
function BlackPiece:EnemyColor(color)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
color = _dep_logic.toList(color or "color");
end
local function EnemyColor_1(color)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_color'..'#'..scID},
{color}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1), 2, '==') then return nil end;
return {_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = EnemyColor_1(color) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end

CrownPiece = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "CrownPiece";
setmetatable(CrownPiece,_overload_meta);
CrownPiece.constructor = {};
function CrownPiece:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(CrownPiece, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
CrownPiece.constructor[#CrownPiece.constructor+1] = function(self,piece)
local posX,posY;
self.color = piece.color;
posX = piece.x;
posY = piece.y;
self = _dep_utils.deepCopyWithoutStatic(Piece, self)
Piece.constructor[2](self,posX,posY)
end
function CrownPiece:draw()
local pair = Math2D:getSquareCenter(self.x,self.y);
Color:setColorELA(self.color);
love.graphics.circle('fill',pair.first,pair.second,Math2D.pieceRadius);
Color:setColorELA(Gold:new(1));
love.graphics.circle('fill',pair.first,pair.second,Math2D.pieceRadius - 10);
end
function CrownPiece:DirectionByColor(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local function DirectionByColor_1(x, y, newx, newy)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_x'..'#'..scID, '_y'..'#'..scID, '_newx'..'#'..scID, '_newy'..'#'..scID},
{x, y, newx, newy}, {});
if not _logic_bindings_1 then return nil end;
return {_dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newx'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_newy'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = DirectionByColor_1(x, y, newx, newy) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function CrownPiece:EnemyColor(color)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
color = _dep_logic.toList(color or "color");
end
local function EnemyColor_1(color)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_color'..'#'..scID},
{color}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1), 0, '~=') then return nil end;
return {_dep_logic.substitute_vars('_color'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = EnemyColor_1(color) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end

BlankPiece = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "BlankPiece";
setmetatable(BlankPiece,_overload_meta);
BlankPiece.constructor = {};
function BlankPiece:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(BlankPiece, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
BlankPiece.constructor[#BlankPiece.constructor+1] = function(self)
local posX,posY;
posX = - 1;
posY = - 1;
self = _dep_utils.deepCopyWithoutStatic(Piece, self)
Piece.constructor[2](self,posX,posY)
end
function BlankPiece:draw()
end
function BlankPiece:DirectionByColor(x, y, newx, newy)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
x, y, newx, newy = _dep_logic.toList(x or "x", y or "y", newx or "newx", newy or "newy");
end
local _logic_ret_val = nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function BlankPiece:EnemyColor(color)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
color = _dep_logic.toList(color or "color");
end
local _logic_ret_val = nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end

DragAndDrop = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "DragAndDrop";
setmetatable(DragAndDrop,_overload_meta);
DragAndDrop.constructor = {};
function DragAndDrop:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(DragAndDrop, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
DragAndDrop.originalPosition = Pair:new(1,- 1,- 1);
DragAndDrop.currentPosition = Pair:new(1,- 1,- 1);
DragAndDrop.selectedPiece = BlankPiece:new(1);

