Utils = require('utils');
NodeType = require('tokens').NodeType;
Semantic = {};

local currentScope = {};
local errors = {};
local polish = {};
local stack = {};
local currentClass = nil;

local resultedTypes = {
    ['number' .. ':' .. TokenType.PLUS_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.MINUS_OPERATOR.. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.STAR_OPERATOR.. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.SLASH_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'string'] = 'string',
    ['string' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'number'] = 'string',
    ['string' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'string'] = 'string',
    ['number' .. ':' .. TokenType.EQUALS_OPERATOR .. ':' .. 'number'] = 'boolean'
};

local basicTypes = {
    ['nil'] = true, 
    ['boolean'] = true, 
    ['number'] = true, 
    ['string'] = true, 
    ['table'] = true, 
    ['function'] = true, 
    ['userdata'] = true, 
    ['thread'] = true,
    ['any'] = true
}

local declaredTypes = {};

local function getTypeAndDepth(varType)
    if not varType then return 'any', 0 end;
    local separatorIndex = string.find(varType, "|");
    if separatorIndex == nil then
        return varType, 0;
    end
    local str = string.sub(varType, 1, separatorIndex - 1)
    local num = tonumber(string.sub(varType, separatorIndex + 1))
    return str, num;
end

local function resolveVarScopeType(varId, isThis)
    local traverseScope = currentScope;
    if isThis then
        if not currentClass then return 'nil' end;
        if declaredTypes[currentClass].fields[varId] then
            return declaredTypes[currentClass].fields[varId].type or 'any';
        else
            return 'nil';
        end
    else
        while traverseScope.father and (not traverseScope[varId]) do
            traverseScope = traverseScope.father;
        end
        return (traverseScope[varId] or {}).type, (traverseScope[varId] or {}).returnType;
    end
end

