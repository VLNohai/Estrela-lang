Utils = require('utils');
NodeType = require('tokens').NodeType;
Generator = {};
MainOutputFile = io.open("output/main.ela", 'w')
Code = "";
local dependencies = {};

local function loadDependency(name)
    if not dependencies[name] then
        Code = 'local _dep_' .. name .. ' = require("' .. name  .. '.lua");\n' .. Code;
        local src = io.open('prefabs/' .. name .. '.lua');
        if src then
            local content = src:read("*all");
            local dest = io.open("output/" .. name .. '.lua', 'wb');
            if dest then
                dest:write(content);
                dest:close();  
            end
        end
        dependencies[name] = true;
    end
end

function Generator.generate(ast)
    local astfile = io.open('extra/ast.ast', 'w');
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
        loadDependency('logic');

        --SIGNATURE
        localCode = localCode .. '--LOGIC BLOCK' .. '\n';
        localCode = localCode .. 'local function ' .. block.id .. '(';
            if(block.args) then
            localCode = localCode .. block.args[1].id;
            for index, arg in ipairs(utils.remove_first_n(block.args, 1)) do
                if arg.argType == 'in' then
                    localCode = localCode .. ', ' .. arg.id; 
                end
            end
        end

        localCode = localCode .. ')\n';
        
        --BODY
        localCode = localCode .. '--do stuff here\n';
        localCode = localCode .. 'end\n';

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