Utils = require('utils');
NodeType = require('tokens').NodeType;
Generator = {};
MainOutputFile = io.open("output/main.lua", 'w')
Code = "--end of dependencies\n";
local dependencies = {};

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
        code = code .. 'head = ' .. fromLogicNodeToTable(node.head) .. ', tail = ' ..fromLogicNodeToTable(node.tail);
        code = code .. '}';
    elseif node.node == NodeType.VALUE_NODE then
        local code = node.value;
        if type(node.value) == "string" then
            code = '"' .. code .. '"';
        end
    elseif node.node == NodeType.LOGIC_IDENTIFIER_NODE then
        code = node.id;
    end
    return code;
end

local function resolveFuncArgs(func_args)
    local code = '';
    for index, arg in ipairs(func_args) do
        code = code .. fromLogicNodeToTable(arg) .. ', ';
    end
    return code;
end

local function handleLogicArgs(block_args, func_args)
    local header = '';
    local footer = '';
    header = header .. '_dep_logic.unify(\n{' .. resolveFuncArgs(func_args)  .. '},\n';
    header = header .. '{' .. utils.listOfIdsToCommaString(block_args) .. '}';
    header = header .. ');';
    return header, footer;
end

local function handleLogicStats(stats)
    return '';
end

local function tablesToLogicLists(args)
    local code = '';
    for index, arg in ipairs(args) do
        
    end
    code = code .. utils.listOfIdsToCommaString(args) .. ' = _dep_logic.toList(' ..utils.listOfIdsToCommaString(args, true)  .. ');\n';
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
        loadDependency('utils');
        loadDependency('linkedlist');
        loadDependency('logic', true);
        --BODY
        local bodyCode = '';
        bodyCode = bodyCode .. tablesToLogicLists(block.args);
        for index, func in ipairs(block.funcs) do
            local header, footer = handleLogicArgs(block.args, func.args);
            bodyCode = bodyCode .. writeFunction(true, (block.id .. '_' .. index), utils.extractField(block.args, 'id'),
                header .. handleLogicStats(func.stats) .. footer
            );
        end
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