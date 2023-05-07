Utils = require('utils');
NodeType = require('tokens').NodeType;
Generator = {};
MainOutputFile = io.open("output/main.ela", 'w');
Code = "";

function Generator.generate(ast)
    --Code = "";
    local astfile = io.open('extra/ast.ast', 'w');
    if not astfile then return; end;
    astfile:write(utils.dump(ast));

    local statRouter = {};
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
    end

    for index, stat in ipairs(ast.stats) do
        if statRouter[stat.node] then
            statRouter[stat.node](stat);
        end
    end

    if ast.retstat then
        Code = Code .. "\nprint('Program returned " .. utils.dump(ast.retstat) .. "');";
    end

    MainOutputFile:write(Code);
    os.execute('start cmd /c "lua output/main.ela && pause"')
end

return Generator;