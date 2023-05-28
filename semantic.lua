local utils = require('utils');
NodeType = require('tokens').NodeType;
local linker = require('linker')
Semantic = {};

local currentScope = {};
local errors = {};
local polish = {};
local currentClass = nil;

local inbuildOperations = {
    ['number' .. ':' .. TokenType.PLUS_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.MINUS_OPERATOR.. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.STAR_OPERATOR.. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.SLASH_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.PERCENT_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.CARET_OPERATOR .. ':' .. 'number'] = 'number',
    ['number' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'string'] = 'string',
    ['string' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'number'] = 'string',
    ['string' .. ':' .. TokenType.DOUBLE_POINT_MARK .. ':' .. 'string'] = 'string',
    ['number' .. ':' .. TokenType.EQUALS_OPERATOR .. ':' .. 'number'] = 'boolean'
};

local declaredOperations = {}

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
        return (traverseScope[varId] or {}).type, (traverseScope[varId] or {}).returnType, (traverseScope[varId] or {}).params;
    end
end

local function addNewError(message)
    errors[#errors+1] = {message = message};
end

local function namelistToTypelist(namelist)
    local typesList = {};
    local parNames = {};
    for index, parameter in ipairs(namelist) do
        local parType = parameter.type or 'any';
        if (not declaredTypes[parType]) and (not basicTypes[parType]) then
            addNewError('Cannot resolve type ' .. parType);
        end
        if parNames[parameter.id] ~= nil then
            addNewError('Parameter names must be unique');
        end
        parNames[parameter.id] = true;
        typesList[#typesList+1] = parType;
    end
    return typesList;
end

local function operationType(termOneType, op, termTwoType)
    if termOneType == 'any' or termTwoType == 'any' then
        return 'any';
    end
    if inbuildOperations[termOneType .. ':' .. op .. ':' .. termTwoType] then
        return inbuildOperations[termOneType .. ':' .. op .. ':' .. termTwoType];
    end
    if declaredOperations[termOneType .. ':' .. op .. ':' .. termTwoType] then
        return declaredOperations[termOneType .. ':' .. op .. ':' .. termTwoType];
    end
    errors[#errors+1] = 'invalid operation between types ' .. termOneType .. ' and ' .. termTwoType;
    return 'any';
end

local function level(token)
    if 
    token == TokenType.CARET_OPERATOR 
    then
        return 8;
    elseif
    token == TokenType.NOT_KEYWORD or
    token == TokenType.UNARY_MINUS_OPERATOR
    then
        return 7;
    elseif 
    token == TokenType.STAR_OPERATOR or
    token == TokenType.SLASH_OPERATOR
    then
        return 6;
    elseif 
    token == TokenType.PLUS_OPERATOR or
    token == TokenType.MINUS_OPERATOR 
    then
        return 5;
    elseif 
    token == TokenType.DOUBLE_POINT_MARK
    then
    elseif
    token == TokenType.MORE_OPERATOR or
    token == TokenType.LESS_OPERATOR or
    token == TokenType.MORE_OR_EQUAL_OPERATOR or
    token == TokenType.LESS_OR_EQUAL_OPERATOR or
    token == TokenType.NOT_EQUALS_OPERATOR or
    token == TokenType.EQUALS_OPERATOR
    then
        return 3;
    elseif 
    token == TokenType.AND_KEYWORD
    then
        return 2;
    elseif 
    token == TokenType.OR_KEYWORD
    then
        return 1;
    elseif
    token == TokenType.LEFT_PARAN_MARK or
    token == TokenType.RIGHT_PARAN_MARK
    then
        return 0;
    end
    print('operator' .. token .. 'not imlemented');
end

local function validateCast(original, castTo)
    if not (basicTypes[castTo] or declaredTypes[castTo]) then
        addNewError('Type ' .. castTo .. ' was not declared');
        return;
    end
    if original == castTo then
        return nil;
    end
    if castTo == 'any' then
        if declaredTypes[original] then
            return 'deepcopy';
        end
        return nil;
    end
    if original == 'any' then
        if basicTypes[castTo] then
            return 'check';
        end
        addNewError('Variables of type any can only be cast to primitve Types');
        return;
    end
    if basicTypes[original] and basicTypes[castTo] then
            addNewError('Cannot cast from one primitive type to another (' .. original .. ' to ' .. castTo .. ')');
        return;
    end
    if basicTypes[original] and declaredTypes[castTo] then
            addNewError('Cannot cast from primitive to declared types');
            return;
    end
    if declaredTypes[original] and basicTypes[castTo] then
        if castTo == 'table' then
            return 'deepcopy';
        else
            addNewError('Cannot cast from declared type to primitve types other than table');
            return;
        end
    end
    if declaredTypes[original] and declaredTypes[castTo] then
        if declaredTypes[original].castTo[castTo] then
            return nil;
        else
            if declaredTypes[castTo].castTo[original] then
                return 'check';
            else
                addNewError('No corelation found between tpyes ' .. original .. ' and ' .. castTo);
            end
        end
    end
end

local validateConstructorCall;
local resolveVarType;
local resolveExpType;
local function recursivePolish(exp, stack)
    if(exp.exp.node == NodeType.PARAN_EXP_NODE) then
        stack:push(TokenType.LEFT_PARAN_MARK);
        recursivePolish(exp.exp.exp, stack);
        while stack.top ~= TokenType.LEFT_PARAN_MARK do
            polish[#polish+1] = stack.top;
            stack:pop();
        end
        stack:pop();
        return;
    elseif exp.exp.node == NodeType.CAST_NODE then
        local castTo =  exp.exp.castTo;
        local currentType = resolveExpType(exp.exp.exp);
        local castSafety = validateCast(currentType, castTo);
        exp.exp.safety = castSafety;
        exp.exp.type = castTo;
        exp.exp.traversed = true;
    elseif exp.exp.valType == 'var' then
        exp.exp.type = resolveVarType(exp.exp.value);
    elseif exp.exp.valType == 'functioncall' then
        exp.exp.value.suffix[# exp.exp.value.suffix + 1] = exp.exp.value.call;
        exp.exp.type = resolveVarType(exp.exp.value);
        exp.exp.value.suffix[# exp.exp.value.suffix] = nil;
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
        recursivePolish(exp.op.term, stack);
    end
end

local function validateFunctionCall(functionParams, callArgs)
    local paramTypeList = namelistToTypelist(functionParams);
    for index, paramType in ipairs(paramTypeList) do
        if paramType ~= 'any' then
            if callArgs[index] then
                local argType = resolveExpType(callArgs[index]);
                if argType ~= paramType then
                    addNewError('Tried to call function with ' .. argType .. ' on param of type ' .. paramType);
                end
            else
                addNewError('Tried to call function with nil on param of type ' .. paramType);
            end
        end
    end
end

local function resolveIndexType(type, suffix, prefixId, typedCall)
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
                    local field = declaredTypes[type].fields[suff.id] or declaredTypes[type].abstractMethods[suff.id];
                    if not field then
                        addNewError('Field ' .. suff.id .. ' not found on type ' .. type);
                        type = 'nil';
                    else
                        type = field.type or 'any';
                    end
                elseif type == 'table' or type == 'any' then
                    type = 'any';
                else
                    addNewError('Cannot index type ' .. type);
                    type = 'any';
                end
                if suff.node == NodeType.SELF_CALL_NODE then
                    if type == 'member_function' then
                        type = declaredTypes[lastType].fields[lastId].returnType or 'any';
                        validateFunctionCall(declaredTypes[lastType].fields[lastId].params, typedCall.args)
                        lastId = '#';
                        lastType = '#';
                    else
                        type = 'any';
                    end
                end
            elseif suff.node == NodeType.CALL_NODE then
                if type == 'member_function' then
                    addNewError('Member functions should be called with ":".');
                    type = 'any';
                elseif type == 'function' then
                    if prefixId then
                        local _, returnType, params = resolveVarScopeType(prefixId);
                        validateFunctionCall(params, typedCall.args)
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

resolveExpType = function(exp)
    if exp == nil then
        return 'nil';
    end
    if exp.node == NodeType.LAMBDA_FUNC_NODE then
        return 'function';
    end
    polish = {};
    local stack = utils.createStack();
    recursivePolish(exp, stack);
    while stack.top do
        polish[#polish+1] = stack.top;
        stack:pop();
    end
    local stack = utils.createStack();
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
                if fieldType == 'table' and field.node == NodeType.TABLE_CONSTRUCTOR_NODE then
                    validateTableType(field.exp.exp.value, varType, depth - 1);
                else
                    addNewError('Cannot initialize homogenous structure with non homogenous table');
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
    if var.node == NodeType.FUNCTION_CALL_NODE then
        if var.prefix == 'requireELA' and (var.suffix and #var.suffix == 1) then
            if #var.call.args == 1 and (not var.call.args[1].op) and var.call.args[1].exp.type == 'string' then 
                local linkResult = linker.linkElaFile(var.call.args[1].exp.value);
                if not linkResult then
                    addNewError('Could not link module ' .. var.call.args[1].exp.value);
                end
                var.traversed = true;
                return;
            end
        end
    end
    if var.prefix and var.node == NodeType.VAR_NODE then
        type = resolveExpType(var.prefix.exp);
    else
        type = resolveVarScopeType(var.id or var.prefix, var.isThis) or 'any';
    end
    if var.suffix then
        local prefixType, depth = getTypeAndDepth(type);
        if type ~= 'table' and type ~= 'any' and (not declaredTypes[type]) and type ~= 'function' and depth == 0 then
            addNewError('illegal index of prefix of type ' .. type);
        else
            type = resolveIndexType(type, var.suffix, (var.id or var.prefix), var.call);
            var.traversed = true;
        end
    end
    return type;
end

local function equivalentArgs(cst1, cst2) 
    if #cst1 ~= #cst2 then
        return false;
    end
    for i=1, #cst1, 1 do
        if cst1[i] ~= cst2[i] then
            return false;
        end
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
    declaredTypes[classDecNode.id] = {constructors = {}, fields = {}, inheritParams = {}, abstractMethods = {}, castTo = {}, abstractCount = 0};
    if classDecNode.baseClassId then
        declaredTypes[classDecNode.id].fields = utils.deepCopy(declaredTypes[classDecNode.baseClassId].fields);
        declaredTypes[classDecNode.id].castTo = {[classDecNode.baseClassId] = true;};
        local currentCastTo = declaredTypes[classDecNode.id].castTo;
        for castType, _ in pairs(declaredTypes[classDecNode.baseClassId].castTo) do
            currentCastTo[castType] = true;
        end
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
            declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = stat.type, params = (stat.params.namelist or {})};
        elseif stat.node == NodeType.MEMBER_FUNCTION_NODE or stat.node == NodeType.LOGIC_BLOCK_NODE then
            if classDecNode.baseClassId then
                if declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id] and not abstractsImplemented[stat.id] then
                    if equivalentArgs(
                        namelistToTypelist(declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id].namelist or {}), 
                        namelistToTypelist((stat.args or stat.body.parlist.namelist) or {})
                    ) then
                        abstractsImplemented[stat.id] = true;
                        abstractsImplementedCount = abstractsImplementedCount + 1;
                    end
                end
            end
            declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = (stat.body or {}).type, params = namelistToTypelist((stat.args or stat.body.parlist.namelist) or {})};
        elseif stat.node == NodeType.CLASS_FIELD_DELCARATION_NODE then
            for index, field in ipairs(stat.left) do
                validate_declared_type(field);
                if not declaredTypes[classDecNode.id].fields[field.id] then
                    if stat.right and stat.right[index] then
                        validateAssignedType(field, stat.right[index]);
                        declaredTypes[classDecNode.id].fields[field.id] = {type = field.type};
                    elseif field.type ~= 'any' then
                       addNewError('Static field initialized with nil'); 
                    else
                        declaredTypes[classDecNode.id].fields[field.id] = {type = 'any'};
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
    classDecNode.fields = declaredTypes[classDecNode.id].fields;
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

validateConstructorCall = function(call_stat, declarations_list)
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
    addNewError('no constructor found with args ' .. errorTypes)
    return 'nil';
end

local function validateOverload(overload)
    local typelist = namelistToTypelist(overload.body.parlist.namelist);
    for index, value in ipairs(typelist) do
        if value == 'any' then
            addNewError('Cannot overload operator for type any');
            return;
        end
        if (not declaredTypes[value]) and (not basicTypes[value]) then
            return;
        end
    end
    if overload.node == NodeType.BINARY_OPERATOR_OVERLOAD_NODE then
        local key = typelist[1] .. ':' .. overload.op .. ':' .. typelist[2];
        if not (declaredTypes[typelist[1]] or declaredTypes[typelist[2]]) then
            addNewError('At least the #1 argument in overloading should be a class');
        end
        overload.type1 = typelist[1];
        overload.type2 = typelist[2];
        if not inbuildOperations[key] or declaredOperations[key] then
            declaredOperations[key] = overload.body.type or 'any';
        else
            addNewError('Operation already defined for types ' .. typelist[1] .. ', ' .. typelist[2]);
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
                    value.suffix[#value.suffix + 1] = value.call;
                    resolveVarType(value);
                    value.suffix[#value.suffix] = nil;
                end
            end

            if value.node == NodeType.REQUIRE_NODE then
                if not value.traversed then
                    
                end
            end

            if value.node == NodeType.LOCAL_FUNCTION_DECLARATION_NODE then
                local params = nil 
                if value.body.parlist.namelist then
                    params = namelistToTypelist(value.body.parlist.namelist);
                end
                currentScope[value.id] = {type = 'function', returnType = value.body.type, params = value.body.parlist.namelist or {}};
            end

            if value.node == NodeType.CAST_NODE then
                if not value.traversed then
                    value.safety = validateCast(resolveExpType(value.exp), value.castTo);
                end
            end

            --CLASSES
            if value.node == NodeType.INSTANTIATION_NODE then
                if not declaredTypes[value.id] then addNewError('No declaration found for type ' .. value.id) return end
                if #declaredTypes[value.id].abstractMethods > 0 then addNewError('Cannot instantiate abstract class ' .. value.id) end
                validateConstructorCall(value, declaredTypes[value.type].constructors);
            end

            if value.node == NodeType.BINARY_OPERATOR_OVERLOAD_NODE or value.node == NodeType.UNARY_OPERATOR_OVERLOAD_NODE then
                validateOverload(value);
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

local function saveTypesToCastFile()
    local outputFile = io.open('prefabs/types.lua', "w")
    local code = 'local types = {\n';
    for classId, classInfo in pairs(declaredTypes) do
        code = code .. '["' .. classId .. '"]' .. ' = {\n'; 
        for name, value in pairs(classInfo.fields) do
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

local function getBlockReturnType(ast)
    if ast.retstat.expressions then
        local types = {};
        for index, exp in ipairs(ast.retstat.expressions) do
            types[#types+1] = resolveExpType(exp);
        end
        return types;
    end
end

function Semantic.check(ast)
    if ast == nil then
        return;
    end
    traverse(ast);
    if #errors > 0 then
        print(#errors .. ' semantic errors');
        print(utils.dump(errors)); 
    else
        saveTypesToCastFile();
    end
    if #errors > 0 then
        return nil;
    end
    return {operations = declaredOperations, types = declaredTypes, returnedTypes = getBlockReturnType(ast)}
end

return Semantic;