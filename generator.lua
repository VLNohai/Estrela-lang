Utils = require('utils');
NodeType = require('tokens').NodeType;
Generator = {};
MainOutputFile = io.open("output/main.lua", 'w')
Code = "--end of dependencies\n";
local dependencies = {};
local scopePrefixString = '..scID';

local function writeFunction(is_local, name, args, body_as_string)
    local code = '';
    if is_local then
        code = code .. 'local ';
    end
    code = code .. 'function ' .. name .. '(';
    if #args > 0 then
        code = code .. args[1];
        for index, arg in ipairs(utils.remove_first_n(args, 1)) do
            code = code .. ', ' .. arg;
        end
    end
    code = code ..')\n' .. body_as_string .. '\n' .. 'end\n';
    return code;
end

local function loadDependency(name, onMainFile)
    if not dependencies[name] then
        if onMainFile then
            Code = 'local _dep_' .. name .. ' = require("deps.' .. name  .. '");\n' .. Code; 
        end
        local src = io.open('prefabs/' .. name .. '.lua');
        if src then
            local content = src:read("*all");
            local dest = io.open("output/deps/" .. name .. '.lua', 'wb');
            if dest then
                dest:write(content);
                dest:close();  
            end
        end
        dependencies[name] = true;
    end
end

local function fromLogicNodeToTable(node)
    local code = '';
    if not node then
        return 'nil';
    end
    if node.node == NodeType.LOGIC_TABLE_NODE then
        code = code .. '{';
        local head = fromLogicNodeToTable(node.head);
        local tail = fromLogicNodeToTable(node.tail);
        if head ~= 'nil' and tail == 'nil' then
            tail = '{}';
        end
        if head ~= 'nil' or tail ~= 'nil' then
            code = code .. 'head = ' .. head .. ', tail = ' .. tail;
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
            left, right = '_dep_logic.substitute_vars(', ', _logic_bindings)';
        end
        code = code .. left .. fromLogicNodeToTable(arg) .. right ..', ';
    end
    code = string.sub(code, 1, -3);
    return code;
end

local checkItBinded = 'if not _logic_bindings then _dep_logic.inv() return nil end;';
local function handleLogicArgs(block_args, func_args)
    local header = '';
    local footer = '';
    header = header .. 'local _logic_bindings = ';
    header = header .. '_dep_logic.unify_many(\n{' .. resolveFuncArgs(func_args)  .. '},\n';
    header = header .. '{' .. utils.listOfIdsToCommaString(block_args) .. '}';
    header = header .. ', {});\n';
    header = header .. checkItBinded .. '\n';

    footer = footer .. '_dep_logic.ret();\n'
    footer = footer ..  'return {' .. resolveFuncArgs(func_args, true) .. '};';
    return header, footer;
end

local function resolveToNumber(value)
    local code = '';
    if value.node == NodeType.LOGIC_IDENTIFIER_NODE then
        code = '_dep_logic.substitute_vars(' .. "'_" .. value.id .. "'" .. scopePrefixString .. ', _logic_bindings' .. ')';
    else
        code = code .. value.value;
    end
    return code;
end

local function FromTokenToStringOps(token)
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
        code = code .. FromTokenToStringOps(exp.binop);
        exp = exp.exp;
        if exp.value then
            code = code .. resolveToNumber(exp.value);
        else
            code = code .. "(" .. spreadExp(exp.innerExp) .. ")";
        end
    end
    return code;
end

