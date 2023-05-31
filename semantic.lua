local utils = require('utils');
NodeType = require('tokens').NodeType;
local linker = require('linker')
local Semantic = {};

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
    ['number' .. ':' .. TokenType.EQUALS_OPERATOR .. ':' .. 'number'] = 'boolean',
    [TokenType.HASH_OPERATOR .. ':' .. 'table'] = 'number';
    [TokenType.HASH_OPERATOR .. ':' .. 'string'] = 'number';
    [TokenType.UNARY_MINUS_OPERATOR .. ':' .. 'number'] = 'number';
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
    ['any'] = true,
    ['logic_function'] = true
}

local function addNewError(message, SemanticState)
    SemanticState.errors[#SemanticState.errors+1] = message;
end

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

local function getClassName(classType)
    local before, after = classType:match("(.-)@(.*)")
    return before, after;
end

local function resolveVarScopeType(varId, isThis, SemanticState)
    local traverseScope = SemanticState.currentScope;
    if isThis then
        if not SemanticState.currentClass then
            addNewError('"This" keyword can only be used inside class methods', SemanticState);
            return 'any' 
        end;
        if SemanticState.declaredTypes[SemanticState.currentClass].fields[varId] then
            return SemanticState.declaredTypes[SemanticState.currentClass].fields[varId].type or 'any';
        else
            addNewError('Field "' .. varId .. '"' .. ' is not part of class ' .. SemanticState.currentClass, SemanticState);
            return 'any';
        end
    else
        if SemanticState.declaredTypes[varId] then
            return 'class@' .. varId;
        end
        while traverseScope.father and (not traverseScope[varId]) do
            traverseScope = traverseScope.father;
        end
        return (traverseScope[varId] or {}).type, (traverseScope[varId] or {}).returnType, (traverseScope[varId] or {}).params;
    end
end

local function namelistToTypelist(namelist, SemanticState)
    local typesList = {};
    local parNames = {};
    for index, parameter in ipairs(namelist) do
        local parType = parameter.type or 'any';
        if (not SemanticState.declaredTypes[parType]) and (not basicTypes[parType]) then
            addNewError('Cannot resolve type ' .. parType, SemanticState);
        end
        if parNames[parameter.id] ~= nil then
            addNewError('Parameter names must be unique', SemanticState);
        end
        parNames[parameter.id] = true;
        typesList[#typesList+1] = parType;
    end
    return typesList;
end

local function operationType(termOneType, op, termTwoType, SemanticState)
    if termOneType == 'any' or termTwoType == 'any' then
        return 'any';
    end
    local _, depth = getTypeAndDepth(termOneType);
    if depth > 0 then termOneType = 'table'; end;
    local _, depth = getTypeAndDepth(termTwoType);
    if depth > 0 then termTwoType = 'table'; end;

    if op == TokenType.OR_KEYWORD then
        if termOneType == termTwoType or termOneType == 'nil' or termTwoType == 'nil' then
            return termOneType;
        else
            return 'any';
        end
    elseif 
    op == TokenType.AND_KEYWORD or 
    op == TokenType.EQUALS_OPERATOR or
    op == TokenType.NOT_EQUALS_OPERATOR or
    op == TokenType.MORE_OPERATOR or
    op == TokenType.MORE_OR_EQUAL_OPERATOR or
    op == TokenType.LESS_OPERATOR or
    op == TokenType.LESS_OR_EQUAL_OPERATOR then
        return 'boolean'
    end
    if inbuildOperations[termOneType .. ':' .. op .. ':' .. termTwoType] then
        return inbuildOperations[termOneType .. ':' .. op .. ':' .. termTwoType];
    end
    if SemanticState.declaredOperations[termOneType .. ':' .. op .. ':' .. termTwoType] then
        return SemanticState.declaredOperations[termOneType .. ':' .. op .. ':' .. termTwoType];
    end
    SemanticState.errors[#SemanticState.errors+1] = 'invalid operation between types ' .. termOneType .. ' and ' .. termTwoType;
    return 'any';
end

local function level(token)
    if 
    token == TokenType.CARET_OPERATOR 
    then
        return 8;
    elseif
    token == TokenType.NOT_KEYWORD or
    token == TokenType.UNARY_MINUS_OPERATORs
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
        return 4;
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

local function validateCast(original, castTo, SemanticState)
    if not (basicTypes[castTo] or SemanticState.declaredTypes[castTo]) then
        addNewError('Type ' .. castTo .. ' was not declared', SemanticState);
        return;
    end
    if original == castTo then
        return nil;
    end
    if castTo == 'any' then
        if SemanticState.declaredTypes[original] then
            return 'deepcopy';
        end
        return nil;
    end
    if original == 'any' then
        if basicTypes[castTo] then
            return 'check';
        end
        addNewError('Variables of type any can only be cast to primitve Types', SemanticState);
        return;
    end
    if basicTypes[original] and basicTypes[castTo] then
            addNewError('Cannot cast from one primitive type to another (' .. original .. ' to ' .. castTo .. ')', SemanticState);
        return;
    end
    if basicTypes[original] and SemanticState.declaredTypes[castTo] then
            addNewError('Cannot cast from primitive to declared types', SemanticState);
            return;
    end
    if SemanticState.declaredTypes[original] and basicTypes[castTo] then
        if castTo == 'table' then
            return 'deepcopy';
        else
            addNewError('Cannot cast from declared type to primitve types other than table', SemanticState);
            return;
        end
    end
    if SemanticState.declaredTypes[original] and SemanticState.declaredTypes[castTo] then
        if SemanticState.declaredTypes[original].castTo[castTo] then
            return nil;
        else
            if SemanticState.declaredTypes[castTo].castTo[original] then
                return 'check';
            else
                addNewError('No corelation found between tpyes ' .. original .. ' and ' .. castTo, SemanticState);
            end
        end
    end
end

local validateConstructorCall;
local resolveVarType;
local resolveExpType;
local function recursivePolish(exp, stack, SemanticState)
    if(exp.exp.node == NodeType.PARAN_EXP_NODE) then
        stack:push(TokenType.LEFT_PARAN_MARK);
        recursivePolish(exp.exp.exp, stack, SemanticState);
        while stack.top ~= TokenType.LEFT_PARAN_MARK do
            SemanticState.polish[#SemanticState.polish+1] = stack.top;
            stack:pop();
        end
        stack:pop();
        return;
    elseif exp.exp.node == NodeType.CAST_NODE then
        local castTo =  exp.exp.castTo;
        local currentType = resolveExpType(exp.exp.exp, SemanticState);
        local castSafety = validateCast(currentType, castTo, SemanticState);
        exp.exp.safety = castSafety;
        exp.exp.type = castTo;
        exp.exp.traversed = true;
    elseif exp.exp.node == NodeType.CAST_CHECK_NODE then
        local castTo =  exp.exp.castTo;
        local currentType = resolveExpType(exp.exp.exp, SemanticState);
        local castSafety = validateCast(currentType, castTo, SemanticState);
        if castSafety then
            castSafety = 'validate';
        end
        exp.exp.safety = castSafety;
        exp.exp.type = 'boolean';
        exp.exp.traversed = true;
    elseif exp.exp.valType == 'var' then
        exp.exp.type = resolveVarType(exp.exp.value, SemanticState);
    elseif exp.exp.valType == 'functioncall' then
        exp.exp.value.suffix[# exp.exp.value.suffix + 1] = exp.exp.value.call;
        exp.exp.type = resolveVarType(exp.exp.value, SemanticState);
        exp.exp.value.suffix[# exp.exp.value.suffix] = nil;
    end
    if exp.op and exp.op.node == NodeType.UNOP_NODE then
        local _, depth = getTypeAndDepth(exp.exp.type);
        local termType = exp.exp.type;
        if depth > 0 then termType = 'table' end;
        local resultedType = inbuildOperations[exp.op.symbol .. ':' .. termType];
        if resultedType then
            SemanticState.polish[#SemanticState.polish+1] = resultedType;
        elseif exp.exp.type ~= 'any' then
            SemanticState.polish[#SemanticState.polish+1] = 'any';
            addNewError('Unary operator ' .. exp.op.value .. ' not implemented for ' .. exp.exp. type, SemanticState);
        end
        return
    end;
    SemanticState.polish[#SemanticState.polish+1] = exp.exp.type;
    if exp.op then
        local symbol = exp.op.binop.symbol;
        if stack.top == nil then
            stack:push(symbol);
        else
            while stack.top and level(symbol) <= level(stack.top) do
                SemanticState.polish[#SemanticState.polish+1] = stack.top;
                stack:pop();
            end
            stack:push(symbol);
        end
        recursivePolish(exp.op.term, stack, SemanticState);
    end
end

local function validateFunctionCall(functionParams, callArgs, SemanticState)
    for index, paramType in ipairs(functionParams) do
        if paramType ~= 'any' then
            if callArgs[index] then
                local argType = resolveExpType(callArgs[index], SemanticState);
                if argType ~= paramType then
                    addNewError('Tried to call function with ' .. argType .. ' on param of type ' .. paramType, SemanticState);
                end
            else
                addNewError('Tried to call function with nil on param of type ' .. paramType, SemanticState);
            end
        end
    end
    for i = #functionParams + 1, #callArgs, 1 do
        local argType = resolveExpType(callArgs[i], SemanticState);
        if SemanticState.declaredTypes[argType] then
            callArgs[i].safety = 'deepcopy';
        end
    end
end

local function resolveIndexType(type, suffix, prefixId, SemanticState)
    local lastId = '#';
    local lastType = '#';
    local depth;
    local nilSafe = true;
    for index, suff in ipairs(suffix) do
        if type == 'any' then return 'any' end;
        type, depth = getTypeAndDepth(type);
        if depth == 0 then
            if suff.node == NodeType.POINT_INDEX_NODE or suff.node == NodeType.SELF_CALL_NODE then
                local isClass, className = getClassName(type);
                if SemanticState.declaredTypes[type] or SemanticState.declaredTypes[className] then
                    lastId = suff.id;
                    lastType = className or type;
                    local field;
                    if not isClass then
                        field = SemanticState.declaredTypes[type].fields[suff.id] or SemanticState.declaredTypes[type].abstractMethods[suff.id];
                    else
                        field = SemanticState.declaredTypes[className].static[suff.id];
                    end
                        if not field then
                        addNewError('Field ' .. suff.id .. ' not found on type ' .. type, SemanticState);
                        type = 'any';
                    else
                        type = field.type or 'any';
                    end
                elseif type == 'table' or type == 'any' then
                    type = 'any';
                else
                    addNewError('Cannot index type ' .. type, SemanticState);
                    type = 'any';
                end
                if suff.node == NodeType.SELF_CALL_NODE then
                    if type == 'member_function' or type == 'static_function' or type == 'logic_member_function' then
                        if type == 'member_function' or type == 'logic_member_function' then
                            local functype = type;
                            type = SemanticState.declaredTypes[lastType].fields[lastId].returnType or 'any';
                            if functype == 'logic_member_function' then
                                suff.switchToPoint = true;
                            end
                            validateFunctionCall(SemanticState.declaredTypes[lastType].fields[lastId].params, suff.args, SemanticState)
                        else
                            type = SemanticState.declaredTypes[lastType].static[lastId].returnType or 'any';
                            validateFunctionCall(SemanticState.declaredTypes[lastType].static[lastId].params, suff.args, SemanticState)
                        end
                        lastId = '#';
                        lastType = '#';
                    else
                        type = 'any';
                    end
                end
            elseif suff.node == NodeType.CALL_NODE then
                if type == 'member_function' or type == 'static_function' then
                    addNewError('Member or static functions should be called with ":"', SemanticState);
                    type = 'any';
                elseif type == 'function' or type == 'logic_function' then
                    if prefixId then
                        local _, returnType, params = resolveVarScopeType(prefixId, false, SemanticState);
                        validateFunctionCall(namelistToTypelist(params, SemanticState), suff.args, SemanticState)
                        type = returnType or 'any';
                    else
                        type = 'any';
                    end
                elseif type == 'any' then
                    type = 'any';
                else
                    addNewError('Cannot call type ' .. type, SemanticState);
                    type = 'any';
                end
            elseif suff.node == NodeType.BRACKET_INDEX_NODE then
                if type == 'table' then
                    type = 'any';
                elseif SemanticState.declaredTypes[type] then
                    addNewError('Cannot access class fields with brackets', SemanticState);
                    type = 'any';
                else
                    addNewError('Cannot bracket index type ' .. type);
                    type = 'any';
                end
            end
        else
            if suff.node ~= NodeType.BRACKET_INDEX_NODE then
                addNewError('Homogenous structures should be accessed with brackets', SemanticState);
                type = 'any';
            else
                depth = depth - 1;
                if depth > 0 then
                    type = type .. '|' .. depth;
                end
                suff.nilSafe = type;
            end
        end
        prefixId = suff.id;
    end
    return type, nilSafe;
end

resolveExpType = function(exp, SemanticState)
    if exp == nil then
        return 'any';
    end
    if exp.node == NodeType.LAMBDA_FUNC_NODE then
        exp.traversed = true;
        return 'function';
    end
    SemanticState.polish = {};
    local stack = utils.createStack();
    recursivePolish(exp, stack, SemanticState);
    while stack.top do
        SemanticState.polish[#SemanticState.polish+1] = stack.top;
        stack:pop();
    end
    local stack = utils.createStack();
    for key, value in pairs(SemanticState.polish) do
        if type(value) == 'string' then
            stack:push(value);
        else
            local term2 = stack.top;
            stack:pop();
            local term1 = stack.top;
            stack:pop();
            stack:push(operationType(term1, value, term2, SemanticState));
        end
    end
    exp.traversed = true;
    return stack.top;
end

local function validateTableType(table, varType, depth, SemanticState)
    for index, field in ipairs(table.fieldlist) do
        local fieldType = resolveExpType(field.exp, SemanticState);
        if depth == 0 then
            if fieldType ~= varType and fieldType ~= 'nil' then
                addNewError('Wrong type ' .. fieldType .. ' in structure of type ' .. varType, SemanticState);
            end
        else
            if fieldType ~= 'table' and fieldType ~= 'nil' and fieldType ~= (varType .. '|' .. depth) then
                addNewError('Wrong type ' .. fieldType .. ', ' ..varType .. '|'.. depth .. ' expected', SemanticState);
            else
                if fieldType == 'table' and field.node == NodeType.TABLE_CONSTRUCTOR_NODE or field.node == NodeType.EXP_WRAPPER_NODE then
                    validateTableType(field.exp.exp.value, varType, depth - 1, SemanticState);
                else
                    addNewError('Cannot initialize homogenous structure with non homogenous table', SemanticState);
                end
            end
        end
    end
end

local function validateAssignedType(left, right, SemanticState)
    local expressionType = resolveExpType(right, SemanticState);

    if not left.type then left.type = 'any' end;
    local varType, depth = getTypeAndDepth(left.type);
    if depth > 0 and expressionType == 'table' then
        validateTableType(right.exp.value, varType, depth - 1, SemanticState);
    elseif left.type ~= 'any' then
        if expressionType == 'nil' then
            right.node = NodeType.DEFAULT_PLACEHOLDER_NODE;
            right.type = left.type;
        elseif left.type ~= expressionType then
            addNewError('Wrong type ' .. expressionType .. ' assgined to ' .. left.type, SemanticState);
        end
    end
end

local function appendLinkResultToState(linkResult, SemanticState)
    for key, value in pairs(linkResult.types) do
        if SemanticState.declaredTypes[key] then
            addNewError('Type ' .. key .. ' was already declared');
        else
            SemanticState.declaredTypes[key] = value;
        end
    end
end

resolveVarType = function(var, SemanticState)
    local type = nil;
    if var.node == NodeType.FUNCTION_CALL_NODE then
        if var.prefix == 'requireELA' and (var.suffix and #var.suffix == 1) and (not var.isThis) then
            if #var.call.args == 1 and (not var.call.args[1].op) and var.call.args[1].exp.type == 'string' then 
                local linkResult = linker.linkElaFile(var.call.args[1].exp.value);
                if not linkResult then
                    addNewError('Could not link module ' .. var.call.args[1].exp.value, SemanticState);
                else
                    appendLinkResultToState(linkResult, SemanticState);
                end
                var.traversed = true;
                var.isRequire = true;
                return;
            end
        end
    end
    if var.prefix and var.prefix.exp and var.node == NodeType.VAR_NODE then
        type = resolveExpType(var.prefix.exp, SemanticState);
    else
        type = resolveVarScopeType(var.id or var.prefix, var.isThis, SemanticState) or 'any';
    end
    if var.suffix then
        local prefixType, depth = getTypeAndDepth(type);
        if type ~= 'table' and type ~= 'any' and (not SemanticState.declaredTypes[type]) and type ~= 'function' and depth == 0 and (not getClassName(type)) then
            addNewError('illegal index of prefix of type ' .. type, SemanticState);
        else
            type = resolveIndexType(type, var.suffix, (var.id or var.prefix), SemanticState);
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

local function validate_declared_type(var, SemanticState)
    if var.type == nil then
        var.type = 'any';
    end
    local flatType = getTypeAndDepth(var.type);
    if (not basicTypes[flatType]) and (not SemanticState.declaredTypes[flatType]) then 
        addNewError('Type ' .. flatType .. ' was not declared!', SemanticState);
        var.type = 'any';
        return false;
    end
    return true;
end

local function addConstructor(classID, ctrNode, SemanticState)
    if ctrNode.body.type then
       addNewError('constructors cannot have explicit return types', SemanticState);
       ctrNode.body.type = nil;
    end
    local typesList = namelistToTypelist(ctrNode.body.parlist.namelist or {}, SemanticState);
    if ctrNode.body.parlist.isTriple then
        addNewError('Constructors should have fixed number of parameters', SemanticState)
    end
    for index, var in ipairs(ctrNode.body.parlist.namelist or {}) do
        if SemanticState.declaredTypes[classID].inheritParams[var.id] then
            addNewError('Base class parameters are injected in constructors implicitly, remove the explicit parameter with same name ' .. var.id, SemanticState);
        end 
    end
    local valid = true;
    for key, cst in ipairs(SemanticState.declaredTypes[classID].constructors) do
        if equivalentArgs(cst, typesList) then
            addNewError('ambiguity in the declaration of constructors', SemanticState)
            valid = false;
        end
    end
    if valid then
        SemanticState.declaredTypes[classID].constructors[#SemanticState.declaredTypes[classID].constructors+1] = typesList;
    end
end

local function declareClass(classDecNode, SemanticState)
    if SemanticState.declaredTypes[classDecNode.id] ~= nil or basicTypes[classDecNode.id] ~= nil then
        addNewError('found redeclaration of type ' .. classDecNode.id, SemanticState);
        return;
    end
    SemanticState.declaredTypes[classDecNode.id] = {constructors = {}, fields = {}, inheritParams = {}, abstractMethods = {}, castTo = {}, static = {}, abstractCount = 0};
    if classDecNode.baseClassId then
        SemanticState.declaredTypes[classDecNode.id].fields = utils.deepCopy(SemanticState.declaredTypes[classDecNode.baseClassId].fields);
        SemanticState.declaredTypes[classDecNode.id].static = utils.deepCopy(SemanticState.declaredTypes[classDecNode.baseClassId].static);
        SemanticState.declaredTypes[classDecNode.id].castTo = {[classDecNode.baseClassId] = true;};
        local currentCastTo = SemanticState.declaredTypes[classDecNode.id].castTo;
        for castType, _ in pairs(SemanticState.declaredTypes[classDecNode.baseClassId].castTo) do
            currentCastTo[castType] = true;
        end
        local baseClassTypeList = namelistToTypelist(classDecNode.baseClassArgs, SemanticState);
        for index, var in ipairs(classDecNode.baseClassArgs) do
            SemanticState.declaredTypes[classDecNode.id].inheritParams[var.id] = {type = var.type or 'any'};
        end
        local baseCst = SemanticState.declaredTypes[classDecNode.baseClassId].constructors;
        local foundCst = nil;
        for index, cst in ipairs(baseCst) do
            if equivalentArgs(cst, baseClassTypeList) then
                foundCst = index;
            end
        end
        if not foundCst then addNewError("Cannot resolve constructor for base class " .. classDecNode.baseClassId .. ' of ' .. classDecNode.id, SemanticState) end;
        classDecNode.IndexOfBaseConstructor = foundCst;
    end
    local abstractsImplemented = {};
    local abstractsImplementedCount = 0;
    for index, stat in ipairs(classDecNode.stats) do
        if stat.node == NodeType.CONSTRUCTOR_NODE then
            addConstructor(classDecNode.id, stat, SemanticState);
        elseif stat.node == NodeType.ABSTRACT_METHOD_NODE then
            if not SemanticState.declaredTypes[classDecNode.id].fields[stat.id] and (not SemanticState.declaredTypes[classDecNode.id].static[stat.id]) then
                local abstracts = SemanticState.declaredTypes[classDecNode.id].abstractMethods;
                SemanticState.declaredTypes[classDecNode.id].abstractCount = SemanticState.declaredTypes[classDecNode.id].abstractCount + 1;
                classDecNode.isAbstract = true;
                abstracts[stat.id] = {type = 'member_function', returnType = stat.type, params = (stat.params.namelist or {})};
                SemanticState.declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = stat.type, params = (stat.params.namelist or {})};
            else
                addNewError('Field redeclaration for ' .. stat.id .. ' in class ' .. classDecNode.id, SemanticState);
            end
        elseif stat.node == NodeType.MEMBER_FUNCTION_NODE or stat.node == NodeType.LOGIC_BLOCK_NODE then
            if not SemanticState.declaredTypes[classDecNode.id].fields[stat.id] and (not SemanticState.declaredTypes[classDecNode.id].static[stat.id]) then
                if not stat.static then
                    if stat.node == NodeType.LOGIC_BLOCK_NODE then
                        SemanticState.declaredTypes[classDecNode.id].fields[stat.id] = {type = 'logic_member_function', returnType = (stat.body or {}).type, params = namelistToTypelist(stat.args or {}, SemanticState)};
                    else
                        SemanticState.declaredTypes[classDecNode.id].fields[stat.id] = {type = 'member_function', returnType = (stat.body or {}).type, params = namelistToTypelist(stat.body.parlist.namelist or {}, SemanticState)};
                    end
                else
                    if stat.node == NodeType.LOGIC_BLOCK_NODE then
                        SemanticState.declaredTypes[classDecNode.id].static[stat.id] = {type = 'logic_member_function', returnType = (stat.body or {}).type, params = namelistToTypelist(stat.args or {}, SemanticState)};
                    else
                        SemanticState.declaredTypes[classDecNode.id].static[stat.id] = {type = 'static_function', returnType = (stat.body or {}).type, params = namelistToTypelist((stat.args or stat.body.parlist.namelist) or {}, SemanticState)};
                    end
                end
            else
                if classDecNode.baseClassId and (not stat.static) then
                    if SemanticState.declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id] and not abstractsImplemented[stat.id] then
                        if equivalentArgs(
                            namelistToTypelist(SemanticState.declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id].params or {}, SemanticState), 
                            namelistToTypelist((stat.args or stat.body.parlist.namelist) or {}, SemanticState)
                        )
                        and
                            (SemanticState.declaredTypes[classDecNode.baseClassId].abstractMethods[stat.id].returnType or 'any')
                            ==
                            ((stat.body or {}).type or 'any')
                        then
                            abstractsImplemented[stat.id] = true;
                            abstractsImplementedCount = abstractsImplementedCount + 1;
                        else
                            addNewError('Signature for ' .. stat.id .. ' was not respected', SemanticState);
                        end
                    end
                else
                    addNewError('Field redeclaration for ' .. stat.id .. ' in class ' .. classDecNode.id, SemanticState);
                end
            end
        elseif stat.node == NodeType.CLASS_FIELD_DELCARATION_NODE then
            if not stat.right then stat.right = {node = NodeType.EXPLIST_NODE} end;
            for index, field in ipairs(stat.left) do
                field.type = field.type or 'any';
                validate_declared_type(field, SemanticState);
                if not SemanticState.declaredTypes[classDecNode.id].fields[field.id] and (not SemanticState.declaredTypes[classDecNode.id].static[field.id]) then
                    if stat.right and stat.right[index] then
                        validateAssignedType(field, stat.right[index], SemanticState);
                        SemanticState.declaredTypes[classDecNode.id].fields[field.id] = {type = field.type};
                    elseif field.type ~= 'any' and (not SemanticState.defaults[field.type]) then
                        addNewError('No default value found for ' .. field.type, SemanticState);
                    else
                        if field.type == 'any' then
                            stat.right[index] = { exp = { value = 'nil', type = 'nil'}, node = 33}
                        else
                            stat.right[index] = {node = NodeType.DEFAULT_PLACEHOLDER_NODE, type = field.type};
                        end
                        if not stat.static then
                            SemanticState.declaredTypes[classDecNode.id].fields[field.id] = {type = field.type or 'any'};
                        else
                            SemanticState.declaredTypes[classDecNode.id].static[field.id] = {type = field.type or 'any'};
                        end
                    end
                else
                    addNewError('Field redeclaration for ' .. field.id .. ' in class ' .. classDecNode.id, SemanticState);
                end
            end
        end
    end
    if classDecNode.baseClassId and abstractsImplementedCount ~= SemanticState.declaredTypes[classDecNode.baseClassId].abstractCount then
        addNewError('Not all abstract methods of base class ' .. classDecNode.baseClassId .. ' were implemented', SemanticState);
    end
    classDecNode.fields = SemanticState.declaredTypes[classDecNode.id].fields;
end

local function checkDeclarationNode(currentNode, child, SemanticState)
    for index, var in ipairs(child.left) do
        --NEW DECLARED Local
        child.right = child.right or {};
        if not SemanticState.currentScope[var.id] then
            validate_declared_type(var, SemanticState);
            SemanticState.currentScope[var.id] = {type = var.type};
        else
            if not var.type then var.type = 'any' end;
            if var.type ~= SemanticState.currentScope[var.id].type then
                addNewError('Redefinition in the same scope of variable ' .. var.id .. ' with different type ' .. '(was ' .. SemanticState.currentScope[var.id].type .. ', now is ' .. var.type .. ' )', SemanticState);
            end
        end
        local right = child.right[index];
        if (not right) and (not SemanticState.defaults[var.type]) then
            if var.type ~= 'any' then
                addNewError('No default value found for ' .. var.type, SemanticState);
            else
                child.right[index] ={ exp = { value = 'nil', type = 'nil'}, node = 33}
            end
        else
            if right then
                validateAssignedType(var, right, SemanticState); 
            else
                child.right[index] = {node = NodeType.DEFAULT_PLACEHOLDER_NODE, type = var.type};
            end
        end
    end
end

local function checkAssignmentNode(assignment, SemanticState)
    assignment.right = assignment.right or {node = NodeType.EXPLIST_NODE};
    for index, var in ipairs(assignment.left) do
        local type = resolveVarType(var, SemanticState);
        local right = assignment.right[index];
        if (not right) and type ~= 'any' then
            addNewError('Static variable was assigned nil', SemanticState);
        else
            if right then
                local leftType = resolveVarType(var, SemanticState);
                local rightType = resolveExpType(right, SemanticState);
                local varType, depth = getTypeAndDepth(leftType);
                if depth > 0 and rightType == 'table' then
                    validateTableType(right.exp.value, varType, depth - 1, SemanticState);
                elseif leftType ~= 'any' and leftType ~= rightType then
                    if rightType == 'nil' then
                        assignment.right[index] = {node = NodeType.DEFAULT_PLACEHOLDER_NODE, type = leftType};
                    else
                        local rightFlatType, rightDepth = getTypeAndDepth(rightType);
                        if rightDepth > 0 and rightFlatType == leftType then
                        else
                            addNewError('Wrong type ' .. rightType .. ' assigned to ' .. leftType, SemanticState);
                        end
                    end
                end
            end
        end
    end
end

validateConstructorCall = function(call_stat, declarations_list, SemanticState)
    local typeList = {};
    for key, arg in ipairs(call_stat.args) do
        local type = resolveExpType(arg, SemanticState);
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
    addNewError('no constructor found with args ' .. errorTypes, SemanticState)
    return 'any';
end

local function validateOverload(overload, SemanticState)
    local typelist = namelistToTypelist(overload.body.parlist.namelist, SemanticState);
    for index, value in ipairs(typelist) do
        if value == 'any' then
            addNewError('Cannot overload operator for type any', SemanticState);
            return;
        end
        if (not SemanticState.declaredTypes[value]) and (not basicTypes[value]) then
            return;
        end
    end
    if overload.node == NodeType.BINARY_OPERATOR_OVERLOAD_NODE then
        local key = typelist[1] .. ':' .. overload.op .. ':' .. typelist[2];
        if not (SemanticState.declaredTypes[typelist[1]] or SemanticState.declaredTypes[typelist[2]]) then
            addNewError('At least the #1 argument in overloading should be a class', SemanticState);
        end
        overload.type1 = typelist[1];
        overload.type2 = typelist[2];
        if not inbuildOperations[key] or SemanticState.declaredOperations[key] then
            SemanticState.declaredOperations[key] = overload.body.type or 'any';
            if not SemanticState.overloadsList[typelist[1]] then
                SemanticState.overloadsList[typelist[1]] = {[1] = {term = typelist[2], sign = overload.op, returnType = overload.body.type or 'any'}};
            else
                local list = SemanticState.overloadsList[typelist[1]];
                list[#list + 1] = {term = typelist[2], sign = overload.op, returnType = overload.body.type or 'any'};
            end
        else
            addNewError('Operation already defined for types ' .. typelist[1] .. ', ' .. typelist[2], SemanticState);
        end
    end
end

local function checkIfReturnsOnAllPaths(ifNode)
    for index, branch in ipairs(ifNode.branches) do
        if not branch.block.retstat.expressions then
            return 0;
        end
    end
    if not ifNode.elseBranch.block then
        return 0;
    end
    if not ifNode.elseBranch.block.retstat.expressions then
        return 0;
    end
    return 1;
end

local function validateLogicBlockNumberOfArgs(logicBlock, SemanticState)
    local numberOfArgs = #logicBlock.args;
    for index, func in ipairs(logicBlock.funcs) do
        if func.node == NodeType.LOGIC_PREDICATE_NODE then
            if numberOfArgs ~= #func.args then
                addNewError('All logic predicates should have the same number of args as the containing block ', SemanticState)
            end 
        end
    end
end

local traverse;
local function validateNodeValue(value, currentNode, key, SemanticState)
    if type(value) == 'table' then
        --LOCAL DECLARATION
        if value.node == NodeType.LOCAL_DECLARATION_NODE then
            checkDeclarationNode(currentNode, value, SemanticState);
        end

        if value.node == NodeType.ASSIGNMENT_NODE then
            checkAssignmentNode(value, SemanticState);
        end

        if value.node == NodeType.CLASS_DECLARATION_NODE then
            declareClass(value, SemanticState);
        end

        if value.node == NodeType.FUNCTION_CALL_NODE then
            if not value.traversed then
                value.suffix[#value.suffix + 1] = value.call;
                resolveVarType(value, SemanticState);
                value.suffix[#value.suffix] = nil;
            end
        end

        if value.node == NodeType.VAR_NODE then
            if not value.traversed then
                resolveVarType(value, SemanticState);
            end
        end

        if value.node == NodeType.EVALUABLE_NODE then
            if not value.traversed then
                resolveExpType(value, SemanticState);
            end
        end

        if value.node == NodeType.FUNCTION_DECLARATION_NODE then
            if value.body.type then
                addNewError('functions can be declared with return type only on local declaration', SemanticState);
            end
            for index, param in ipairs(value.body.parlist.namelist or {}) do
                if param.type then
                    addNewError('functions can be declared with typed parameters only on local declaration', SemanticState);
                    return;
                end
            end
        end

        if value.node == NodeType.LOCAL_FUNCTION_DECLARATION_NODE then
            local params = nil 
            if value.body.parlist.namelist then
                params = namelistToTypelist(value.body.parlist.namelist, SemanticState);
            end
            SemanticState.currentScope[value.id] = {type = 'function', returnType = value.body.type, params = value.body.parlist.namelist or {}};
        end

        if value.node == NodeType.CAST_NODE then
            if not value.traversed then
                value.safety = validateCast(resolveExpType(value.exp, SemanticState), value.castTo, SemanticState);
            end
        end

        if value.node == NodeType.DEFAULT_SET_NODE then
            local flatType, depth = getTypeAndDepth(value.type);
            if (not SemanticState.declaredTypes[flatType]) and (not basicTypes[flatType]) and value.type ~= 'any' then
                addNewError('Cannot resolve type ' .. value.type, SemanticState);
            end
            local assignedType = resolveExpType(value.exp, SemanticState);
            if depth > 0 and assignedType == 'table' and value.exp.exp.value.node == NodeType.TABLE_CONSTRUCTOR_NODE or value.exp.exp.value.node == NodeType.EXP_WRAPPER_NODE then
                validateTableType(value.exp.exp.value, flatType, depth - 1, SemanticState);
                SemanticState.defaults[value.type] = true;
            elseif value.type ~= assignedType then
                addNewError('Cannot set default of type ' .. value.type .. ' to an expression of type ' .. assignedType, SemanticState);
            else
                SemanticState.defaults[value.type] = true;
            end
        end

        if value.node == NodeType.RETURN_NODE then
            if not SemanticState.inControlStucture then
                SemanticState.currentReturnScopeReturnCertitudes = SemanticState.currentReturnScopeReturnCertitudes + 1; 
            end
            if SemanticState.currentReturnScope == 'any' then
                return;
            elseif #value.expressions > 1 then
                addNewError('Strong typed blocks can only return one value', SemanticState);
                return;
            end
            local returnType = resolveExpType(value.expressions[1], SemanticState);
            if SemanticState.currentReturnScope ~= 'any' and returnType ~= SemanticState.currentReturnScope then
                addNewError('Wrong type ' .. returnType .. ' returned by block, ' .. SemanticState.currentReturnScope .. ' expected', SemanticState);
            end
        end

        --CLASSES
        if value.node == NodeType.INSTANTIATION_NODE then
            if not SemanticState.declaredTypes[value.id] then addNewError('No declaration found for type ' .. value.id, SemanticState) return end
            if SemanticState.declaredTypes[value.id].abstractCount > 0 then addNewError('Cannot instantiate abstract class ' .. value.id, SemanticState) end
            validateConstructorCall(value, SemanticState.declaredTypes[value.type].constructors, SemanticState);
        end

        if value.node == NodeType.BINARY_OPERATOR_OVERLOAD_NODE or value.node == NodeType.UNARY_OPERATOR_OVERLOAD_NODE then
            validateOverload(value, SemanticState);
        end

        if value.node == NodeType.LOGIC_ALIAS_NODE then
            local varType = resolveVarType(value.var, SemanticState);
            if varType == 'logic_member_function' or varType == 'logic_function' then
                SemanticState.logicAliasses[value.alias] = {var = value.var};
            else
                addNewError('Can only alias logic functions in logic block, got ' .. varType .. ' instead', SemanticState)
            end
        end

        if value.node == NodeType.LOGIC_FUNCTION_CALL_NODE then
            if SemanticState.logicAliasses[value.id] then
                value.replaceWith = SemanticState.logicAliasses[value.id].var;
                value.shouldBeSelf = SemanticState.logicAliasses[value.id].shouldBeSelf;
            end
        end

        if value.node == NodeType.FUNC_BODY_NODE or value.node == NodeType.DO_BLOCK_NODE then
            local nextScope = {};

            local oldReturnScope = SemanticState.currentReturnScope;
            local oldInConstrolStructure = SemanticState.inControlStucture;
            local oldReturnScopeReturnCertitudes =  SemanticState.currentReturnScopeReturnCertitudes;
            
            if value.node == NodeType.FUNC_BODY_NODE then
                for index, var in ipairs(value.parlist.namelist or {}) do
                    nextScope[var.id] = {type = var.type or 'any'};
                end
                SemanticState.currentReturnScope = value.type or 'any';
                SemanticState.inControlStucture = false;
                SemanticState.currentReturnScopeReturnCertitudes = 0;
            end
            nextScope.father = SemanticState.currentScope;
            SemanticState.currentScope = nextScope;
            traverse(value, SemanticState);

            if value.node == NodeType.FUNC_BODY_NODE then
                if value.type and value.type ~= 'any' then
                    if SemanticState.currentReturnScopeReturnCertitudes == 0 then
                        addNewError('Not all paths return values in strongly typed block', SemanticState);
                    end
                end
                SemanticState.currentReturnScope = oldReturnScope;
                SemanticState.inControlStucture = oldInConstrolStructure;
                SemanticState.currentReturnScopeReturnCertitudes = oldReturnScopeReturnCertitudes;
            end

            SemanticState.currentScope = SemanticState.currentScope.father;
        elseif value.node == NodeType.CLASS_DECLARATION_NODE then
            SemanticState.currentClass = value.id;
            local nextScope = {};
            if value.baseClassId then
                for index, var in ipairs(value.baseClassArgs) do
                    nextScope[var.id] = {type = var.type or 'any'};
                end
            end
            nextScope.father = SemanticState.currentScope;
            SemanticState.currentScope = nextScope;
            traverse(value, SemanticState);
            SemanticState.currentScope = SemanticState.currentScope.father;
            SemanticState.currentClass = nil;
        elseif 
            value.node == NodeType.WHILE_LOOP_NODE or
            value.node == NodeType.FOR_CONTOR_LOOP_NODE or
            value.node == NodeType.FOR_IN_LOOP_NODE or
            value.node == NodeType.IF_NODE or
            value.node == NodeType.REPEAT_LOOP_NODE or
            value.node == NodeType.LAMBDA_FUNC_NODE
        then
            local nextScope = {};
            nextScope.father = SemanticState.currentScope;
            SemanticState.currentScope = nextScope;
            local oldSemanticStateInConstrolStructure = SemanticState.inControlStucture;
            SemanticState.inControlStucture = true;
            traverse(value, SemanticState);
            if value.node == NodeType.IF_NODE then
                SemanticState.currentReturnScopeReturnCertitudes = SemanticState.currentReturnScopeReturnCertitudes + checkIfReturnsOnAllPaths(value);
            end
            SemanticState.inControlStucture = oldSemanticStateInConstrolStructure;
            SemanticState.currentScope = SemanticState.currentScope.father;
        elseif value.node == NodeType.LOGIC_BLOCK_NODE then
            if value.isLocal then
                SemanticState.currentScope[value.id] = {type = 'logic_function'};
            elseif not SemanticState.currentClass then
                addNewError('Logic blocks should be local ', SemanticState);
            end
            validateLogicBlockNumberOfArgs(value, SemanticState);
            traverse(value, SemanticState);
            SemanticState.logicAliasses = {};
        else
            if key ~= 'namelist' then
                traverse(value, SemanticState); 
            end
        end
    end
end

traverse = function(currentNode, SemanticState)
    if currentNode.node == NodeType.BLOCK_NODE then
        validateNodeValue(currentNode.stats, currentNode, 'stats', SemanticState);
        validateNodeValue(currentNode.retstat, currentNode, 'retstat', SemanticState);
        return;
    end
    for key, value in pairs(currentNode) do
        validateNodeValue(value, currentNode, key, SemanticState);
    end
end

function Semantic.check(ast, exportedType)

    local SemanticState = {};

    SemanticState.currentScope = {};
    SemanticState.polish = {};
    SemanticState.currentClass = nil;
    SemanticState.currentReturnScope = exportedType or 'any';
    SemanticState.currentReturnScopeReturnCertitudes = 0;
    SemanticState.inControlStucture = false;
    SemanticState.errors = {}
    SemanticState.logicAliasses = {};
    
    SemanticState.declaredOperations = {};
    SemanticState.overloadsList = {};
    SemanticState.declaredTypes = {};

    SemanticState.defaults = {
        ['number'] = true;
        ['string'] = true;
        ['boolean'] = true;
        ['table'] = true;
        ['function'] = true;
        ['thread'] = true;
    };

    if ast == nil then
        return;
    end
    traverse(ast, SemanticState);

    if SemanticState.currentReturnScope ~= 'any' and SemanticState.currentReturnScopeReturnCertitudes == 0 then
        print(exportedType);
        addNewError('Not all paths return values on module level',  SemanticState)
    end

    if #SemanticState.errors > 0 then
        print(#SemanticState.errors .. ' semantic errors');
        print(utils.dump(SemanticState.errors)); 
    end
    if #SemanticState.errors > 0 then
        return nil;
    else
        return {types = SemanticState.declaredTypes}
    end
end

return Semantic;