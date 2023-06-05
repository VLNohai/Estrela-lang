local _dep_linkedlist = require("deps.linkedlist");
local _dep_overload = require("deps.overload");
local _dep_types = require("deps.types");
local _dep_utils = require("deps.utils");
local _dep_logic = require("deps.logic");
local _dep_cast = require("deps.cast");
local _dep_defaults = require("deps.defaults");
local _dep_globals = require("deps.globals");
--end of dependencies
Prolog = {}
local _overload_meta = _dep_overload.getMeta();
_overload_meta.typename = "Prolog";
setmetatable(Prolog,_overload_meta);
Prolog.constructor = {};
function Prolog:new(constructor, ...)
local new;
new = _dep_utils.deepCopyWithoutStatic(Prolog, new);
setmetatable(new, getmetatable(self))
new.constructor[constructor](new, ...);new.constructor = nil;
new.new = nil;
return new
end;
function Prolog:getnhelp(index, table, n, rez)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
index, table, n, rez = _dep_logic.toList(index or "index", table or "table", n or "n", rez or "rez");
end
local function getnhelp_1(index, table, n, rez)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_n'..'#'..scID, {head = '_h'..'#'..scID, tail = '_t'..'#'..scID}, '_n'..'#'..scID, '_h'..'#'..scID},
{index, table, n, rez}, {});
if not _logic_bindings_1 then return nil end;
return {_dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars({head = '_h'..'#'..scID, tail = '_t'..'#'..scID}, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_h'..'#'..scID, _logic_bindings_1)};

end
local function getnhelp_2(index, table, n, rez)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_index'..'#'..scID, {head = '_h'..'#'..scID, tail = '_t'..'#'..scID}, '_n'..'#'..scID, '_rez'..'#'..scID},
{index, table, n, rez}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.check(_dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), '<') then return nil end;
if not _dep_logic.unify("_new_index"..'#'..scID, _dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_1)+1, _logic_bindings_1) then return nil end;
if not _dep_logic.unify_many({'_new_index'..'#'..scID, '_t'..'#'..scID, '_n'..'#'..scID, '_rez'..'#'..scID}, Prolog:getnhelp(_dep_logic.substitute_vars('_new_index'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_t'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
return {_dep_logic.substitute_vars('_index'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars({head = '_h'..'#'..scID, tail = '_t'..'#'..scID}, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = getnhelp_1(index, table, n, rez) or getnhelp_2(index, table, n, rez) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Prolog:getn(table, n, rez)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
table, n, rez = _dep_logic.toList(table or "table", n or "n", rez or "rez");
end
local function getn_1(table, n, rez)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_n'..'#'..scID, '_rez'..'#'..scID},
{table, n, rez}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.unify_many({1, '_table'..'#'..scID, '_n'..'#'..scID, '_rez'..'#'..scID}, Prolog:getnhelp(_dep_logic.substitute_vars(1, _logic_bindings_1), _dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
return {_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_n'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = getn_1(table, n, rez) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Prolog:getXY(table, x, y, rez)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
table, x, y, rez = _dep_logic.toList(table or "table", x or "x", y or "y", rez or "rez");
end
local function getXY_1(table, x, y, rez)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{'_table'..'#'..scID, '_x'..'#'..scID, '_y'..'#'..scID, '_rez'..'#'..scID},
{table, x, y, rez}, {});
if not _logic_bindings_1 then return nil end;
if not _dep_logic.unify_many({'_table'..'#'..scID, '_y'..'#'..scID, '_rez_rec'..'#'..scID}, Prolog:getn(_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez_rec'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
if not _dep_logic.unify_many({'_rez_rec'..'#'..scID, '_x'..'#'..scID, '_rez'..'#'..scID}, Prolog:getn(_dep_logic.substitute_vars('_rez_rec'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
return {_dep_logic.substitute_vars('_table'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_x'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_y'..'#'..scID, _logic_bindings_1), _dep_logic.substitute_vars('_rez'..'#'..scID, _logic_bindings_1)};

end
local _logic_ret_val = getXY_1(table, x, y, rez) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end
function Prolog:equalPair(a, b)
_Logic_stack_depth = _Logic_stack_depth + 1;
if _Logic_stack_depth == 1 then
a, b = _dep_logic.toList(a or "a", b or "b");
end
local function equalPair_1(a, b)
local scID = _dep_logic.newScopeId()
local _logic_bindings_1 = _dep_logic.unify_many(
{{ head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, { head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}},
{a, b}, {});
if not _logic_bindings_1 then return nil end;
return {_dep_logic.substitute_vars({ head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, _logic_bindings_1), _dep_logic.substitute_vars({ head = '_x'..'#'..scID, tail = {head = '_y'..'#'..scID, tail = {}}}, _logic_bindings_1)};

end
local _logic_ret_val = equalPair_1(a, b) or nil;
_Logic_stack_depth = _Logic_stack_depth - 1;
if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end
return _logic_ret_val;

end

