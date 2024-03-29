local NodeType = require('tokens').NodeType;
local TokenType = require('tokens').TokenType;
local utils = require('utils');
local mapTokensToFields = require('metatableOps');
local Generator = {};
local OutputFile = nil;
local depsPath;

-----------------------BLOCK---------------------

local statRouter;
local generateExplist;
local function generateBlock(ast)
    local code = '';
    if not ast then return '\n' end;
    for index, stat in ipairs(ast.stats) do
        if statRouter[stat.node] then
            local temp = statRouter[stat.node](stat) .. '\n';
            code = code .. temp;
        end
    end
    if ast.retstat.expressions then
        code = code .. 'return ' .. generateExplist(ast.retstat.expressions) .. ';\n';
    end
    return code;
end

-------------------------------------------------LOGIC GENERATION BLOCK-------------------------------------------------------------

local scopePrefixString = "..'#'..scID";
local bind_depth = 1;
local is_block_unique = false;

local function writeFunction(is_local, name, args, body_as_string, memberOf)
    local code = '';
    if not memberOf then memberOf = '' else memberOf = memberOf .. ':' end;
    if is_local then
        code = code .. 'local ';
    end
    code = code .. 'function ' .. memberOf .. name .. '(';
    if #args > 0 then
        code = code .. args[1];
        for index, arg in ipairs(utils.remove_first_n(args, 1)) do
            code = code .. ', ' .. arg;
        end
    end
    code = code ..')\n' .. body_as_string .. '\n' .. 'end\n';
    return code;
end

local function loadDependency(dependencies, fileCode, name, onMainFile)
    if not dependencies[name] then
        if onMainFile then
            fileCode = 'local _dep_' .. name .. ' = require("deps.' .. name  .. '");\n' .. fileCode; 
        end
        local src = io.open('prefabs/' .. name .. '.lua');
        if src then
            local content = src:read("*all");
            local dest = io.open(depsPath .. '/' .. name .. '.lua', 'wb');
            if dest then
                dest:write(content);
                dest:close();  
            end
        end
        dependencies[name] = true;
    end
    return fileCode;
end

