do
    local function permutations_2(List, Rez)
       local scID = _dep_logic.newScopeId()
       local _logic_bindings = _dep_logic.unify_many(
       {{head = '_H'..scID, tail = '_T'..scID}, {head = '_X'..scID, tail = '_Perm'..scID}},
       {List, Rez}, {});
       if not _logic_bindings then return nil end;
 
       local _logic_co_1 = coroutine.create(select);
       while coroutine.status(_logic_co_1) ~= "dead" do
          local _logic_bindings_1 = _logic_bindings;
          if not _dep_logic.unify_many({'_X'..scID, {head = '_H'..scID, tail = '_T'..scID}, '_Rest'..scID}, coroutine.resume(_logic_co_1, _dep_logic.substitute_vars('_X'..scID, _logic_bindings), _dep_logic.substitute_vars({head = '_H'..scID, tail = '_T'..scID}, _logic_bindings_1), _dep_logic.substitute_vars('_Rest'..scID, _logic_bindings_1)), _logic_bindings_1) then return nil end
          if not _dep_logic.unify_many({'_Rest'..scID, '_Perm'..scID}, permutations(_dep_logic.substitute_vars('_Rest'..scID, _logic_bindings), _dep_logic.substitute_vars('_Perm'..scID, _logic_bindings)), _logic_bindings) then return nil end
       end
       return {_dep_logic.substitute_vars({head = '_H'..scID, tail = '_T'..scID}, _logic_bindings), _dep_logic.substitute_vars({head = '_X'..scID, tail = '_Perm'..scID}, _logic_bindings)};
    end
 
    local _logic_run = coroutine.create(_dep_logic.run);
    while coroutine.status(_logic_run) ~= "dead" do
       coroutine.yield(coroutine.resume(_logic_run, {permutations_1, permutations_2}, {List, Rez}));
    end
    _Logic_stack_depth = _Logic_stack_depth - 1;
    --if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;
    --return _logic_ret_val;
 end
 