local function addNewError(message)
    errors[#errors+1] = {message = message};
end

local function operationType(termOneType, op, termTwoType)
    if op == TokenType.AS_KEYWORD then
        return termTwoType;
    end
    if termOneType == 'any' or termTwoType == 'any' then
        return 'any';
    end
    if resultedTypes[termOneType .. ':' .. op .. ':' .. termTwoType] then
        return resultedTypes[termOneType .. ':' .. op .. ':' .. termTwoType];
    end
    errors[#errors+1] = 'invalid operation between types ' .. termOneType .. ' and ' .. termTwoType;
    return 'any';
end

local function level(token)
    if
    token == TokenType.LEFT_PARAN_MARK then
        return 0;
    end
    if token == TokenType.EQUALS_OPERATOR or
    token == TokenType.NOT_EQUALS_OPERATOR
    then
        return 1;
    end
    if 
    token == TokenType.PLUS_OPERATOR or   
    token == TokenType.MINUS_OPERATOR or
    token == TokenType.DOUBLE_POINT_MARK or
    token == TokenType.PERCENT_OPERATOR
    then
        return 2;
    end
    if 
    token == TokenType.STAR_OPERATOR or   
    token == TokenType.SLASH_OPERATOR
    then
        return 3;
    end
    if
    token == TokenType.AS_KEYWORD 
    then
        return 4;
    end
    print('operator' .. token .. 'not imlemented');
end

local validateCall;
local resolveVarType;
local function recursivePolish(exp)
    if(exp.exp.node == NodeType.PARAN_EXP_NODE) then
        stack:push(TokenType.LEFT_PARAN_MARK);
        recursivePolish(exp.exp.exp);
        while stack.top ~= TokenType.LEFT_PARAN_MARK do
            polish[#polish+1] = stack.top;
            stack:pop();
        end
        stack:pop();
        return;
    elseif exp.exp.valType == 'var' then
        exp.exp.type = resolveVarType(exp.exp.value);
    elseif exp.exp.valType == 'functioncall' then
        exp.exp.value.suffix[# exp.exp.value.suffix + 1] = exp.exp.value.call;
        exp.exp.type = resolveVarType(exp.exp.value);
        exp.exp.value.suffix[# exp.exp.value.suffix + 1] = nil;
    end
    polish[#polish+1] = exp.exp.type;
    if exp.op then
        local symbol = exp.op.binop.symbol;
        if stack.top == nil then
            stack:push(symbol);
        else
            while stack.top and level(symbol) <= level(stack.top) do
                polish[#polish+1] = stack.top;
                stack:pop();
            end
            stack:push(symbol);
        end
        recursivePolish(exp.op.term);
    end
end

local function resolveIndexType(type, suffix, prefixId)
    local lastId = '#';
    local lastType = '#';
    local depth;
    for index, suff in ipairs(suffix) do
        if type == 'any' then return 'any' end;
        type, depth = getTypeAndDepth(type);
        if depth == 0 then
            if suff.node == NodeType.POINT_INDEX_NODE or suff.node == NodeType.SELF_CALL_NODE then
                if declaredTypes[type] then
                    lastId = suff.id;
                    lastType = type;
                    type = declaredTypes[type].fields[suff.id].type or 'nil';
                elseif type == 'table' or type == 'any' then
                    type = 'any';
                else
                    addNewError('Cannot index type ' .. type);
                    type = 'any';
                end
                if suff.node == NodeType.SELF_CALL_NODE then
                    if type == 'member_function' then
                        type = declaredTypes[lastType].fields[lastId].returnType or 'any';
                        lastId = '#';
                        lastType = '#';
                    else
                        type = 'any';
                    end
                end
            elseif suff.node == NodeType.CALL_NODE then
                if type == 'member_function' then
                    type = declaredTypes[lastType].fields[lastId].returnType or 'any';
                    lastId = '#';
                    lastType = '#';
                elseif type == 'function' then
                    if prefixId then
                        local _, returnType = resolveVarScopeType(prefixId);
                        type = returnType or 'any';
                    else
                        type = 'any';
                    end
                elseif type == 'any' then
                    type = 'any';
                else
                    addNewError('Cannot call type ' .. type);
                    type = 'any';
                end
            elseif suff.node == NodeType.BRACKET_INDEX_NODE then
                if type == 'table' then
                    type = 'any';
                elseif declaredTypes[type] then
                    addNewError('Cannot access class fields with brackets');
                    type = 'nil';
                else
                    addNewError('Cannot bracket index type ' .. type);
                    type = 'nil';
                end
            end
        else
            if suff.node ~= NodeType.BRACKET_INDEX_NODE then
                addNewError('Homogenous structures should be accessed with brackets');
                type = 'nil';
            else
                depth = depth - 1;
                if depth > 0 then
                    type = type .. '|' .. depth;
                end
            end
        end
        prefixId = suff.id;
    end
    return type;
end

local function resolveExpType(exp)
    if exp == nil then
        return 'nil';
    end
    if exp.node == NodeType.LAMBDA_FUNC_NODE then
        return 'function';
    end
    polish = {};
    stack = utils.createStack();
    recursivePolish(exp);
    while stack.top do
        polish[#polish+1] = stack.top;
        stack:pop();
    end
    stack = utils.createStack();
    for key, value in pairs(polish) do
        if type(value) == 'string' then
            stack:push(value);
        else
            local term2 = stack.top;
            stack:pop();
            local term1 = stack.top;
            stack:pop();
            stack:push(operationType(term1, value, term2));
        end
    end
    return stack.top;
end

local function validateTableType(table, varType, depth)
    for index, field in ipairs(table.fieldlist) do
        local fieldType = resolveExpType(field.exp);
        if depth == 0 then
            if fieldType ~= varType and fieldType ~= 'nil' then
                addNewError('Wrong type ' .. fieldType .. ' in structure of type ' .. varType);
            end
        else
            if fieldType ~= 'table' and fieldType ~= 'nil' and fieldType ~= (varType .. '|' .. depth) then
                addNewError('Wrong type ' .. fieldType .. ', ' ..varType .. '|'.. depth .. ' expected');
            else
                if fieldType == 'table' then
                    validateTableType(field.exp.exp.value, varType, depth - 1);
                end
            end
        end
    end
end

local function validateAssignedType(left, right)
    local expressionType = resolveExpType(right);

    if not left.type then left.type = 'any' end;
    local varType, depth = getTypeAndDepth(left.type);
    if depth > 0 and expressionType == 'table' then
        validateTableType(right.exp.value, varType, depth - 1);
    elseif left.type ~= 'any' and left.type ~= expressionType then
        addNewError('Wrong type ' .. expressionType .. ' assgined to ' .. left.type);
    end
end

resolveVarType = function(var)
    local type = nil;
    if var.prefix and var.prefix.node == NodeType.VAR_NODE then
        type = resolveExpType(var.prefix.exp);
    else
        type = resolveVarScopeType(var.id or var.prefix, var.isThis) or 'any';
    end
    if var.suffix then
        local prefixType, depth = getTypeAndDepth(type);
        if type ~= 'table' and type ~= 'any' and (not declaredTypes[type]) and type ~= 'function' and depth == 0 then
            addNewError('illegal index of prefix of type ' .. type);
        else
            type = resolveIndexType(type, var.suffix, (var.id or var.prefix));
        end
    end
    return type;
end

local function equivalentArgs(cst1, cst2) 
    if #cst1 ~= #cst2 then
        return false;
    end
    for i=1, #cst1, 1 do
        if cst1[i] == 'any' or cst2[i] == 'any' then
            goto continue;
        end
        if cst1[i] ~= cst2[i] then
            return false;
        end
        ::continue::
    end
    return true;
end

local function validate_declared_type(var)
    if var.type == nil then
        var.type = 'any';
    end
    local flatType = getTypeAndDepth(var.type);
    if basicTypes[flatType] == nil and declaredTypes[flatType] == nil then 
        addNewError('Type ' .. flatType .. ' was not declared!');
        var.type = 'any';
        return false;
    end
    return true;
end

local function namelistToTypelist(namelist)
    local typesList = {};
    local parNames = {};
    for index, parameter in ipairs(namelist) do
        local parType = parameter.type or 'any';
        if parNames[parameter.id] ~= nil then
            addNewError('Parameter names must be unique');
        end
        parNames[parameter.id] = true;
        typesList[#typesList+1] = parType;
    end
    return typesList;
end

local function validateFunctionDeclaration(funcNode, isConstructor)
    local parameters = funcNode.body.parlist.namelist or {};
    local isTriple = funcNode.body.parlist.isTriple;
    local typesList = {};
    local parNames = {};
    typesList = namelistToTypelist(parameters);
    if isTriple then
        typesList[#typesList+1] = 'repeat';
    end
    return typesList;
end

local function addConstructor(classID, ctrNode)
    if ctrNode.body.type then
       addNewError('constructors cannot have explicit return types');
       ctrNode.body.type = nil;
    end
    local typesList = namelistToTypelist(ctrNode.body.parlist.namelist or {});
    for index, var in ipairs(ctrNode.body.parlist.namelist or {}) do
        if declaredTypes[classID].inheritParams[var.id] then
            addNewError('Base class parameters are injected in constructors implicitly, remove the explicit parameter with same name ' .. var.id);
        end 
    end
    local valid = true;
    for key, cst in ipairs(declaredTypes[classID].constructors) do
        if equivalentArgs(cst, typesList) then
            addNewError('ambiguity in the declaration of constructors')
            valid = false;
        end
    end
    if valid then
        declaredTypes[classID].constructors[#declaredTypes[classID].constructors+1] = typesList;
    end
end

local function declareClass(classDecNode)
    if declaredTypes[classDecNode.id] ~= nil or basicTypes[classDecNode.id] ~= nil then
        addNewError('found redeclaration of type ' .. classDecNode.id);
        return;
    end
    declaredTypes[classDecNode.id] = {constructors = {}, fields = {}, inheritParams = {}, abstractMethods = {}, abstractCount = 0};
    if classDecNode.baseClassId then
        local baseClassTypeList = namelistToTypelist(classDecNode.baseClassArgs);
        for index, var in ipairs(classDecNode.baseClassArgs) do
            declaredTypes[classDecNode.id].inheritParams[var.id] = {type = var.type or 'any'};
        end
        local baseCst = declaredTypes[classDecNode.baseClassId].constructors;
        local foundCst = nil;
        for index, cst in ipairs(baseCst) do
            if equivalentArgs(cst, baseClassTypeList) then
                foundCst = index;
            end
        end
        if not foundCst then addNewError("Cannot resolve constructor for base class " .. classDecNode.baseClassId .. ' of ' .. classDecNode.id) end;
        classDecNode.IndexOfBaseConstructor = foundCst;
    end
    local abstractsImplemented = {};
    local abstractsImplementedCount = 0;
    for index, stat in ipairs(classDecNode.stats) do
        if stat.node == NodeType.CONSTRUCTOR_NODE then
            addConstructor(classDecNode.id, stat);
        elseif stat.node == NodeType.ABSTRACT_METHOD_NODE then
            local abstracts = declaredTypes[classDecNode.id].abstractMethods;
            abstracts[stat.id] = stat.params;
            declaredTypes[classDecNode.id].abstractCount = declaredTypes[classDecNode.id].abstractCount + 1;
            classDecNode.isAbstract = true;
            declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = stat.type};
        elseif stat.node == NodeType.MEMBER_FUNCTION_NODE or stat.node == NodeType.LOGIC_BLOCK_NODE then
            if classDecNode.baseClassId then
                if declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id] and not abstractsImplemented[stat.id] then
                    if equivalentArgs(
                        namelistToTypelist(declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id].namelist), 
                        namelistToTypelist((stat.args or stat.body.parlist.namelist) or {})
                    ) then
                        abstractsImplemented[stat.id] = true;
                        abstractsImplementedCount = abstractsImplementedCount + 1;
                    end
                end
            end
            declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = (stat.body or {}).type};
        elseif stat.node == NodeType.CLASS_FIELD_DELCARATION_NODE then
            for index, field in ipairs(stat.left) do
                validate_declared_type(field);
                if not declaredTypes[classDecNode.id].fields[field.id] then
                    if stat.right and stat.right[index] then
                        validateAssignedType(field, stat.right[index]);
                        declaredTypes[classDecNode.id].fields[field.id] = {type = field.type};
                    elseif field.type ~= 'any' then
                       addNewError('Static field initialized with nil'); 
                    end
                else
                    addNewError('Field redeclaration for ' .. field.id .. ' in class ' .. classDecNode.id);
                end
            end
        end
    end
    if classDecNode.baseClassId and abstractsImplementedCount ~= declaredTypes[classDecNode.baseClassId].abstractCount then
        addNewError('Not all abstract methods of base class ' .. classDecNode.baseClassId .. ' were implemented');
    end
end

local function checkDeclarationNode(currentNode, child)
    for index, var in ipairs(child.left) do
        --NEW DECLARED Local
        if not currentScope[var.id] then
            validate_declared_type(var);
            currentScope[var.id] = {type = var.type};
        else
            if not var.type then var.type = 'any' end;
            if var.type ~= currentScope[var.id].type then
                addNewError('Redefinition in the same scope of variable ' .. var.id .. ' with different type ' .. '(was ' .. currentScope[var.id].type .. ', now is ' .. var.type .. ' )');
            end
        end
        local right = (child.right or {})[index];
        if (not right) and var.type ~= 'any' then
            addNewError('Static variable was assigned nil');
        else
            if right then
                validateAssignedType(var, right); 
            end
        end
    end
end

local function checkAssignmentNode(assignment)
    for index, var in ipairs(assignment.left) do
        local type = resolveVarType(var);
        local right = (assignment.right or {})[index];
        if (not right) and type ~= 'any' then
            addNewError('Static variable was assigned nil');
        else
            if right then
                local leftType = resolveVarType(var);
                local rightType = resolveExpType(right);
                local varType, depth = getTypeAndDepth(leftType);
                if depth > 0 and rightType == 'table' then
                    validateTableType(right.exp.value, varType, depth - 1);
                elseif leftType ~= 'any' and leftType ~= rightType then
                    addNewError('Wrong type ' .. rightType .. ' assigned to ' .. leftType);
                end
            end
        end
    end
end

validateCall = function(call_stat, declarations_list)
    local typeList = {};
    for key, arg in ipairs(call_stat.args) do
        local type = resolveExpType(arg);
        typeList[#typeList+1] = type;
    end
    for key, decl in ipairs(declarations_list) do
        if equivalentArgs(decl, typeList) then
            call_stat.indexOfMatch = key;
            call_stat.traversed = true;
            return decl.return_type or 'any';
        end
    end
    local errorTypes = "[";
    for key, value in ipairs(typeList) do
        errorTypes = errorTypes .. value .. ',';
    end
    errorTypes = errorTypes .. ']';
    addNewError('no declaration of function found with args ' .. errorTypes)
    return 'nil';
end

local function declareFunction(func_stat)
    local args = validateFunctionDeclaration(func_stat);
    args.return_type = func_stat.body.type;
    if not currentScope[func_stat.id[1]] then
        currentScope[func_stat.id[1]] = {type = 'function', args = {[1] = args}};
    else
        local valid = true;
        for key, argsList in ipairs(currentScope[func_stat.id[1]].args) do
            if equivalentArgs(args, argsList) then
                addNewError('ambiguity in function declaration');
                valid = false;
            end
        end
        if valid then
            currentScope[func_stat.id[1]].args[#currentScope[func_stat.id[1]].args + 1] = args;
        end
    end
end

local function traverse(currentNode)
    for key, value in pairs(currentNode) do
        if type(value) == 'table' then
            --LOCAL DECLARATION
            if value.node == NodeType.LOCAL_DECLARATION_NODE then
                checkDeclarationNode(currentNode, value);
            end

            if value.node == NodeType.ASSIGNMENT_NODE then
                checkAssignmentNode(value);
            end

            if value.node == NodeType.CLASS_DECLARATION_NODE then
                declareClass(value);
            end

            if value.node == NodeType.FUNCTION_CALL_NODE then
                if not value.traversed then
                    --utils.dump_print(value);
                end
            end

            if value.node == NodeType.LOCAL_FUNCTION_DECLARATION_NODE then
                currentScope[value.id] = {type = 'function', returnType = value.body.type};
            end

            if value.node == NodeType.VAR_NODE or value.node == NodeType.NAME_NODE then
                utils.dump_print(value.id);
            end

            --CLASSES
            if value.node == NodeType.INSTANTIATION_NODE then
                if not declaredTypes[value.id] then addNewError('No declaration found for type ' .. value.id) return end
                if #declaredTypes[value.id].abstractMethods > 0 then addNewError('Cannot instantiate abstract class ' .. value.id) end
                validateCall(value, declaredTypes[value.type].constructors);
            end

            if value.node == NodeType.FUNC_BODY_NODE or value.node == NodeType.DO_BLOCK_NODE then
                local nextScope = {};
                if value.node == NodeType.FUNC_BODY_NODE then
                    for index, var in ipairs(value.parlist.namelist or {}) do
                        nextScope[var.id] = {type = var.type or 'any'};
                    end
                end
                nextScope.father = currentScope;
                currentScope = nextScope; 
                traverse(value);
                if value.node == NodeType.FUNC_BODY_NODE then
                    local expectedReturnType = value.type or 'any';
                    if expectedReturnType ~= 'any' then
                        if not value.block.retstat.expressions then
                            addNewError('Function expected to return ' .. expectedReturnType .. ', returns nil instead');
                        elseif #value.block.retstat.expressions > 1 then
                            addNewError('You can return only one value on explicit typed function');
                        else
                            local actualReturnType = resolveExpType(value.block.retstat.expressions[1]);
                            if actualReturnType ~= expectedReturnType then
                                addNewError('Function expected to return ' .. expectedReturnType .. ', returns ' .. actualReturnType .. ' instead')
                            end
                        end
                    end
                end
                currentScope = currentScope.father;
            elseif value.node == NodeType.CLASS_DECLARATION_NODE then
                currentClass = value.id;
                local nextScope = {};
                if value.baseClassId then
                    for index, var in ipairs(value.baseClassArgs) do
                        nextScope[var.id] = {type = var.type or 'any'};
                    end
                end
                nextScope.father = currentScope;
                currentScope = nextScope;
                traverse(value);
                currentScope = currentScope.father;
                currentClass = nil;
            else
                if key ~= 'namelist' then
                    traverse(value); 
                end
            end
        end
    end
end

function Semantic.check(ast)
    if ast == nil then
        return;
    end
    traverse(ast);
    print(#errors .. ' semantic errors');
    if #errors > 0 then
        print(utils.dump(errors)); 
    end
    return #errors == 0;
end

return Semantic;