local function fromLogicNodeToTable(node)
    local code = '';
    if not node then
        return 'nil';
    end
    if node.node == NodeType.LOGIC_TABLE_NODE then
        code = code .. '{';
        local head = fromLogicNodeToTable((node.head or {})[#(node.head or {})]);
        local tail = fromLogicNodeToTable(node.tail);
        if head ~= 'nil' and tail == 'nil' then
            tail = '{}';
        end

        if head ~= 'nil' or tail ~= 'nil' then
            code = code .. 'head = ' .. head .. ', tail = ' .. tail;
        end
        if node.head and #node.head > 1 then
            for i=#node.head - 1, 1, -1 do
                code = '{ head = ' .. fromLogicNodeToTable(node.head[i]) .. ', tail = ' .. code .. '}';
            end
        end
        code = code .. '}';
    elseif node.node == NodeType.VALUE_NODE then
        code = node.value;
    elseif node.node == NodeType.LOGIC_IDENTIFIER_NODE then
        code = "'_" .. node.id .. "'" .. scopePrefixString;
    end
    return code;
end

local function resolveFuncArgs(func_args, ret_by_binding)
    local code = '';
    for index, arg in ipairs(func_args) do
        local left, right = '', '';
        if ret_by_binding then
            left, right = '_dep_logic.substituteAtoms(', ', _logic_bindings_' .. bind_depth .. ')';
        end
        code = code .. left .. fromLogicNodeToTable(arg) .. right ..', ';
    end
    code = string.sub(code, 1, -3);
    return code;
end

local function handleLogicArgs(block_args, func_args)
    local checkItBinded = 'if not _logic_bindings_' .. bind_depth;
    if is_block_unique then
        checkItBinded = checkItBinded .. ' then return nil end;'
    else
        checkItBinded = checkItBinded .. ' then return nil end;'
    end
    local header = '';
    local footer = '';
    if not is_block_unique then
        header = header .. 'local temp_resume = nil;\n';
    end
    header = header .. 'local _logic_bindings_1 = ';
    header = header .. '_dep_logic.unify_many(\n{' .. resolveFuncArgs(func_args)  .. '},\n';
    header = header .. '{' .. utils.listOfIdsToCommaString(block_args) .. '}';
    header = header .. ', {});\n';
    header = header .. checkItBinded .. '\n';

    return header, footer;
end

local function resolveToNumber(value)
    local code = '';
    if value.node == NodeType.LOGIC_IDENTIFIER_NODE then
        code = '_dep_logic.substituteAtoms(' .. "'_" .. value.id .. "'" .. scopePrefixString .. ', _logic_bindings_' .. bind_depth .. ')';
    else
        code = code .. value.value;
    end
    return code;
end

local function fromTokenToStringOps(token)
    if token == TokenType.PLUS_OPERATOR then
        return '+';
    elseif token == TokenType.MINUS_OPERATOR then
        return '-'
    elseif token == TokenType.STAR_OPERATOR then
        return '*'
    elseif token == TokenType.SLASH_OPERATOR then
        return '/'
    elseif token == TokenType.PERCENT_OPERATOR then
        return '%'
    elseif token == TokenType.EQUALS_OPERATOR then
        return '=='
    elseif token == TokenType.NOT_EQUALS_OPERATOR then
        return '~='
    elseif token == TokenType.MORE_OPERATOR then
        return '>'
    elseif token == TokenType.LESS_OPERATOR then
        return '<'
    elseif token == TokenType.MORE_OR_EQUAL_OPERATOR then
        return '>='
    elseif token == TokenType.LESS_OR_EQUAL_OPERATOR then
        return '<='
    end
end

local function spreadExp(exp)
    local code = '';
    if exp.paranExp then
        code = code .. "(" .. spreadExp(exp.innerExp) .. ")";
    else
        code = code .. resolveToNumber(exp.value);
    end
    while exp.exp do
        code = code .. fromTokenToStringOps(exp.binop);
        exp = exp.exp;
        if exp.value then
            code = code .. resolveToNumber(exp.value);
        else
            code = code .. "(" .. spreadExp(exp.innerExp) .. ")";
        end
    end
    return code;
end

local generateVar;
local function handleLogicStats(stats, containing_func_args)
    local code = '';
    local invalidate_stat = '';
    local endsToClose = 0;
    for index, stat in ipairs(stats) do
        --update the invalidation sequence
        local invalidate_stat = 'then return nil end;\n';
        if stat.node == NodeType.LOGIC_CHECK_NODE then
            if is_block_unique then
                code = code .. 'if not _dep_logic.check(' .. spreadExp(stat.left) .. ', ' .. spreadExp(stat.right) .. ", '" .. fromTokenToStringOps(stat.check) .. "'" .. ') ' .. invalidate_stat;
            else
                code = code .. 'if _dep_logic.check(' .. spreadExp(stat.left) .. ', ' .. spreadExp(stat.right) .. ", '" .. fromTokenToStringOps(stat.check) .. "'" .. ') then\n';
                endsToClose = endsToClose + 1;
            end
        elseif stat.node == NodeType.LOGIC_UNIFY_NODE then
            if is_block_unique then
                code = code .. 'if not _dep_logic.unify(' .. fromLogicNodeToTable(stat.left) .. ', ' .. fromLogicNodeToTable(stat.right)  .. ', _logic_bindings_' .. bind_depth .. ')' .. invalidate_stat;
            else
                code = code .. 'if _dep_logic.unify(' .. fromLogicNodeToTable(stat.left) .. ', ' .. fromLogicNodeToTable(stat.right)  .. ', _logic_bindings_' .. bind_depth .. ') then\n';
                endsToClose = endsToClose + 1;
            end
        elseif stat.node == NodeType.LOGIC_FUNCTION_CALL_NODE then
            if stat.replaceWith then
                stat.id = generateVar(stat.replaceWith);
            end
            if stat.is_inbuilt then
                if stat.shouldBeSelf then
                    stat.id = stat.id:gsub("(.*)%.(.*)", "%1:%2");
                end
                if is_block_unique then
                    code = code .. 'if not _dep_logic.' .. stat.id .. '(' .. resolveFuncArgs(stat.args) .. ', _logic_bindings_' .. bind_depth .. ') ' ..  invalidate_stat;
                else
                    code = code .. 'if _dep_logic.' .. stat.id .. '(' .. resolveFuncArgs(stat.args) .. ', _logic_bindings_' .. bind_depth .. ') then\n';
                    endsToClose = endsToClose + 1;
                end
            else
                if is_block_unique then
                    if stat.shouldBeSelf then
                        stat.id = stat.id:gsub("(.*)%.(.*)", "%1:%2");
                    end
                    if stat.modifier == 'not' then
                        code = code .. 'local _logic_bindings_temp = _logic_bindings_' .. bind_depth .. ';\n';
                        code = code .. 'if _dep_logic.unify_many({' .. resolveFuncArgs(stat.args) .. '}, ' .. stat.id .. '(' .. resolveFuncArgs(stat.args, true)  .. ')' .. ', _logic_bindings_' .. bind_depth .. ') then return nil end\n';
                        code = code .. '_logic_bindings_' .. bind_depth .. ' = _logic_bindings_temp;\n';
                    else
                        code = code .. 'if not _dep_logic.unify_many({' .. resolveFuncArgs(stat.args) .. '}, ' .. stat.id .. '(' .. resolveFuncArgs(stat.args, true)  .. ')' .. ', _logic_bindings_' .. bind_depth .. ') then return nil end\n';
                    end
                else
                    local selfArg = ''
                    if stat.shouldBeSelf then
                        selfArg = 'self,'
                    end
                    if stat.modifier == 'not' then
                        code = code .. 'local _logic_co_temp = coroutine.create(' .. stat.id .. ');\n';
                        code = code .. 'local _logic_bindings_temp = _dep_utils.deepCopy(_logic_bindings_' .. bind_depth .. ');\n'
                        code = code .. '_, temp_resume = ' .. 'coroutine.resume' .. '(_logic_co_temp, ' .. selfArg .. resolveFuncArgs(stat.args, true)  .. ')\n';
                        code = code .. 'if not _dep_logic.unify_many({' .. resolveFuncArgs(stat.args) .. '}, temp_resume, _logic_bindings_' .. bind_depth .. ') then\n';
                        code = code .. '_logic_bindings_' .. bind_depth .. ' = _logic_bindings_temp;\n';
                        endsToClose = endsToClose + 1;
                    else
                        bind_depth = bind_depth + 1;
                        code = code .. 'local _logic_co_' .. bind_depth .. ' = coroutine.create(' .. stat.id .. ');\n';
                        code = code .. 'while coroutine.status(_logic_co_' .. bind_depth .. ') ~= "dead" do\n'
                        code = code .. 'local _logic_bindings_' .. bind_depth .. ' = _dep_utils.deepCopy(_logic_bindings_' .. (bind_depth - 1) .. ');\n'
                        code = code .. '_, temp_resume = ' .. 'coroutine.resume' .. '(_logic_co_' .. bind_depth .. ', ' .. selfArg .. resolveFuncArgs(stat.args, true)  .. ')\n';
                        code = code .. 'if _dep_logic.unify_many({' .. resolveFuncArgs(stat.args) .. '}, temp_resume, _logic_bindings_' .. bind_depth .. ') then\n';
                    end
                end
            end
        elseif stat.node == NodeType.LOGIC_ASSIGN_NODE then
            if is_block_unique then
                code = code .. 'if not _dep_logic.unify("_' .. stat.left  .. '"' .. scopePrefixString .. ', ' .. spreadExp(stat.right)  .. ', _logic_bindings_' .. bind_depth .. ') ' .. invalidate_stat;
            else
                code = code .. 'if _dep_logic.unify("_' .. stat.left  .. '"' .. scopePrefixString .. ', ' .. spreadExp(stat.right)  .. ', _logic_bindings_' .. bind_depth .. ') then\n';
                endsToClose = endsToClose + 1;
            end
        end
    end
    if is_block_unique then
        code = code ..  'return {' .. resolveFuncArgs(containing_func_args, true) .. '};\n';
    else
        code = code .. 'coroutine.yield({' .. resolveFuncArgs(containing_func_args, true) .. '});\n';
        for i=bind_depth, 2, -1 do
            code = code .. ' end end';
        end
        for i=1, endsToClose do
            code = code .. ' end';
        end
        bind_depth = 1;    
    end
    return code;
end

local function tablesToLogicLists(args, id)
    local code = '';
    code = code .. 'if _Logic_stack_depth == 1 then\n';
    code = code .. utils.listOfIdsToCommaString(args) .. ' = _dep_logic.toList(' ..utils.listOfIdsToCommaString(args, true)  .. ');\n';
    code = code .. 'end\n';
    return code;
end

-------------------------------------------------ASSIGNMENT NODE-------------------------------------------------------------

local currentThisIndex = '';

local function generateName(name)
    return name.id;
end

local function generateNamelist(namelist, classId)
    local code = '';
    if not classId then classId = '' else classId = classId .. '.' end
    for index, name in ipairs(namelist) do
        code = code .. classId .. generateName(name);
        if index < #namelist then
            code = code .. ',';
        end
    end
    return code;
end

local function generateArgs(args)
    local code = '';
    code = code .. '(' .. generateExplist(args) .. ')';
    return code;
end

local function generateCall(call)
    local code = '';
    if call then
        if call.node == NodeType.CALL_NODE then
            code = code .. generateArgs(call.args);
        elseif call.node == NodeType.SELF_CALL_NODE then
            code = code .. ':' .. code .. call.id .. generateArgs(call.args);
        end
    end
    return code;
end

local generateExp;
local function generateSuffix(suffixList, isValue)
    local code = '';
    local nilSafeChecks = {};
    for index, suffix in ipairs(suffixList) do
        if suffix.node == NodeType.POINT_INDEX_NODE then
            code = code .. '.' .. suffix.id;
        elseif suffix.node == NodeType.BRACKET_INDEX_NODE then
            local ending = '';
            if isValue and suffix.nilSafe then
                nilSafeChecks[#nilSafeChecks+1] = suffix.nilSafe;
                ending = ')';
            end
            code = code .. '[' .. generateExp(suffix.val) .. ']' .. ending;
        elseif suffix.node == NodeType.CALL_NODE then
            code = code .. generateCall(suffix.call);
        end
    end
    return code, nilSafeChecks;
end

local function generatePrefix(var)
    local code = '';
    if type(var) == 'string' then
        return var;
    end
    if type(var.prefix) == "string" then
        code = code .. var.prefix;
    else
        if var.prefix and var.prefix.exp then
            code = code .. '(' .. generateExp(var.prefix.exp)  .. ')'; 
        end
    end
    return code;
end

local function generateNilSafeChecks(checks)
    local code = '';
    checks = utils.reverse(checks);
    for index, check in ipairs(checks) do
        local localDefault = '_default_' .. string.gsub(check, "|", "_of_")
        code = code .. '_dep_defaults.safe("' .. string.gsub(check, "|", "_of_") .. '",' .. localDefault .. ',';
    end
    return code;
end

generateVar = function(var, isValue)
    local code = '';
    local thisCode = '';
    if var.isThis then
        thisCode = currentThisIndex;
    end
    if var.id then
        code = code .. thisCode;
        code = code .. var.id;
    else
        local tempCode, checks = generateSuffix(var.suffix, isValue);
        if isValue then code = code .. generateNilSafeChecks(checks) end;
        code = code .. thisCode;
        code = code .. generatePrefix(var);
        code = code .. tempCode;
        code = code .. generateCall(var.call);
    end
    return code;
end

local function generateField(field)
    local code = '';
    if field.node == NodeType.BRACKET_INDEX_NODE then
        return '[' .. generateExp(field.index) .. '] = ' .. generateExp(field.exp);
    elseif field.node == NodeType.NAME_ASSIGNMENT_NODE then
        return generateName(field.left) .. '=' .. generateExp(field.right);
    elseif field.node == NodeType.EXP_WRAPPER_NODE then
        return generateExp(field.exp);
    end
    return code;
end

local function generateFieldList(filedlist)
    local code = '';
    for index, field in ipairs(filedlist) do
        code = code .. generateField(field) .. ';';
    end
    return code;
end

local function generateTableConst(tableConst)
    local code = '{';
    if tableConst.fieldlist then
        code =  code .. generateFieldList(tableConst.fieldlist);
    end
    code = code .. '}';
    return code;
end

local generateFuncbody;
local function generateLambdaFunc(lmd)
    local code = 'function';
    code = code .. generateFuncbody(lmd);
    return code;
end

local generateFunctioncall;
local function generateValue(value)
    local code = '';
    if value.valType == 'var' then
        return generateVar(value.value, true);
    elseif value.node == NodeType.UNOP_EXP_NODE then
        return code .. value.op.value .. ' ' .. generateValue(value.value);
    elseif value.node == NodeType.CAST_NODE or value.node == NodeType.CAST_CHECK_NODE then
        if not value.safety then
            return generateExp(value.exp);
        elseif value.safety == 'check' then
            return '_dep_defaults.safe("' .. string.gsub(value.castTo, "|", "_of_")  .. '",' .. '_default_' .. string.gsub(value.castTo, "|", "_of_") .. ',_dep_cast.cast(' .. generateExp(value.exp) .. ',"' .. string.gsub(value.castTo, "|", "_of_") .. '"))';
        elseif value.safety == 'deepcopy' then
            return '_dep_utils.deepCopy(' .. generateExp(value.exp) .. ')';
        elseif value.safety == 'validate' then
            return '_dep_cast.validate(' .. generateExp(value.exp) .. ',"' .. string.gsub(value.castTo, "|", "_of_") .. '")';
        else
            print('cast safety level not implemented');
        end
    elseif value.valType == 'functioncall' then
        return generateFunctioncall(value.value);
    elseif value.type == 'boolean' or 
           value.type == 'number'
    then
        return value.value;
    elseif value.type == 'nil' then
            return 'nil';
    elseif value.type == 'string' then
        return "'" .. value.value .. "'";
    elseif value.type == 'triplePoint' then
        return '...';
    elseif value.type == 'table' then
        return generateTableConst(value.value);
    elseif value.node == NodeType.PARAN_EXP_NODE then
        return '(' .. generateExp(value.exp) .. ')';
    elseif value.node == NodeType.INSTANTIATION_NODE  then
        code =  value.id .. ':' .. 'new(' .. value.indexOfMatch
        if #value.args > 0 then code = code .. ',' .. generateExplist(value.args); end
        code = code .. ')';
    end
    return code;
end

generateExp = function(exp)
    local code = '';
    if exp.node == NodeType.EVALUABLE_NODE then
        code = code .. generateValue(exp.exp);
        if exp.op then
            if exp.op.node == NodeType.BINEXP_NODE then
                code = code .. ' ' .. exp.op.binop.value .. ' ' .. generateExp(exp.op.term);
            else
                code = exp.op.value .. ' ' .. code;
            end
        end
    elseif exp.node == NodeType.LAMBDA_FUNC_NODE then
        return generateLambdaFunc(exp.body);
    elseif exp.node == NodeType.DEFAULT_PLACEHOLDER_NODE then
        return '(_default_' .. string.gsub(exp.type, "|", "_of_") .. ' or _dep_defaults.get("' .. string.gsub(exp.type, "|", "_of_") .. '"))';
    end
    return code;
end

local function generateVarlist(varlist)
    local code = '';
    for index, var in ipairs(varlist) do
        code = code .. generateVar(var);
        if index < #varlist then
            code = code .. ',';
        end
    end
    return code;
end

generateExplist = function(explist)
    local code = '';
    for index, exp in ipairs(explist) do
        if exp.safety == 'deepcopy' then
            code = code .. '_dep_utils.deepCopy(' .. generateExp(exp) .. ')';
        else
            code = code .. generateExp(exp);
        end
        if index < #explist then
            code = code .. ',';
        end
    end
    return code;
end

generateFunctioncall = function(functioncall)
    local code = '';
    if functioncall.isRequire then
        return 'require(' .. '"' .. functioncall.call.args[1].exp.value .. '"' .. ')';
    end
    if functioncall.isThis then
        code = currentThisIndex;
    end
    code = code .. generatePrefix(functioncall.prefix);
    code = code .. generateSuffix(functioncall.suffix);
    code = code .. generateCall(functioncall.call);
    return code;
end

local function generateFuncname(funcname)
    local code = '';
    for index, name in ipairs(funcname) do
        if index < #funcname then
            if index > 1 then
                code = code .. '.';
            end 
            code = code .. name;
        end
    end
    if #funcname > 1 then
        if funcname.isSelf then
            code = code .. ':' .. funcname[#funcname];
        else
            code = code .. '.' .. funcname[#funcname];
        end
    else
        code = code .. funcname[1];
    end
    return code;
end

local function generateParlist(parlist)
    local code = generateNamelist(parlist.namelist);
    if parlist.isTriple then
        code = code .. ', ...';
    end
    return code;
end

generateFuncbody = function (funcbody)
    local code = '(';
    if funcbody.parlist.namelist then
        code = code .. generateParlist(funcbody.parlist);
    end
    code = code .. ')\n' .. generateBlock(funcbody.block) .. 'end';
    return code;
end

local function generateLogicBlock(block, memberOf)
    local localCode = '';
    --BODY
    local bodyCode = '';
    local funcList = '';
    is_block_unique = block.is_unique;
    bodyCode = bodyCode .. tablesToLogicLists(block.args, block.id);
    local funcIndex = 1;
    for index, func in ipairs(block.funcs) do
        if func.node == NodeType.LOGIC_PREDICATE_NODE then
            local header, footer = handleLogicArgs(block.args, func.args);
            local func_id = block.id .. '_' .. funcIndex;
            funcIndex = funcIndex + 1;
            funcList = funcList .. func_id .. ',';
            bodyCode = bodyCode .. writeFunction(true, (func_id), utils.extractField(block.args, 'id'),
            'local scID = _dep_logic.newScopeId()\n' 
            .. header .. handleLogicStats(func.stats, func.args) .. footer
            );
        end
    end
    --YIELDING THE RESULTS
    if not is_block_unique then
        bodyCode = 'local localDepth = _Logic_stack_depth;\n' .. bodyCode;
    end
    bodyCode = '_Logic_stack_depth = _Logic_stack_depth + 1;\n' .. bodyCode;

    if is_block_unique then
        bodyCode = bodyCode .. 'local _logic_ret_val = '
        for index = 1, funcIndex - 1, 1 do
            bodyCode = bodyCode .. block.id .. '_' .. index .. '(' .. utils.listOfIdsToCommaString(block.args) .. ')' .. ' or ';
        end
            bodyCode = bodyCode .. 'nil;\n';
            bodyCode = bodyCode .. '_Logic_stack_depth = _Logic_stack_depth - 1;\n'
            bodyCode = bodyCode .. 'if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;\n'
            bodyCode = bodyCode .. 'if _Logic_stack_depth == 0 then _dep_logic.listOfListsToArray(_logic_ret_val) end\n'
            bodyCode = bodyCode .. 'return _logic_ret_val;\n';
    else
            bodyCode = bodyCode .. 'local _logic_run = coroutine.create(_dep_logic.run);\n';
            bodyCode = bodyCode .. 'while coroutine.status(_logic_run) ~= "dead" do\n';
            bodyCode = bodyCode .. 'local _, temp = coroutine.resume(_logic_run, {' .. funcList .. '}, {' .. utils.listOfIdsToCommaString(block.args)  .. '});\n';
            bodyCode = bodyCode .. 'if localDepth == 1 then _dep_logic.listOfListsToArray(temp) _Logic_stack_depth = 0 end\n'
            bodyCode = bodyCode .. 'if temp then coroutine.yield(temp); end;\n'
            bodyCode = bodyCode .. 'if localDepth == 1 then _Logic_stack_depth = 1 end\n';
            bodyCode = bodyCode .. 'end\n';
            bodyCode = bodyCode .. 'if localDepth == 1 then _Logic_stack_depth = 0 end\n';
    end

    --SIGNATURE
    localCode = localCode .. writeFunction(block.isLocal, block.id, utils.extractField(block.args, 'id'), bodyCode, memberOf);

    return localCode;
end

local function generateInstantiationFunc(classDeclaration)
    local code = '';
    code = code .. 'function ' .. classDeclaration.id .. ':new(constructor, ...)\n'
    code = code .. 'local new;\n';
    code = code .. 'new = _dep_utils.deepCopyWithoutStatic(' .. classDeclaration.id .. ', new);\n';
    code = code .. 'setmetatable(new, getmetatable(self))\n';
    code = code .. 'new.constructor[constructor](new, ...);';
    code = code .. 'new.constructor = nil;\n';
    code = code .. 'new.new = nil;\n';
    code = code .. 'return new\n';
    code = code .. 'end;\n';
    return code;
end

local function inheritInConstructor(baseId, baseArgs, ihtCstIndex)
    local code = '';
    code = code .. 'self = _dep_utils.deepCopyWithoutStatic(' .. baseId .. ', self)\n';
    code = code .. baseId .. '.constructor[' .. ihtCstIndex .. ']' .. '(self';
    if #baseArgs > 0 then
        code = code .. ',' .. generateNamelist(baseArgs);
    end
    code = code .. ')\n';
    return code;
end

local function generateClassStats(classId, stats, baseId, baseArgs, ihtCstIndex)
    local code = '';
    for index, stat in ipairs(stats) do
        if stat.node == NodeType.MEMBER_FUNCTION_NODE then
                code = code .. 'function ' .. classId .. ':' .. stat.id .. generateFuncbody(stat.body) .. '\n';
        elseif stat.node == NodeType.CONSTRUCTOR_NODE then
            code = code .. classId ..  '.constructor[#' .. classId .. '.constructor+1] = function(self';
            if stat.body.parlist.namelist then
                code = code .. ',' .. generateNamelist(stat.body.parlist.namelist);
            end
            code = code .. ')\n';
            if baseId then
                if #baseArgs > 0 then
                    code = code .. 'local ' .. generateNamelist(baseArgs) .. ';\n';
                end
            end
            code = code .. generateBlock(stat.body.block); 
            if baseId then
                code = code .. inheritInConstructor(baseId, baseArgs, ihtCstIndex);
            end
            code = code .. 'end\n';
        elseif stat.node == NodeType.LOGIC_BLOCK_NODE then
            stat.isLocal = false;
            code = code .. generateLogicBlock(stat, classId);
        elseif stat.node == NodeType.CLASS_FIELD_DECLARATION_NODE then
            code = code .. generateNamelist(stat.left, classId);
            code = code .. ' = ';
            if stat.right then
                code = code .. generateExplist(stat.right);
                if #stat.right < #stat.left then code = code .. ',' end
            end
            local start = #(stat.right or {}) + 1;
            for i=start, #stat.left, 1 do
                code = code .. 'nil';
                if i < #stat.left then code = code .. ',' end;
            end
            
            code = code .. ';\n';
        end
    end
    return code;
end

local function generateDefaultSet(defaultSet)
    local code = '';
    if not defaultSet.isLocal then
        code = code .. '_dep_defaults.set(';
        code = code .. '"' .. string.gsub(defaultSet.type, "|", "_of_") .. '",' .. generateExp(defaultSet.exp);
        code = code .. ');\n';
    else
        code = code .. 'local _default_' .. string.gsub(defaultSet.type, "|", "_of_")  .. ' = ' .. generateExp(defaultSet.exp);
    end
    return code;
end

local function saveTypesToCastFile(declaredTypes)
    local outputFile = io.open('prefabs/types.lua', "w")
    local code = 'local types = {\n';
    for classId, classInfo in pairs(declaredTypes) do
        code = code .. '["' .. classId .. '"]' .. ' = {\n'; 
        for name, value in pairs(classInfo.castTo) do
            code = code .. '["' .. name .. '"] = true;\n';
        end
        code = code .. '};\n'
    end
    local code = code .. '\n}\nreturn types;';
    if outputFile then
        outputFile:write(code); 
        outputFile:close();
    end
end

local function generateOverloadFunc(overload, declaredTypes)
    local code = '_dep_overload.addOperator(';
    code = code .. overload.type1 .. ',';
    if overload.type2 then
        if declaredTypes[overload.type2] then
            code = code .. overload.type2 .. ',';
        else
            code = code .. '"' .. overload.type2 .. '",';
        end
    else
        code = code .. 'nil,';
    end
    code = code .. '"' .. mapTokensToFields[overload.op] .. '",';
    code = code .. 'function(' .. generateParlist(overload.body.parlist) .. ')\n'
    code = code .. generateBlock(overload.body.block);
    code = code .. 'end);';
    return code;
end

function Generator.generate(ast, linkResult, mainFilePath, filename, isMainFile)
    local fileCode = "--end of dependencies\n";
    local dependencies = {};
    if isMainFile then
        saveTypesToCastFile(linkResult.types);
    end

    --HANDLE FILES
    if mainFilePath then mainFilePath = mainFilePath .. '/' else mainFilePath = '' end;
    local command = 'mkdir "' .. (mainFilePath or '') .. 'build' .. '" 2>nul'
    local handle = io.popen(command)
    if handle then
        handle:close();
    end
    OutputFile = io.open(mainFilePath ..  'build/' .. filename .. '.lua', 'w');

    os.execute('mkdir "' .. mainFilePath ..  '/build/deps' .. '" > nul 2>&1')
    depsPath = mainFilePath .. '/build/deps';
    --------------------------------
    fileCode = loadDependency(dependencies, fileCode, 'globals', true);
    fileCode = loadDependency(dependencies, fileCode, 'defaults', true);
    fileCode = loadDependency(dependencies, fileCode, 'cast', true);
    fileCode = loadDependency(dependencies, fileCode, 'logic', true);
    fileCode = loadDependency(dependencies, fileCode, 'utils', true);
    fileCode = loadDependency(dependencies, fileCode, 'logic', true);
    fileCode = loadDependency(dependencies, fileCode, 'utils', true);
    fileCode = loadDependency(dependencies, fileCode, 'types', true);
    fileCode = loadDependency(dependencies, fileCode, 'overload', true);
    fileCode = loadDependency(dependencies, fileCode, 'linkedlist');

    statRouter = {};

    statRouter[NodeType.FUNCTION_DECLARATION_NODE] = function (funcDecStat)
        return 'function ' .. generateFuncname(funcDecStat.id)
            .. generateFuncbody(funcDecStat.body);
    end

    statRouter[NodeType.LOCAL_FUNCTION_DECLARATION_NODE] = function (funcDecStat)
        return 'local function ' .. funcDecStat.id .. generateFuncbody(funcDecStat.body);
    end

    statRouter[NodeType.FOR_IN_LOOP_NODE] = function (forStat)
        return 'for ' .. generateNamelist(forStat.left) 
        .. ' in ' .. generateExplist(forStat.right) .. ' do\n'
        .. generateBlock(forStat.block) .. 'end';
    end

    statRouter[NodeType.FOR_CONTOR_LOOP_NODE] = function (forStat)
        local code =  'for ' .. forStat.contorName .. '=' .. generateExp(forStat.contorValue)
        .. ', ' .. generateExp(forStat.stopValue);
        if forStat.increment then
            code = code .. ', ' .. generateExp(forStat.increment);
        end
        code = code .. ' do\n' .. generateBlock(forStat.block) .. 'end';
        return code;
    end

    statRouter[NodeType.IF_NODE] = function (ifStatement)
        local code = 'if ';
        for index, branch in ipairs(ifStatement.branches) do
            if index > 1 then
                code = code .. 'elseif ';
            end
                code = code .. generateExp(branch.condition) .. ' then\n';
                code = code .. generateBlock(branch.block);
        end
        if ifStatement.elseBranch then
            code = code .. 'else\n' .. generateBlock(ifStatement.elseBranch.block);
        end
        code = code .. 'end\n'
        return code;
    end

    statRouter[NodeType.REPEAT_LOOP_NODE] = function (repeatStatement)
        return 'repeat\n' .. generateBlock(repeatStatement.block) .. 
            'until ' .. generateExp(repeatStatement.condition) .. ';';
    end

    statRouter[NodeType.WHILE_LOOP_NODE] = function (whileStat)
        return 'while ' .. generateExp(whileStat.condition) .. ' do\n'
               .. generateBlock(whileStat.block) .. 'end\n';
    end

    statRouter[NodeType.DO_BLOCK_NODE] = function(doBlock)
        return 'do\n' .. generateBlock(doBlock.block) .. 'end\n';
    end

    statRouter[NodeType.LOCAL_DECLARATION_NODE] = function (declaration)
        local code =  'local ' .. generateNamelist(declaration.left)  
        if declaration.right then
            local explist = generateExplist(declaration.right); 
            if explist ~= '' then
                code = code .. ' = ' .. explist;
            end  
        end
        code = code .. ';';
        return code;
    end

    statRouter[NodeType.FUNCTION_CALL_NODE] = function (functioncall)
        return generateFunctioncall(functioncall) .. ';';
    end

    statRouter[NodeType.DEFAULT_SET_NODE] = function (defaultSet)
        return generateDefaultSet(defaultSet);
    end

    statRouter[NodeType.ASSIGNMENT_NODE] = function (assign)
        local localCode = '';
        localCode = localCode .. generateVarlist(assign.left) .. ' = ' .. generateExplist(assign.right) .. ';';
        return localCode;
    end

    statRouter[NodeType.LOGIC_BLOCK_NODE] = function (block)
        return generateLogicBlock(block);
    end

    local overloadFunction = function (overload)
        return generateOverloadFunc(overload, linkResult.types);
    end
    statRouter[NodeType.BINARY_OPERATOR_OVERLOAD_NODE] = overloadFunction;
    statRouter[NodeType.UNARY_OPERATOR_OVERLOAD_NODE] = overloadFunction;

    statRouter[NodeType.CLASS_DECLARATION_NODE] = function (classDeclaration)

        local code = '';
        local oldThisIndex = currentThisIndex;
        currentThisIndex = 'self.';
        
        code = code .. classDeclaration.id .. ' = {}\n';
        code = code .. 'local _overload_meta = _dep_overload.getMeta();\n'
        code = code .. '_overload_meta.typename = "' .. classDeclaration.id .. '";\n'
        code = code .. 'setmetatable(' .. classDeclaration.id .. ',_overload_meta);\n';
        code = code .. classDeclaration.id .. '.' .. 'constructor = {};\n';

        if not classDeclaration.isAbstract then
            code = code .. generateInstantiationFunc(classDeclaration);
        end

        code = code .. generateClassStats(classDeclaration.id, classDeclaration.stats, classDeclaration.baseClassId, classDeclaration.baseClassArgs, classDeclaration.IndexOfBaseConstructor);
        currentThisIndex = oldThisIndex;
        return code;
    end

    for index, stat in ipairs(ast.stats) do
        if statRouter[stat.node] then
            fileCode = fileCode .. statRouter[stat.node](stat) .. '\n';
        end
    end
    if ast.retstat.expressions then
        fileCode = fileCode .. 'return ' .. generateExplist(ast.retstat.expressions) .. ';\n';
    end
    
    if OutputFile then
        OutputFile:write(fileCode); 
    end
end

return Generator;