local function handleLogicStats(stats)
    local code = '';
    for index, stat in ipairs(stats) do
        if stat.node == NodeType.LOGIC_CHECK_NODE then
            code = code .. 'if not _dep_logic.check(' .. spreadExp(stat.left) .. ', ' .. spreadExp(stat.right) .. ", '" .. FromTokenToStringOps(stat.check) .. "'" .. ') then _dep_logic.inv() return nil; end' .. '\n';
        elseif stat.node == NodeType.LOGIC_UNIFY_NODE then
            code = code .. 'if not _dep_logic.unify(' .. fromLogicNodeToTable(stat.left) .. ', ' .. fromLogicNodeToTable(stat.right)  .. ', _logic_bindings) then  _dep_logic.inv() return nil end\n';
        elseif stat.node == NodeType.LOGIC_FUNCTION_CALL_NODE then
            code = code .. 'if not _dep_logic.unify_many({' .. resolveFuncArgs(stat.args) .. '}, ' .. stat.id .. '(' .. resolveFuncArgs(stat.args, true)  .. ')' .. ', _logic_bindings) then _dep_logic.inv() return nil end\n';
        elseif stat.node == NodeType.LOGIC_ASSIGN_NODE then
            code = code .. 'if not _dep_logic.unify("_' .. stat.left  .. '"' .. scopePrefixString .. ', ' .. spreadExp(stat.right)  .. ', _logic_bindings) then _dep_logic.inv() return nil end\n';
        end
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

function Generator.generate(ast)
    local astfile = io.open('extra/ast.ast', 'w');
    os.execute('mkdir "' .. 'output/deps' .. '" > nul 2>&1')
    if not astfile then return; end;
    astfile:write(utils.dump(ast));

    local statRouter = {};
    --[[
    statRouter[NodeType.ASSIGNMENT_NODE] = function (assignment)
        for index, var in ipairs(assignment.left) do
            Code = Code .. var.id;
            if index < #assignment.left then
                Code = Code .. ',';
            end
        end
        Code = Code .. ' = 1;';
        if assignment.checkAtRuntime then
            --print('add an assert!');
        else
            --print('was certain');
        end
    end]]

    statRouter[NodeType.LOGIC_BLOCK_NODE] = function (block)
        local localCode = '';
        loadDependency('utils', true);
        loadDependency('linkedlist');
        loadDependency('logic', true);
        --BODY
        local bodyCode = '';
        bodyCode = bodyCode .. tablesToLogicLists(block.args, block.id);
        for index, func in ipairs(block.funcs) do
            local header, footer = handleLogicArgs(block.args, func.args);
            local func_id = block.id .. '_' .. index;
            bodyCode = bodyCode .. writeFunction(true, (func_id), utils.extractField(block.args, 'id'),
                'if not _dep_logic.adv("' .. func_id .. '"' .. ') then return nil end;\n' 
                .. 'local scID = _dep_logic.newScopeId()\n' 
                .. header .. handleLogicStats(func.stats) .. footer
            );
        end
        --RETSTAT
        bodyCode = bodyCode .. 'local _logic_ret_val = '
        for index, func in ipairs(block.funcs) do
            bodyCode = bodyCode .. block.id .. '_' .. index .. '(' .. utils.listOfIdsToCommaString(block.args) .. ')' .. ' or ';
        end
        bodyCode = bodyCode .. 'nil;';
        bodyCode = '_Logic_stack_depth = _Logic_stack_depth + 1;\n' .. bodyCode;
        bodyCode = bodyCode .. '\n_Logic_stack_depth = _Logic_stack_depth - 1;\n'
        bodyCode = bodyCode .. '_dep_logic.reset()';
        bodyCode = bodyCode .. 'if (not _logic_ret_val) or #_logic_ret_val == 0 then return nil end;\n'
        bodyCode = bodyCode .. 'return _logic_ret_val;\n';
        --SIGNATURE
        localCode = localCode .. writeFunction(false, block.id, utils.extractField(block.args, 'id'), bodyCode);

        return localCode;
    end

    for index, stat in ipairs(ast.stats) do
        if statRouter[stat.node] then
            local temp = statRouter[stat.node](stat) .. '\n';
            Code = Code .. temp;
        end
    end

    MainOutputFile:write(Code);
    --os.execute('start cmd /c "lua output/main.ela && pause"')
end

return Generator;