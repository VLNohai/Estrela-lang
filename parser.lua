TokenType = require('tokens').TokenType;
NodeType = require('tokens').NodeType;
Utils = require('utils');

Parser = {}

NODE = {}
LEXEMS = {}
INDEX = 1;

MAX_INDEX = -1;

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

function EQUALS(a, b)
    if a == b then
        INDEX = INDEX + 1;
        if INDEX > MAX_INDEX then
            MAX_INDEX = INDEX;
        end
        return a;
    end
    return false;
end

function SET(a, b)
    if b then
        a.val = b;
        return a.val;
    else
        return b;
    end
end

function OPTIONAL(index, ...)

    local indexCpy = index;
    local arg = {...}
    local astElements = {};

    if #arg > (#LEXEMS - INDEX + 1) then
        return {};
    end
    
    for key, value in pairs(arg) do
        local astNode = {val = nil};
        if type(value) == 'number' then
            if not SET(astNode, EQUALS(LEXEMS[INDEX].tokenType, value)) then
                INDEX = indexCpy;
                astElements[#astElements] = nil; 
                break;
            else
                astElements[#astElements + 1] = LEXEMS[INDEX - 1];
            end
        elseif type(value) == 'function' then
            if not SET(astNode, value()) then
                INDEX = indexCpy;
                astElements[#astElements] = nil;
                break;
            else
                astElements[#astElements + 1] = astNode.val;
            end
        else
            print('weird error');
        end

    end
    astElements = utils.flatten(astElements);
    return astElements;
end

function OPTIONAL_MULTIPLE(index, ...)

    local matched = true;
    local indexCpy = INDEX;
    local astElements = {};

    local arg = {...}

    if #arg > (#LEXEMS - INDEX + 1) then
        return {};
    end
    
    local repetitions = 1;
    while(matched and #arg <= (#LEXEMS - INDEX + 1)) do

        local astNode = {val = nil};
        astElements[repetitions] = {};

        for key, value in ipairs(arg) do
            if type(value) == 'number' then
                if not SET(astNode, EQUALS(LEXEMS[INDEX].tokenType, value)) then
                    INDEX = indexCpy;
                    matched = false;
                    astElements[repetitions] = nil;
                    break;
                else
                    astElements[repetitions][#astElements[repetitions] + 1] = LEXEMS[INDEX - 1];
                end
            elseif type(value) == 'function' then
                if not SET(astNode, value()) then
                    INDEX = indexCpy;
                    matched = false;
                    astElements[repetitions] = nil;
                    break;
                else
                    astElements[repetitions][#astElements[repetitions] + 1] = astNode.val;
                end
            else
                matched = false;
                break;
            end
        end

        if(matched) then
        indexCpy = INDEX;
        astElements[repetitions] = utils.flatten(astElements[repetitions]);
        repetitions = repetitions + 1;
        end
    end
    INDEX = indexCpy;
    --astElements = utils.flatten(astElements);
    return astElements;
end

function OPTIONAL_MULTIPLE_LEAVE_LAST(index, ...)

    local matched = true;
    local indexCpy = INDEX;
    local earlyIndex = INDEX;
    local astElements = {};

    local arg = {...}

    if #arg > (#LEXEMS - INDEX + 1) then
        return {};
    end
    
    local repetitions = 1;
    while(matched and #arg <= (#LEXEMS - INDEX + 1)) do

        local astNode = {val = nil};
        astElements[repetitions] = {};

        for key, value in ipairs(arg) do
            if type(value) == 'number' then
                if not SET(astNode, EQUALS(LEXEMS[INDEX].tokenType, value)) then
                    INDEX = indexCpy;
                    matched = false;
                    astElements[repetitions] = nil;
                    break;
                else
                    astElements[repetitions][#astElements[repetitions] + 1] = LEXEMS[INDEX - 1];
                end
            elseif type(value) == 'function' then
                if not SET(astNode, value()) then
                    INDEX = indexCpy;
                    matched = false;
                    astElements[repetitions] = nil;
                    break;
                else
                    astElements[repetitions][#astElements[repetitions] + 1] = astNode.val;
                end
            else
                matched = false;
                break;
            end
        end

        if(matched) then
        earlyIndex = indexCpy;
        indexCpy = INDEX;
        astElements[repetitions] = utils.flatten(astElements[repetitions]);
        repetitions = repetitions + 1;
        end

    end
    INDEX = earlyIndex;

    if #astElements > 0 then
        astElements[#astElements] = nil;
    end
    --astElements = utils.flatten(astElements);
    return astElements;
end

function MATCH(...)
    local indexCpy = INDEX;
    local arg = {...}

    local astElements = {};

    if #arg > (#LEXEMS - INDEX + 1) then
        return false;
    end

    if(#arg == 0) then print('received null...') return false; end;

    for key, value in ipairs(arg) do
        local localIndex = INDEX;
        local astNode = {val = nil};
        if type(value) == 'function' then
            if not SET(astNode, value()) then 
                return false; 
            else
                astElements[#astElements + 1] = astNode.val;
            end
        elseif type(value) == 'number' then
            if not SET(astNode, EQUALS(LEXEMS[INDEX].tokenType, value)) then 
                INDEX = indexCpy; return false; 
            else
                astElements[#astElements + 1] = LEXEMS[INDEX - 1];
            end
        else
            print('weird error');
        end
    end
    astElements = utils.flatten(astElements);
    return astElements;
end

function ONE_OR_MORE(index, ...)
    local indexCpy = INDEX;
    local arg = {...}

    local firstMatch = {val = nil};
    local listMatch = {val = nil};
    if SET(firstMatch, MATCH(table.unpack(arg))) and SET(listMatch, OPTIONAL_MULTIPLE(INDEX, table.unpack(arg))) then
        local result = firstMatch.val;
        for _, value in ipairs(listMatch) do
            result[#result+1] = value;
        end
        return result;
    end
    INDEX = indexCpy;

    return false;
end

function NODE.CHUNK()
    local indexCpy = INDEX;
    local exports = OPTIONAL(INDEX, TokenType.EXPORTS_KEYWORD, TokenType.AT_OPERATOR, NODE.TYPE);
    if exports[3] then
        exports = utils.fromTypeNodeToString(exports[3]);
    else
        exports = nil;
        INDEX = indexCpy;
    end
    local ast = MATCH(NODE.BLOCK);

    if ast and (INDEX == #LEXEMS + 1) then
        return ast, exports;
    else
        if #LEXEMS == 0 then
            return {stats = {}, retstat = {}};
        end
        print('syntax error!');
        print('error at line ' .. LEXEMS[MAX_INDEX].line .. ', column: ' .. LEXEMS[MAX_INDEX].column);
    end
end

function NODE.BLOCK()
    
    local indexCpy = INDEX;
    local stats = {value = nil};
    local retstat = {value = nil};

    if SET(stats, OPTIONAL_MULTIPLE(INDEX, NODE.STAT)) and SET(retstat, OPTIONAL(INDEX, NODE.RETSTAT)) then
        return {node = NodeType.BLOCK_NODE, stats = stats.val, retstat = retstat.val};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.STAT()

    local indexCpy = INDEX;
    local matchedValues = {val = nil};

    if MATCH(TokenType.SEMICOLON_MARK) then
        return {node = NodeType.SEMICOLON_NODE};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(NODE.VARLIST, TokenType.ASSIGN_OPERATOR, NODE.EXPLIST)) then
        return {node = NodeType.ASSIGNMENT_NODE, left = matchedValues.val[1], right = matchedValues.val[3], line = matchedValues.val[2].line};
    end
    INDEX = indexCpy;

    local matchedLeft = {val = nil};
    local matchedRight = {val = nil};
    if SET(matchedLeft, MATCH(TokenType.LOCAL_KEYWORD, NODE.NAMELIST)) and 
    SET(matchedRight, OPTIONAL(INDEX, TokenType.ASSIGN_OPERATOR, NODE.EXPLIST)) then
        return {node = NodeType.LOCAL_DECLARATION_NODE, left = matchedLeft.val[2], right = matchedRight.val[2], line = matchedLeft.val[1].line};
    end
    INDEX = indexCpy;

    local matchedValues = {val = nil};
    if SET(matchedValues, MATCH(NODE.FUNCTIONCALL)) then
        return {node = NodeType.FUNCTION_CALL_NODE, call = matchedValues.val.call, prefix = matchedValues.val.prefix, suffix = matchedValues.val.suffix};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(NODE.LABEL)) then
        return {node = NodeType.LABEL, id = matchedValues.val.value};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.GOTO_KEYWORD, TokenType.IDENTIFIER)) then
        return {node = NodeType.GOTO, id = matchedValues.val[2].value};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.DO_KEYWORD, NODE.BLOCK, TokenType.END_KEYWORD)) then
        return {node = NodeType.DO_BLOCK_NODE, block = matchedValues.val[2]};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.WHILE_KEYWORD, NODE.EXP, TokenType.DO_KEYWORD, NODE.BLOCK, TokenType.END_KEYWORD)) then
        return {node = NodeType.WHILE_LOOP_NODE, condition = matchedValues.val[2], block = matchedValues.val[4]};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.REPEAT_KEYWORD, NODE.BLOCK, TokenType.UNTIL_KEYWORD, NODE.EXP)) then
        return {node = NodeType.REPEAT_LOOP_NODE, block = matchedValues.val[2], condition = matchedValues.val[4]};
    end
    INDEX = indexCpy;

    local mainExp = {val = nil};
    local elseifExp = {val = nil};
    local elseExp = {val = nil};
    if SET(mainExp, MATCH(TokenType.IF_KEYWORD, NODE.EXP, TokenType.THEN_KEYWORD, NODE.BLOCK)) and
    SET(elseifExp,
    OPTIONAL_MULTIPLE(
        INDEX, TokenType.ELSEIF_KEYWORD, NODE.EXP, TokenType.THEN_KEYWORD, NODE.BLOCK
    )) and
    SET(elseExp,
    OPTIONAL(
        INDEX, TokenType.ELSE_KEYWORD, NODE.BLOCK
    )) and
    MATCH(TokenType.END_KEYWORD) then
        local branches = {[1] = {}};
        branches[1].condition = mainExp.val[2];
        branches[1].block = mainExp.val[4];
        for key, branch in ipairs(elseifExp.val) do
            branches[#branches+1] = {};
            branches[#branches].condition = branch[2];
            branches[#branches].block = branch[4];
        end
        local elseBranch = nil;
        if #elseExp.val then
            elseBranch = {block = elseExp.val[2]}
        end
        return {node = NodeType.IF_NODE, branches = branches, elseBranch = elseBranch};
    end
    INDEX = indexCpy;

    local incrementExp = {val = nil};
    local forBody = {val = nil};
    if SET(matchedValues, MATCH(TokenType.FOR_KEYWORD, TokenType.IDENTIFIER, TokenType.ASSIGN_OPERATOR, 
             NODE.EXP, TokenType.COMMA_MARK, NODE.EXP)) and
    SET(incrementExp, OPTIONAL(
        INDEX, TokenType.COMMA_MARK, NODE.EXP
    )) and
    SET(forBody, MATCH(TokenType.DO_KEYWORD, NODE.BLOCK, TokenType.END_KEYWORD)) then
        local increment = nil;
        if #incrementExp.val > 0 then
            increment = incrementExp.val[2];
        end
        return {
            node = NodeType.FOR_CONTOR_LOOP_NODE,
            contorName = matchedValues.val[2].value,
            contorValue = matchedValues.val[4],
            stopValue = matchedValues.val[6],
            increment = increment,
            block = forBody.val[2]
        }
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.FOR_KEYWORD, NODE.NAMELIST, TokenType.IN_KEYWORD, NODE.EXPLIST, TokenType.DO_KEYWORD, NODE.BLOCK, TokenType.END_KEYWORD)) then
        return {
            node = NodeType.FOR_IN_LOOP_NODE,
            left = matchedValues.val[2],
            right = matchedValues.val[4],
            block = matchedValues.val[6]
        };
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.FUNCTION_KEYWORD, NODE.FUNCNAME, NODE.FUNCBODY)) then
        return {node = NodeType.FUNCTION_DECLARATION_NODE, id = matchedValues.val[2], body = matchedValues.val[3], line = matchedValues.val[1].line};
    end
    INDEX = indexCpy;

    if SET(matchedValues, MATCH(TokenType.LOCAL_KEYWORD, TokenType.FUNCTION_KEYWORD, TokenType.IDENTIFIER, NODE.FUNCBODY)) then
        return {node = NodeType.LOCAL_FUNCTION_DECLARATION_NODE, id = matchedValues.val[3].value, body = matchedValues.val[4]};
    end
    INDEX = indexCpy;

    local className = {val = nil};
    local baseClass = {val = nil};
    local classBody = {val = nil};
    if SET(className, MATCH(TokenType.CLASS_KEYWORD, TokenType.IDENTIFIER)) and 
    SET(baseClass, OPTIONAL(INDEX, TokenType.COLON_OPERATOR, TokenType.IDENTIFIER, NODE.CONSTRUCTORARGS)) and
    SET(classBody, MATCH(TokenType.AS_KEYWORD, NODE.CLASSBODY)) then
        local baseClassId = nil;
        local baseClassArgs = nil;
        if #baseClass.val > 0 then
            baseClassId = baseClass.val[2].value;
            baseClassArgs = baseClass.val[3];
        end
        return {node = NodeType.CLASS_DECLARATION_NODE, id = className.val[2].value, baseClassId = baseClassId, stats = classBody.val[2].stats, baseClassArgs = baseClassArgs, line = className.val[2].line};
    end
    INDEX = indexCpy;

    local matchedNames = { val = nil };
    local matchedFunctions = { val = nil };
    local matchedID = {val = nil};
    local matchedUnique = {val = nil};
    local isLocal = {val = nil};
    if SET(isLocal, OPTIONAL(INDEX, TokenType.LOCAL_KEYWORD)) and
    MATCH(TokenType.LOGIC_KEYWORD) and
    SET(matchedUnique, OPTIONAL(INDEX, TokenType.UNIQUE_KEYWORD)) and
    SET(matchedID, MATCH(TokenType.IDENTIFIER)) and
    SET(matchedNames, MATCH(NODE.LOGIC_NAMELIST)) and
    SET(matchedFunctions, OPTIONAL_MULTIPLE(INDEX, NODE.LOGIC_FUNC)) and 
    MATCH(TokenType.END_KEYWORD) then
        local is_unique = nil;
        if matchedUnique.val.value then
            is_unique = true;
        end
        local islocal = nil;
        if isLocal.val.value then
            islocal = true;
        end
        return { node = NodeType.LOGIC_BLOCK_NODE, id = matchedID.val.value, is_unique = is_unique, args =  matchedNames.val, funcs = matchedFunctions.val, isLocal = islocal, line = matchedID.val.line};
    end
    INDEX = indexCpy;

    matchedValues = {val = nil};
    if SET(matchedValues, MATCH(TokenType.OPERATOR_KEYWORD, NODE.BINOP, NODE.FUNCBODY)) then
        if #(matchedValues.val[3].parlist.namelist or {}) == 2 then
            return {node = NodeType.BINARY_OPERATOR_OVERLOAD_NODE, 
                    op = matchedValues.val[2].symbol,
                    body = matchedValues.val[3],
                    line = matchedValues.val[1].line;
                }
        end
    end
    INDEX = indexCpy;

    matchedValues = {val = nil};
    if SET(matchedValues, MATCH(TokenType.OPERATOR_KEYWORD, NODE.UNOP, NODE.FUNCBODY)) then
        if #(matchedValues.val[3].parlist.namelist or {}) == 1 then
            return {node = NodeType.UNARY_OPERATOR_OVERLOAD_NODE, 
                    op = matchedValues.val[2].symbol,
                    body = matchedValues.val[3]
                }
        end
    end
    INDEX = indexCpy;

    local isLocal = {val = nil};
    matchedValues = {val = nil};
    if SET(isLocal, OPTIONAL(INDEX, TokenType.LOCAL_KEYWORD)) and 
    SET(matchedValues, MATCH(TokenType.DEFAULT_KEYWORD, TokenType.FOR_KEYWORD, NODE.TYPE, TokenType.IS_KEYWORD, NODE.EXP)) then
        local islocal = nil;
        if isLocal.val.value then
            islocal = true;
        end
        return {node = NodeType.DEFAULT_SET_NODE, 
                type = utils.fromTypeNodeToString(matchedValues.val[3]), 
                exp = matchedValues.val[5],
                isLocal = islocal;
                line = matchedValues.val[1].line;
            }
    end
    INDEX = indexCpy;

    return false;
end

function NODE.CONSTRUCTORARGS()
    local indexCpy = INDEX;

    local matchedNamelist = {val = nil};
    if MATCH(TokenType.LEFT_PARAN_MARK) and 
    SET(matchedNamelist, OPTIONAL(INDEX, NODE.NAMELIST)) 
    and MATCH(TokenType.RIGHT_PARAN_MARK) then
        return matchedNamelist.val;
    end
    INDEX = indexCpy;

    return false;
end

function NODE.CLASSBODY()
    local indexCpy = INDEX;

    local stats = {val = nil};
    if SET(stats, OPTIONAL_MULTIPLE(INDEX, NODE.CLASSSTAT)) and MATCH(TokenType.END_KEYWORD) then
        return {node = NodeType.CLASS_BODY_NODE, stats = stats.val};
    end
    INDEX = indexCpy;

    return false
end

function NODE.CLASSSTAT()
    local indexCpy = INDEX;

    local funcBody = {val = nil};
    local staticMod = {val = nil};
    
    if MATCH(TokenType.SEMICOLON_MARK) then
        return {node = NodeType.SEMICOLON_NODE};
    end

    if SET(funcBody, MATCH(TokenType.CONSTRUCTOR_KEYWORD, NODE.FUNCBODY)) then
        return {
            node = NodeType.CONSTRUCTOR_NODE, 
            body = funcBody.val[2],
            line = funcBody.val[1].line
        };
    end
    INDEX = indexCpy;

    local staticMod = {val = nil};
    if SET(staticMod, OPTIONAL(INDEX, TokenType.STATIC_KEYWORD)) and 
    SET(funcBody, MATCH(TokenType.IDENTIFIER, NODE.FUNCBODY)) then
        local static = nil;
        if staticMod.val.value then
            static = true;
        end
        return {
            node = NodeType.MEMBER_FUNCTION_NODE, 
            static = static, 
            id = funcBody.val[1].value, 
            body = funcBody.val[2],
            line = funcBody.val[1].line
        };
    end
    INDEX = indexCpy;

    local matchedId = {val = nil};
    local matchedParams = {val = nil};
    local matchedType = {val = nil};
    if MATCH(TokenType.ABSTRACT_KEYWORD) and SET(matchedId, MATCH(TokenType.IDENTIFIER, TokenType.LEFT_PARAN_MARK)) and
    SET(matchedParams, OPTIONAL(INDEX, NODE.PARLIST)) and MATCH(TokenType.RIGHT_PARAN_MARK) and SET(matchedType, OPTIONAL(INDEX, TokenType.ARROW_OPERATOR, NODE.TYPE)) then
        local type = nil;
        if matchedType.val[2] then
            type = utils.fromTypeNodeToString(matchedType.val[2]);
        end
        return { node = NodeType.ABSTRACT_METHOD_NODE, 
                params = matchedParams.val, 
                id = matchedId.val[1].value; 
                type = type,
                line = matchedId.val[1].line;
            };
    end
    INDEX = indexCpy;

    local nameList = {val = nil};
    local expList = {val = nil};
    local staticMod = {val = nil};
    if SET(staticMod, OPTIONAL(INDEX, TokenType.STATIC_KEYWORD)) and  
    SET(nameList, MATCH(NODE.NAMELIST)) and 
    SET(expList, OPTIONAL(INDEX, TokenType.ASSIGN_OPERATOR, NODE.EXPLIST)) then
        local static = nil;
        if staticMod.val.value then
            static = true;
        end
        return {
            node = NodeType.CLASS_FIELD_DELCARATION_NODE,
            static = static,
            left = nameList.val,
            right = expList.val[2]
        };
    end
    INDEX = indexCpy;

    local matchedNames = { val = nil };
    local matchedFunctions = { val = nil };
    local matchedID = {val = nil};
    local matchedUnique = {val = nil};
    local staticMod = {val = nil};
    local isLocal = {val = nil};
    if SET(staticMod, OPTIONAL(INDEX, TokenType.STATIC_KEYWORD)) and
    MATCH(TokenType.LOGIC_KEYWORD) and
    SET(matchedUnique, OPTIONAL(INDEX, TokenType.UNIQUE_KEYWORD)) and
    SET(matchedID, MATCH(TokenType.IDENTIFIER)) and
    SET(matchedNames, MATCH(NODE.LOGIC_NAMELIST)) and
    SET(matchedFunctions, OPTIONAL_MULTIPLE(INDEX, NODE.LOGIC_FUNC)) and 
    MATCH(TokenType.END_KEYWORD) then
        local is_unique = nil;
        if matchedUnique.val.value then
            is_unique = true;
        end
        local static = nil;
        if staticMod.val.value then
            static = true;
        end
        return {node = NodeType.LOGIC_BLOCK_NODE, 
                id = matchedID.val.value, 
                is_unique = is_unique, 
                args =  matchedNames.val or {}, 
                funcs = matchedFunctions.val, 
                static = static, 
                line = matchedID.val.line};
    end
    INDEX = indexCpy;

    return false
end

function NODE.ATTNAMELIST()
    local indexCpy = INDEX;

    local firstAttrib = {val = nil};
    local attribList = {val = nil};
    if SET(firstAttrib, MATCH(TokenType.IDENTIFIER, NODE.ATTRIB)) and SET(attribList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, TokenType.IDENTIFIER, NODE.ATTRIB)) then
        local attributes = {};
        attributes[1] = {id = firstAttrib.val[1], attribute = firstAttrib.val[2]};
        --VERIFY THIS CONDITION
        if #attribList.val > 0 then
            for key, value in ipairs(attribList.val) do
                attributes[#attributes+1] = {id = value[2], attribute = value[3]};           
            end
        end
        return attribList;
    end
    INDEX = indexCpy;

    return false
end

function NODE.ATTRIB()
    local indexCpy = INDEX;
    
    local matchedValues = {val = nil};
    if SET(matchedValues, OPTIONAL(INDEX, TokenType.LESS_OPERATOR, TokenType.IDENTIFIER, TokenType.MORE_OPERATOR)) then
        local id = nil;
        if #matchedValues.val > 0 then
            id = matchedValues.val[2].value;
        end
        return {id = id};
    end
    INDEX = indexCpy;

    return false
end

function NODE.RETSTAT()
    local indexCpy = INDEX;

    local expressions = {val = nil};
    local matchedReturn = {val = nil};
    if SET(matchedReturn, MATCH(TokenType.RETURN_KEYWORD)) and 
    SET(expressions, OPTIONAL(INDEX, NODE.EXPLIST)) and 
    OPTIONAL(INDEX, TokenType.SEMICOLON_MARK) then
        return {expressions = expressions.val, node = NodeType.RETURN_NODE, line = matchedReturn.val.line};
    end
    INDEX = indexCpy;

    return false
end

function NODE.LABEL()
    local indexCpy = INDEX;
    local matchedValues = {val = nil};

    if SET(matchedValues, MATCH(TokenType.DOUBLE_COLON_OPERATOR, TokenType.IDENTIFIER, TokenType.DOUBLE_COLON_OPERATOR)) then
        return matchedValues.val[2];
    end

    INDEX = indexCpy;
    return false
end

function NODE.FUNCNAME()
    local indexCpy = INDEX;

    local root = {value = nil};
    local fields = {value = nil};
    local selfField = {value = nil};
    if SET(root, MATCH(TokenType.IDENTIFIER)) and 
    SET(fields, OPTIONAL_MULTIPLE(INDEX, TokenType.POINT_MARK, TokenType.IDENTIFIER)) and
    SET(selfField, OPTIONAL(INDEX, TokenType.COLON_OPERATOR, TokenType.IDENTIFIER)) then
        local fieldIdList = {};
        fieldIdList[1] = root.val.value;
        if #fields.val > 0 then
            for key, value in ipairs(fields.val) do
                fieldIdList[#fieldIdList+1] = value[2].value;
            end
        end
        local isSelf = false;
        if #selfField.val > 0 then
            fieldIdList[#fieldIdList+1] = selfField.val[2].value;
            isSelf = true;
        end
        fieldIdList.isSelf = isSelf; 
        return fieldIdList;
    end
    INDEX = indexCpy;

    return false
end

function NODE.VARLIST()
    local indexCpy = INDEX;

    local firstVar = {val = nil};
    local vars = {val = nil};
    if SET(firstVar, MATCH(NODE.VAR)) and SET(vars, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.VAR)) then
        local varList = {};
        varList[1] = firstVar.val;
        for key, value in ipairs(vars.val) do
            varList[#varList+1] = value[2];
        end
        varList.node = NodeType.VARLIST_NODE;
        return varList;
    end
    INDEX = indexCpy;

    return false
end

function NODE.VAR()
    local indexCpy = INDEX;

    local isThis = {val = nil};
    local matchedPrefix = {val = nil};
    local matchedSuffix = {val = nil};
    local matchedIndex = {val = nil};
    local matchedType = {val = nil};
    if SET(isThis, OPTIONAL(INDEX, TokenType.THIS_KEYWORD, TokenType.POINT_MARK)) and
    SET(matchedPrefix, MATCH(NODE.PREFIX)) and 
    SET(matchedSuffix, OPTIONAL_MULTIPLE_LEAVE_LAST(INDEX, NODE.SUFFIX)) and 
    SET(matchedIndex, MATCH(NODE.INDEX)) then
        local index = {};
        if #matchedSuffix.val > 0 then
            for key, value in pairs(matchedSuffix.val) do
                index[#index+1] = value;
            end
            matchedSuffix = utils.reverse(matchedSuffix);
        end
        local this = nil;
        if #isThis.val > 0 then
            this = true;
        end
        index[#index+1] = matchedIndex.val;
        return {
            node = NodeType.VAR_NODE,
            prefix = matchedPrefix.val,
            suffix = index,
            isThis = this
        };
    end
    INDEX = indexCpy;

    local matchedId = {val = nil};
    matchedType = {val = nil}
    local isThis = {val = nil};
    if SET(isThis, OPTIONAL(INDEX, TokenType.THIS_KEYWORD, TokenType.POINT_MARK)) and 
    SET(matchedId, MATCH(TokenType.IDENTIFIER)) then
        local this = nil;
        if #isThis.val > 0 then
            this = true;
        end
        return {node = NodeType.VAR_NODE, id = matchedId.val.value, isThis = this};
    end
    INDEX = indexCpy;

    return false
end

function NODE.NAMELIST()
    local indexCpy = INDEX;
    
    local matchedFirstName = {val = nil};
    local matchedNameList = {val = nil};
    if SET(matchedFirstName, MATCH(NODE.NAME)) and 
    SET(matchedNameList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.NAME)) then
        local nameList = {};
        nameList[1] = matchedFirstName.val;
        for key, value in ipairs(matchedNameList.val) do
           nameList[#nameList+1] = value[2]; 
        end
        return nameList;
    end
    INDEX = indexCpy;

    return false
end

function NODE.TYPE()
    local indexCpy = INDEX;

    local matchedType = {val = nil};
    if
        SET(matchedType, MATCH(TokenType.IDENTIFIER)) or
        SET(matchedType, MATCH(TokenType.ANY_KEYWORD)) or
        SET(matchedType, MATCH(TokenType.FUNCTION_KEYWORD))
    then
        return matchedType.val.value;
    end
    INDEX = indexCpy;

    if SET(matchedType, MATCH(TokenType.LEFT_BRACE_MARK, NODE.TYPE, TokenType.RIGHT_BRACE_MARK)) then
        return {matchedType.val[2]};
    end
    INDEX = indexCpy;
end

function NODE.NAME()
    local indexCpy = INDEX;

    local matchedId = {val = nil};
    local matchedType = {val = nil};
    if SET(matchedId, MATCH(TokenType.IDENTIFIER)) and 
    SET(matchedType, OPTIONAL(INDEX, TokenType.AT_OPERATOR, NODE.TYPE))  then
        local varType = nil;
        if matchedType.val then
            varType = utils.fromTypeNodeToString(matchedType.val[2]);
        end
        return {node = NodeType.NAME_NODE, id = matchedId.val.value, type = varType};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.EXPLIST()
    local indexCpy = INDEX;

    local matchedFirstExp = {val = nil};
    local matchedExpList = {val = nil};
    if SET(matchedFirstExp, MATCH(NODE.EXP)) and
    SET(matchedExpList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.EXP)) then
        local expList = {};
        expList[1] = matchedFirstExp.val;
        for key, value in ipairs(matchedExpList.val) do
            expList[#expList+1] = value[2];
        end
        expList.node = NodeType.EXPLIST_NODE;
        return expList;
    end

    INDEX = indexCpy;

    return false
end

function NODE.EXP()
    local indexCpy = INDEX;

    local matchedExp = {val = nil};
    if SET(matchedExp, MATCH(NODE.LAMBDAFUNC)) then
        matchedExp.val.node = NodeType.LAMBDA_FUNC_NODE;
        return matchedExp.val;
    end
    INDEX = indexCpy;

    if SET(matchedExp, MATCH(NODE.UNOP, NODE.EXP)) then
        return {node = NodeType.EVALUABLE_NODE, exp = matchedExp.val[2].exp, op = matchedExp.val[1]};
    end
    INDEX = indexCpy;

    local matchedOp = {val = nil};
    if SET(matchedExp, MATCH(NODE.VALUE)) and SET(matchedOp, OPTIONAL(INDEX, NODE.BINOP, NODE.EXP)) then
        local op = nil;
        if matchedOp.val[2] then
            op = {node = NodeType.BINEXP_NODE, binop = matchedOp.val[1], term = matchedOp.val[2]};
        end
        return {node = NodeType.EVALUABLE_NODE, exp = matchedExp.val, op = op;};
    end
    INDEX = indexCpy;

    return false
end

function NODE.VALUE()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    if SET(matchedValue, MATCH(TokenType.NIL_KEYWORD)) then
        return {type = 'nil', value = matchedValue.val.value};
    end 
    if SET(matchedValue, MATCH(TokenType.FALSE_KEYWORD)) then
        return {type = 'boolean', value = matchedValue.val.value}
    end 
    if SET(matchedValue, MATCH(TokenType.TRUE_KEYWORD)) then
        return {type = 'boolean', value = matchedValue.val.value}
    end
    if SET(matchedValue, MATCH(TokenType.NUMBER_VALUE)) then
        return {type = 'number', value = matchedValue.val.value}
    end 
    if SET(matchedValue, MATCH(TokenType.STRING_VALUE)) then
        return {type = 'string', value = utils.escapeQuotes(matchedValue.val.value)}
    end
    if SET(matchedValue, MATCH(TokenType.TRIPLE_POINT_MARK)) then
        return {type = 'triplePoint', value = matchedValue.val.value}
    end
    if SET(matchedValue, MATCH(TokenType.NEW_KEYWORD, TokenType.IDENTIFIER, NODE.ARGS)) then
        return {type = matchedValue.val[2].value, value = matchedValue.val[2].value, node = NodeType.INSTANTIATION_NODE, id = matchedValue.val[2].value, args = matchedValue.val[3], line = matchedValue.val[1].line};
    end
    INDEX = indexCpy;
    if SET(matchedValue, MATCH(NODE.TABLECONSTRUCTOR)) then
        return {type = 'table', value = matchedValue.val}
    end
    INDEX = indexCpy;
    if SET(matchedValue, MATCH(NODE.FUNCTIONCALL)) then
        return {valType = 'functioncall', value = matchedValue.val}
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(NODE.VAR)) then
        return {valType = 'var', value = matchedValue.val};
    end
    INDEX = indexCpy;
    
    if SET(matchedValue, MATCH(TokenType.LEFT_PARAN_MARK, NODE.EXP, TokenType.RIGHT_PARAN_MARK)) then
        return {node = NodeType.PARAN_EXP_NODE, exp = matchedValue.val[2]};
    end
    INDEX = indexCpy;

    local matchedType = {val=nil};
    if SET(matchedValue, MATCH(TokenType.LEFT_PARAN_MARK, NODE.EXP, TokenType.AS_KEYWORD))
    and SET(matchedType, MATCH(TokenType.IDENTIFIER) or MATCH(TokenType.FUNCTION_KEYWORD) or MATCH(TokenType.ANY_KEYWORD)) and MATCH(TokenType.RIGHT_PARAN_MARK) then
        return {node = NodeType.CAST_NODE, exp = matchedValue.val[2], castTo = matchedType.val.value, line = matchedValue.val[3].line}
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(TokenType.LEFT_PARAN_MARK, NODE.EXP, TokenType.IS_KEYWORD))
    and SET(matchedType, MATCH(TokenType.IDENTIFIER) or MATCH(TokenType.FUNCTION_KEYWORD) or MATCH(TokenType.ANY_KEYWORD)) and MATCH(TokenType.RIGHT_PARAN_MARK) then
        return {node = NodeType.CAST_CHECK_NODE, exp = matchedValue.val[2], castTo = matchedType.val.value, line = matchedValue.val[3].line}
    end
    INDEX = indexCpy;

    return false
end

function NODE.INDEX()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    if SET(matchedValue, MATCH(TokenType.LEFT_SQR_BRACKET_MARK, NODE.EXP, TokenType.RIGHT_SQR_BRACKET_MARK)) then
        return {node = NodeType.BRACKET_INDEX_NODE, val = matchedValue.val[2]};
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(TokenType.POINT_MARK, TokenType.IDENTIFIER)) then
        return {node = NodeType.POINT_INDEX_NODE, id = matchedValue.val[2].value};
    end
    INDEX = indexCpy;

    return false
end

function NODE.PREFIX()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    if SET(matchedValue, MATCH(TokenType.LEFT_PARAN_MARK, NODE.EXP, TokenType.RIGHT_PARAN_MARK)) then
        return {node = NodeType.EXP_NODE, exp = matchedValue.val[2]};
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(TokenType.IDENTIFIER)) then
        return matchedValue.val.value;
    end
    INDEX = indexCpy;

    return false
end

function NODE.SUFFIX()
    local indexCpy = INDEX;

    local matchedSuffix = {val = nil};
    if SET(matchedSuffix, MATCH(NODE.CALL)) then
        return {node = NodeType.CALL_NODE, call = matchedSuffix.val};
    end
    INDEX = indexCpy;

    if SET(matchedSuffix, MATCH(NODE.INDEX)) then
        return matchedSuffix.val;
    end
    INDEX = indexCpy;

    return false
end

function NODE.CALL()
    local indexCpy = INDEX;

    local matchedCall = {val = nil};
    if SET(matchedCall, MATCH(NODE.ARGS)) then
        return {node = NodeType.CALL_NODE, args = matchedCall.val};
    end
    INDEX = indexCpy;

    if SET(matchedCall, MATCH(TokenType.COLON_OPERATOR, TokenType.IDENTIFIER, NODE.ARGS)) then
        return {node = NodeType.SELF_CALL_NODE, id = matchedCall.val[2].value, args = matchedCall.val[3]};
    end
    INDEX = indexCpy;

    return false
end

function NODE.FUNCTIONCALL()
    local indexCpy = INDEX;

    local matchedPrefix = {val = nil};
    local matchedSuffixList = {val = nil};
    local matchedCall = {val = nil};
    local isThis = {val = nil};
    if SET(isThis, OPTIONAL(INDEX, TokenType.THIS_KEYWORD, TokenType.POINT_MARK)) and 
    SET(matchedPrefix, MATCH(NODE.PREFIX)) and 
    SET(matchedSuffixList, OPTIONAL_MULTIPLE_LEAVE_LAST(INDEX, NODE.SUFFIX)) and 
    SET(matchedCall, MATCH(NODE.CALL)) then
        local this = nil;
        if #isThis.val > 0 then
            this = true;
        end
        return {
            node = NodeType.FUNCTION_CALL_NODE,
            prefix = matchedPrefix.val,
            suffix = matchedSuffixList.val,
            call = matchedCall.val,
            isThis = this
        };
    end

    INDEX = indexCpy;
    return false;
end

function NODE.ARGS()
    local indexCpy = INDEX;

    local matchedArgs = {val = nil};
    if MATCH(TokenType.LEFT_PARAN_MARK) and SET(matchedArgs, OPTIONAL(INDEX, NODE.EXPLIST)) and MATCH(TokenType.RIGHT_PARAN_MARK) then
        return matchedArgs.val or {};
    end
    INDEX = indexCpy;

    if SET(matchedArgs, MATCH(NODE.TABLECONSTRUCTOR)) then
        return {[1] = matchedArgs.val};
    end
    INDEX = indexCpy;

    if SET(matchedArgs, MATCH(TokenType.STRING_VALUE)) then
        return {[1] = matchedArgs.val.value};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LAMBDAFUNC()
    local indexCpy = INDEX;

    local matchedFuncBody = {val = nil};
    if SET(matchedFuncBody, MATCH(TokenType.FUNCTION_KEYWORD, NODE.FUNCBODY)) then
        return {
            node = NodeType.LAMBDA_FUNC_NODE,
            body = matchedFuncBody.val[2];
        };
    end
    INDEX = indexCpy;

    return false;
end

function NODE.FUNCBODY()
    local indexCpy = INDEX;

    local matchedParlist = {val = nil};
    local matchedType = {val = nil};
    local matchedBlock = {val = nil};
    local matchedEnd = {val = nil};
    if MATCH(TokenType.LEFT_PARAN_MARK) and SET(matchedParlist, OPTIONAL(INDEX, NODE.PARLIST)) and MATCH(TokenType.RIGHT_PARAN_MARK) and 
    SET(matchedType, OPTIONAL(INDEX, TokenType.ARROW_OPERATOR, NODE.TYPE)) and
    SET(matchedBlock, MATCH(NODE.BLOCK)) and SET(matchedEnd, MATCH(TokenType.END_KEYWORD)) then
        local type = nil;
        if matchedType.val then
            type = utils.fromTypeNodeToString(matchedType.val[2]);
        end
        return {parlist = matchedParlist.val, type = type, block = matchedBlock.val, node = NodeType.FUNC_BODY_NODE, line = matchedEnd.val.line};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.PARLIST()
    local indexCpy = INDEX;
    
    local matchedNameList = {val = nil};
    local matchedTriplePoint = {val = nil};
    if SET(matchedNameList, MATCH(NODE.NAMELIST)) and 
    SET(matchedTriplePoint, OPTIONAL(INDEX, TokenType.COMMA_MARK, TokenType.TRIPLE_POINT_MARK)) then
        local isTriple = nil;
        if #matchedTriplePoint.val > 0 then
            isTriple = true;
        end
        return {namelist = matchedNameList.val, isTriple = isTriple};
    end
    INDEX = indexCpy;

    if MATCH(TokenType.TRIPLE_POINT_MARK) then
        return {namelist = {}, isTriple = true};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.TABLECONSTRUCTOR()
    local indexCpy = INDEX;

    local matchedFieldlist = {val = nil};
    local matchedFirstBrace = {val = nil};
    if SET(matchedFirstBrace, MATCH(TokenType.LEFT_BRACE_MARK)) and SET(matchedFieldlist, OPTIONAL(INDEX, NODE.FIELDLIST)) and MATCH(TokenType.RIGHT_BRACE_MARK) then
        return {node = NodeType.TABLE_CONSTRUCTOR_NODE, fieldlist = matchedFieldlist.val, line = matchedFirstBrace.val.line};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.FIELDLIST()
    local indexCpy = INDEX;
    
    local firstField = {val = nil};
    local fieldList = {val = nil};
    if SET(firstField, MATCH(NODE.FIELD)) and SET(fieldList, OPTIONAL_MULTIPLE(INDEX, NODE.FIELDSEP, NODE.FIELD)) and OPTIONAL(INDEX, NODE.FIELDSEP) then
        local fields = {[1] = firstField.val};
        for index, field in ipairs(fieldList.val) do
            fields[#fields+1] = field[2];
        end
        return fields;
    end
    INDEX = indexCpy;

    return false;
end

function NODE.FIELD()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    if SET(matchedValue, MATCH(TokenType.LEFT_SQR_BRACKET_MARK, NODE.EXP, TokenType.RIGHT_SQR_BRACKET_MARK, TokenType.ASSIGN_OPERATOR, NODE.EXP)) then
        return {node = NodeType.BRACKET_INDEX_NODE, index = matchedValue.val[2], exp = matchedValue.val[5]};
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(NODE.NAME, TokenType.ASSIGN_OPERATOR, NODE.EXP)) then
        return {node = NodeType.NAME_ASSIGNMENT_NODE, left = matchedValue.val[1], right = matchedValue.val[3]};
    end
    INDEX = indexCpy;

    if SET(matchedValue, MATCH(NODE.EXP)) then
        return {node = NodeType.EXP_WRAPPER_NODE, exp = matchedValue.val};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.FIELDSEP()
    local indexCpy = INDEX;

    if MATCH(TokenType.COMMA_MARK) then
        return ',';
    end
    INDEX = indexCpy;

    if MATCH(TokenType.SEMICOLON_MARK) then
        return ';';
    end
    INDEX = indexCpy;

    return false;
end

function NODE.BINOP()
    local indexCpy = INDEX;

    local matchedOp = {val = nil};
    if SET(matchedOp, MATCH(TokenType.PLUS_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.MINUS_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.STAR_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.SLASH_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.DOUBLE_SLASH_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.CARET_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.PERCENT_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.AND_KEYWORD)) or 
       SET(matchedOp, MATCH(TokenType.TILDE_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.DOUBLE_POINT_MARK)) or 
       SET(matchedOp, MATCH(TokenType.LESS_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.LESS_OR_EQUAL_OPERATOR)) or
       SET(matchedOp, MATCH(TokenType.MORE_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.MORE_OR_EQUAL_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.EQUALS_OPERATOR)) or
       SET(matchedOp, MATCH(TokenType.NOT_EQUALS_OPERATOR)) or 
       SET(matchedOp, MATCH(TokenType.AND_KEYWORD)) or
       SET(matchedOp, MATCH(TokenType.OR_KEYWORD)) then
        return {node = NodeType.BINOP_NODE, symbol = matchedOp.val.tokenType, value = matchedOp.val.value};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.UNOP()
    local indexCpy = INDEX;

    local matchedOp = {val = nil};
    if SET(matchedOp, MATCH(TokenType.MINUS_OPERATOR)) or 
    SET(matchedOp, MATCH(TokenType.NOT_KEYWORD)) or 
    SET(matchedOp, MATCH(TokenType.HASH_OPERATOR)) then
        local symbol = matchedOp.val.tokenType;
        if matchedOp.val.tokenType == TokenType.MINUS_OPERATOR then
            symbol = TokenType.UNARY_MINUS_OPERATOR
        end
        return {node = NodeType.UNOP_NODE, symbol = symbol, value = matchedOp.val.value};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_NAMELIST()
    local indexCpy = INDEX;

    local fistNameMatched = {val = nil};
    local nameListMatched = {val = nil};
    if SET(fistNameMatched, MATCH(TokenType.LEFT_PARAN_MARK, NODE.LOGIC_NAME)) and
    SET(nameListMatched, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.LOGIC_NAME)) and
    MATCH(TokenType.RIGHT_PARAN_MARK) then
        local nameList = {[1] = fistNameMatched.val[2]};
        for index, value in ipairs(nameListMatched.val) do
            nameList[#nameList+1] = value[2];
        end
        return nameList;
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_NAME()
    local indexCpy = INDEX;

    local matchedId = {val = nil};
    local argType = {val = nil};
    if SET(matchedId, MATCH(TokenType.IDENTIFIER)) then
        return { node = NodeType.LOGIC_NAME_NODE, id = matchedId.val.value };
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_FUNC()
    local indexCpy = INDEX;

    local matchedFirstVar = {val = nil};
    local matchedVarList = {val = nil};
    local matchedStats = {val = nil};
    if SET(matchedFirstVar, MATCH(TokenType.LEFT_PARAN_MARK, NODE.LOGIC_VALUE)) and
    SET(matchedVarList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.LOGIC_VALUE)) and
    MATCH(TokenType.RIGHT_PARAN_MARK) and
    SET(matchedStats, OPTIONAL_MULTIPLE(INDEX, NODE.LOGIC_STAT)) and
    MATCH(TokenType.END_KEYWORD) then
        local vars = {[1] = matchedFirstVar.val[2]};
        for index, var in ipairs(matchedVarList.val) do
            vars[#vars + 1] = var[2];
        end
        return {node = NodeType.LOGIC_PREDICATE_NODE, args = vars, stats = matchedStats.val, line = matchedFirstVar.val[1].line};
    end
    INDEX = indexCpy;

    local matchedValues = {val = nil};
    if SET(matchedValues, MATCH(NODE.VAR, TokenType.AS_KEYWORD, TokenType.IDENTIFIER)) then
        return {node = NodeType.LOGIC_ALIAS_NODE, var = matchedValues.val[1], alias = matchedValues.val[3].value, line = matchedValues.val[3].line};
    end
    INDEX = indexCpy;

    if MATCH(TokenType.SEMICOLON_MARK) then
        return {node = NodeType.SEMICOLON_NODE};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_TABLE()
    local indexCpy = INDEX;

    if MATCH(TokenType.LEFT_BRACE_MARK, TokenType.RIGHT_BRACE_MARK) then
        return { node = NodeType.LOGIC_TABLE_NODE };
    end
    INDEX = indexCpy;

    local matchedFirstHead = {val = nil};
    local matchedHeadList = {val = nil};
    local matchedTail = {val = nil};
    if SET(matchedFirstHead, MATCH(TokenType.LEFT_BRACE_MARK, NODE.LOGIC_VALUE)) and
    SET(matchedHeadList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.LOGIC_VALUE)) and
    SET(matchedTail, OPTIONAL(INDEX, TokenType.CONCATENATION_OPERATOR, NODE.LOGIC_VALUE)) and
    MATCH(TokenType.RIGHT_BRACE_MARK) then
        local head = { [1] = matchedFirstHead.val[2] };
        for index, value in ipairs(matchedHeadList.val) do
            head[#head+1] = value[2];
        end
        return { node = NodeType.LOGIC_TABLE_NODE, head = head, tail = matchedTail.val[2] };
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_VALUE()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    if SET(matchedValue, MATCH(TokenType.LEFT_PARAN_MARK, NODE.LOGIC_EXP, TokenType.RIGHT_PARAN_MARK)) then
        return { paranExp = true, innerExp = matchedValue.val[2]};
    end
    INDEX = indexCpy;

    matchedValue = {val = nil};
    if SET(matchedValue, MATCH(NODE.LOGIC_TABLE)) then
        return matchedValue.val;
    end

    local matchedNegative = {val = nil};
    if SET(matchedValue, MATCH(TokenType.IDENTIFIER)) then
        return { node = NodeType.LOGIC_IDENTIFIER_NODE, id = matchedValue.val.value};
    end

    if SET(matchedNegative, OPTIONAL(INDEX, TokenType.MINUS_OPERATOR)) and 
    SET(matchedValue, MATCH(TokenType.NUMBER_VALUE)) then
        if matchedNegative.val.tokenType then
            matchedValue.val.value = -matchedValue.val.value;
        end
        return { node = NodeType.VALUE_NODE, value = matchedValue.val.value };
    end

    if SET(matchedValue, MATCH(TokenType.STRING_VALUE)) then
        return { node = NodeType.VALUE_NODE, value = utils.escapeQuotes(matchedValue.val.value) };
    end

    return false;
end

function NODE.LOGIC_WRAPPED_FUNCTION()
    local indexCpy = INDEX;
    
    local matchedValues = {val = nil};
    if SET(matchedValues, MATCH(TokenType.NOT_KEYWORD, TokenType.LEFT_PARAN_MARK, NODE.LOGIC_FUNCTION_CALL, TokenType.RIGHT_PARAN_MARK)) then
        local functionCall = matchedValues.val[3];
        functionCall.modifier = 'not';
        return functionCall;
    end
end

function NODE.LOGIC_FUNCTION_CALL()
    local indexCpy = INDEX;

    local matchedId = {val = nil};
    local matchedArgList = {val = nil};
    if SET(matchedId, MATCH(TokenType.IDENTIFIER, TokenType.LEFT_PARAN_MARK, NODE.LOGIC_VALUE)) and
    SET(matchedArgList, OPTIONAL_MULTIPLE(INDEX, TokenType.COMMA_MARK, NODE.LOGIC_VALUE)) and
    MATCH(TokenType.RIGHT_PARAN_MARK) then
        local args = {[1] = matchedId.val[3]};
        for index, arg in ipairs(matchedArgList.val) do
            args[#args+1] = arg[2];
        end
        local is_inbuilt = nil;
        if matchedId.val[1].value == 'is_list' or matchedId.val[1].value == 'atom' then
            is_inbuilt = true;
        end
        return {args = args, id = matchedId.val[1].value, node = NodeType.LOGIC_FUNCTION_CALL_NODE, is_inbuilt = is_inbuilt};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_STAT()
    local indexCpy = INDEX;
    
    local matchedVal = {val = nil};
    if MATCH(TokenType.SEMICOLON_MARK) then
        return {};
    end
    INDEX = indexCpy;

    if SET(matchedVal, MATCH(NODE.LOGIC_FUNCTION_CALL)) then
        return matchedVal.val;
    end
    INDEX = indexCpy;

    if SET(matchedVal, MATCH(NODE.LOGIC_WRAPPED_FUNCTION)) then
        return matchedVal.val;
    end
    INDEX = indexCpy;

    if SET(matchedVal, MATCH(NODE.LOGIC_VALUE, TokenType.ASSIGN_OPERATOR, NODE.LOGIC_VALUE)) then
        return {left = matchedVal.val[1], right = matchedVal.val[3], node = NodeType.LOGIC_UNIFY_NODE};
    end
    INDEX = indexCpy;

    if SET(matchedVal, MATCH(TokenType.IDENTIFIER, TokenType.ARROW_OPERATOR, NODE.LOGIC_EXP)) then
        return {left = matchedVal.val[1].value, right = matchedVal.val[3], node = NodeType.LOGIC_ASSIGN_NODE}
    end

    if SET(matchedVal, MATCH(NODE.LOGIC_EXP, NODE.LOGIC_CHECKS, NODE.LOGIC_EXP)) then
        return {left = matchedVal.val[1], check = matchedVal.val[2], right = matchedVal.val[3], node=NodeType.LOGIC_CHECK_NODE};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_CHECKS()
    local matchedCheck = {val = nil};
    if SET(matchedCheck, MATCH(TokenType.EQUALS_OPERATOR)) or
    SET(matchedCheck, MATCH(TokenType.NOT_EQUALS_OPERATOR)) or
    SET(matchedCheck, MATCH(TokenType.MORE_OPERATOR)) or
    SET(matchedCheck, MATCH(TokenType.LESS_OPERATOR)) or
    SET(matchedCheck, MATCH(TokenType.LESS_OR_EQUAL_OPERATOR)) or
    SET(matchedCheck, MATCH(TokenType.MORE_OR_EQUAL_OPERATOR)) then
        return matchedCheck.val.tokenType;
    end
    return false;
end

function NODE.LOGIC_EXP()
    local indexCpy = INDEX;

    local matchedValue = {val = nil};
    local matchedOps = {val = nil};
    if SET(matchedValue, MATCH(NODE.LOGIC_VALUE)) and SET(matchedOps, OPTIONAL(INDEX, NODE.LOGIC_BINOP, NODE.LOGIC_EXP)) then
        local binop, exp = nil, nil;
        if matchedOps.val then
            binop = matchedOps.val[1];
            exp = matchedOps.val[2];
        end
        if matchedValue.val.paranExp then
            matchedValue.val.exp = exp;
            matchedValue.val.binop = binop;
            return matchedValue.val;
        end
        return { value = matchedValue.val, binop = binop, exp = exp};
    end
    INDEX = indexCpy;

    return false;
end

function NODE.LOGIC_BINOP()
    local matchedOp = {val = nil};
    if SET(matchedOp, MATCH(TokenType.PLUS_OPERATOR)) or
    SET(matchedOp, MATCH(TokenType.MINUS_OPERATOR)) or
    SET(matchedOp, MATCH(TokenType.SLASH_OPERATOR)) or
    SET(matchedOp, MATCH(TokenType.STAR_OPERATOR)) or
    SET(matchedOp, MATCH(TokenType.PERCENT_OPERATOR))
    then
        return matchedOp.val.tokenType;
    end
end

function Parser.parse(lexems)
    LEXEMS = lexems;
    INDEX = 1;
    return NODE.CHUNK();
end

return Parser;