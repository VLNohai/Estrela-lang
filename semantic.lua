Utils = require('utils');
NodeType = require('tokens').NodeType;
Semantic = {};

Globals = {};
local errors = {};
local polish = {};
local stack = {};

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

local function addNewError(message)
    errors[#errors+1] = {message = message};
end

local function operationType(termOneType, op, termTwoType)
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
    token == TokenType.DOUBLE_POINT_MARK
    then
        return 2;
    end
    if 
    token == TokenType.STAR_OPERATOR or   
    token == TokenType.SLASH_OPERATOR
    then
        return 3;
    end
    print('returned nil for some reason');
end

local validateCall;
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
    elseif exp.exp.type == 'var' then
        exp.exp = exp.exp.value;
        if Globals[exp.exp.id] then
            exp.exp.type = Globals[exp.exp.id].type;
        else
            exp.exp.type = 'nil';
        end
    elseif exp.exp.type == 'functioncall' then
        exp.exp = exp.exp.value;
        exp.exp.type = validateCall(exp.exp, Globals[exp.exp.prefix].args);
        print('function type became ' .. exp.exp.type);
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

local function resolveType(exp)
    print('next type ' .. utils.dump(exp));
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
            print('in recusive polish value was ' .. value);
            stack:push(value);
        else
            local term2 = stack.top;
            stack:pop();
            local term1 = stack.top;
            stack:pop();
            stack:push(operationType(term1, value, term2));
        end
    end
    print('concluded as ' ..stack.top);
    return stack.top;
end

local function validateAssignedType(left, right)
    local checkAtRuntime = true;
    local expressionType = resolveType(right);
    if expressionType ~= 'any' and left.type ~= 'any' and
    left.type ~= expressionType then
        addNewError('wrong type ' .. expressionType .. ' assgined to ' .. left.type);
    end
    if expressionType ~= 'any' then
        checkAtRuntime = false;
    end
    return checkAtRuntime;
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
        return true;
    end
    if basicTypes[var.type] == nil and declaredTypes[var.type] == nil then 
        addNewError('Type ' .. var.type .. ' was not declared!');
        var.type = 'any';
        return false;
    end
    return true;
end

local function validateFunctionDeclaration(funcNode, isConstructor)
    local parameters = funcNode.body.parlist.namelist or {};
    local isTriple = funcNode.body.parlist.isTriple;
    local typesList = {};
    local parNames = {};
    for index, parameter in ipairs(parameters) do
        local parType = parameter.type or 'any';
        if parNames[parameter.id] ~= nil then
            addNewError('Parameter names must be unique');
        end
        parNames[parameter.id] = true;
        typesList[#typesList+1] = parType;
    end
    if isTriple then
        typesList[#typesList+1] = 'repeat';
    end
    if not isConstructor then
        validate_declared_type(funcNode.body);
    end
    return typesList;
end

local function addConstructor(classID, ctrNode)
    if ctrNode.body.type then
       addNewError('constructors cannot have explicit return types');
       ctrNode.body.type = nil;
    end
    local typesList = validateFunctionDeclaration(ctrNode, true);
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
    declaredTypes[classDecNode.id] = {constructors = {}, fields = {}};
    for index, stat in ipairs(classDecNode.stats)  do
        if stat.node == NodeType.CONSTRUCTOR_NODE then
            addConstructor(classDecNode.id, stat);
        end
    end
end

local function checkAssignmentNode(currentNode, child)
    for index, var in ipairs(child.left) do
        --NEW DECLARED GLOBAL
        if not Globals[var.id] then
            validate_declared_type(var);
            Globals[var.id] = {type = var.type};
        else
            if var.type ~= nil then
                addNewError('redefinition of global with different type!');
                goto continue;
            end
        end
        currentNode.checkAtRuntime = validateAssignedType(Globals[var.id], child.right[index]);
        ::continue::
    end
end

local function excludeExplicitTypes(node)
    for key, value in pairs(node) do
        if node.node == NodeType.TYPED_VAR_NODE then
            addNewError('Invalid use of explicit type annotation');
            return;
        end
        if type(value) == "table" then
            excludeExplicitTypes(value);
        end
    end
end

validateCall = function(call_stat, declarations_list)
    local typeList = {};
    excludeExplicitTypes(call_stat.call.args);
    for key, arg in ipairs(call_stat.call.args) do
        local type = resolveType(arg);
        typeList[#typeList+1] = type;
    end
    for key, decl in ipairs(declarations_list) do
        if equivalentArgs(decl, typeList) then
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
    if not Globals[func_stat.id[1]] then
        Globals[func_stat.id[1]] = {type = 'function', args = {[1] = args}};
    else
        local valid = true;
        for key, argsList in ipairs(Globals[func_stat.id[1]].args) do
            if equivalentArgs(args, argsList) then
                addNewError('ambiguity in function declaration');
                valid = false;
            end
        end
        if valid then
            Globals[func_stat.id[1]].args[#Globals[func_stat.id[1]].args + 1] = args;
        end
    end
end

local function traverse(currentNode)
    for key, value in pairs(currentNode) do
        if type(value) == 'table' then

            --ASSIGNMENT_NODE
            if value.node == NodeType.ASSIGNMENT_NODE then
                excludeExplicitTypes(value.right);
                checkAssignmentNode(currentNode, value);
            end
            if value.node == NodeType.CLASS_DECLARATION_NODE then
                declareClass(value);
            end

            --FUNCTION_DECLARATION_NODE
            if value.node == NodeType.FUNCTION_DECLARATION_NODE then
                declareFunction(value);
            end

            --FUNCTION_CALL_NODE
            if value.node == NodeType.FUNCTION_CALL_NODE then
                if not value.traversed then
                    validateCall(value, Globals[value.prefix].args);
                end
            end

            --LOCAL_DECLARATION_NODE
            if value.node == NodeType.LOCAL_DECLARATION_NODE then
                
            end
            if value.node == NodeType.LOCAL_FUNCTION_DECLARATION_NODE then
                
            end

            --CLASSES
            if value.node == NodeType.INSTANTIATION_NODE then
                validateCall({call = value}, declaredTypes[value.type].constructors);
            end
            traverse(value);
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