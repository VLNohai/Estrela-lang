local lexer = {}
local tokens = require('tokens');
local open = io.open;

local letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_';
local numbers = '0123456789';
local hexSymbols = 'abcdefABCDEF'
local operator = '+-/%^#=~<>.:*@?|'
local marker = '(){}[];,';
local whitespace = ' \n\t\r'
local validEscapes = 'abfnrtvx"\'\\'

local line = 1;
local column = 1;

local inputFile = nil;
local outputFile = nil;


Current_index = 1;
First_read = true;
c = '';

local function nextChar()
    if First_read or (buffer and Current_index > #buffer) then
        buffer = inputFile:read(4096);
        if not buffer then c = nil return end;
        Current_index = 1;
        First_read = false;
    end
    if not buffer then c = nil return end;
    c = string.sub(buffer, Current_index, Current_index);
    
    Current_index = Current_index + 1;
    if c == '\n' then
        line = line + 1;
        column = 1;
    else
        column = column + 1;
    end
end

function lexer.lex(path)
    local resultTokens = {}
    inputFile = open(path, "r")
    outputFile = open('extra/output.lex', "w")
    if not inputFile then print('file not found!'); return {} end
    if not outputFile then print('file not found!'); return {} end
    
    nextChar()
    if(c == nil) then print('empty file') return {} end;

    while c do
        local word = '';
        local comment = false;

        --IDENTIFIERS OR KEYWORDS
        if string.find(letters, c, 1, true) then
            while(c and (string.find(letters, c, 1, true) or string.find(numbers, c, 1, true))) do
                word = word .. c;
                nextChar()
            end
            if tokens.MapKeywords[word] then
                resultTokens[#resultTokens + 1] = {tokenType = tokens.MapKeywords[word]; value = word; line = line; column = column - #word - 1}
            else
                resultTokens[#resultTokens + 1] = {tokenType = tokens.TokenType.IDENTIFIER; value = word; line = line; column = column - #word - 1}
            end
        elseif

        --NUMBER
        string.find(numbers, c, 1, true) then
            local decimal = false;
            local hex = false;
            while(c and c:match('[0-9]') or (c=='.' and not decimal) or ((c == 'x' or c =='X') and word == '0') or (c and string.find('abcdefABCDEF', c, 1, true) and hex == true)) do
                word = word .. c;
                if(c == '.') then decimal = true; end;
                if(word == '0x' or word == '0X') then hex = true; end;
                nextChar()
            end
            local number = tonumber(word);
            if(number == nil) then print('invalid number') return end;

            resultTokens[#resultTokens + 1] = {tokenType = tokens.TokenType.NUMBER_VALUE; value = number; line = line; column = column - #word - 1};
        elseif

        --STRINGS
        c == '"' or c == "'" then
            local closer = c;
            nextChar()
            while c and c~='\n' and c ~= closer do

                local escape = false;

                --ESCAPE SEQUENCES
                if c == '\\' then
                    escape = true;
                    nextChar()
                    if string.find(validEscapes, c, 1, true) then
                        if(c == 'x') then
                            for i=0, 1, 1 do
                                nextChar()
                                if(not (string.find(numbers, c, 1, true) or string.find(hexSymbols, c, 1, true))) then
                                print("invalid X escape sequence"); return;
                                end
                            end
                        end
                        word = word .. c;
                        nextChar()
                    elseif string.find(numbers, c, 1, true) then
                        repeat
                            word = word .. c;
                            nextChar()
                        until(~string.find(numbers, c, 1, true))
                    else
                            print('invalid escape sequence at line ' .. line)
                        return;
                    end
                end
                
                if not escape then
                    word = word .. c;
                    nextChar()
                end
            end

            if c == closer then
                resultTokens[#resultTokens + 1] = {tokenType = tokens.TokenType.STRING_VALUE; value = word; line = line; column = column - #word - 1};
                nextChar()
            else
                print('error unfinished string');
                print('last character ' .. c);
                print('line ' .. line)
                return;
            end
        elseif

        --MARKERS OR MULTILINE STRING
        string.find(marker, c, 1, true) then

            if(c == '[') then
                DEBUGLINE = line;
                nextChar()
                local numberOfEquals = 0;
                if c == '=' then
                    numberOfEquals = numberOfEquals + 1;
                    nextChar()
                end
                if c == '[' then
                    local latest = '';
                    local paragraph = '';
                    local closingSequence = (']' .. string.rep('=', numberOfEquals) .. ']');
                    nextChar()
                    while latest ~= closingSequence and c do
                        paragraph = paragraph .. c;
                        if #latest == 2 + numberOfEquals then
                            latest = string.sub(latest, 2, 2 + #latest) .. c;
                        else
                            latest = latest .. c;
                        end
                        nextChar()
                    end
                    if latest ~= closingSequence then print('unfinished string ' .. DEBUGLINE) return; end;
                    paragraph = string.sub(paragraph, 1, #paragraph - 2 - numberOfEquals);
                    resultTokens[#resultTokens + 1] = {tokenType = tokens.TokenType.STRING_VALUE; value = paragraph; line = line; column = column - #paragraph - 1};
                else
                    if(numberOfEquals > 0) then print("invalid long string delimiter " .. DEBUGLINE) return; end;
                    resultTokens[#resultTokens + 1] = {tokenType = tokens.MapMarkers['[']; line = line; column = column};
                end
            else
                resultTokens[#resultTokens + 1] = {tokenType = tokens.MapMarkers[c]; line = line; column = column};
                nextChar()
            end
        elseif

        --OPERATORS OR COMMENTS
        string.find(operator, c, 1, true) then
            comment = false;
            word = word .. c;
            nextChar()
            while(c and string.find(operator, c, 1, true)) do
                if not (
                        (word == '=' and c == '=') or 
                        (word == '.' and c == '.') or
                        (word == '<' and c == '=') or
                        (word == '>' and c == '=') or
                        (word == '~' and c == '=') or
                        (word == ':' and c == ':') or
                        (word == '-' and c == '-') or
                        (word == '..' and c == '.') or
                        (word == '-' and c == '>')
                    )
                then break end;

                word = word .. c;
                if word == '--' then comment = true; break end;
                nextChar()
            end

            if tokens.MapOperators[word] then
                resultTokens[#resultTokens + 1] = {tokenType = tokens.MapOperators[word]; line = line; column = column - #word - 1; value = word};
            end
        elseif c ~= nil then
            if not string.find(whitespace, c, 1, true) then
                print('unexpected symbol ' .. c .. ' at line ' .. line)
                return
            end
            nextChar()
        end

        --COMMENTS
        if comment then
            nextChar()
            local brackets = '';
            local numberOfEquals = 0;
            local inside = false;
            multiline = false;
            while c and c ~= '\n' do
                if brackets == '[' then 
                    inside = true 
                end;

                if c == '=' and inside then
                    numberOfEquals = numberOfEquals + 1;
                else
                    brackets = brackets .. c
                end
                
                if brackets == '[[' then
                    multiline = true;
                    break
                end
                nextChar()
            end

            --MULTILINE COMMENTS
            if multiline then
                content = '';
                while c and content ~= ']' .. string.rep('=', numberOfEquals) .. ']' do
                    if #content == 2 + numberOfEquals then
                        content = string.sub(content, 2, 2 + numberOfEquals) .. c;
                    else
                        content = content .. c;
                    end
                    nextChar()
                end
            else
                nextChar()
            end
        end
    end

    local fileContent = ''
    for key, value in pairs(resultTokens) do
        fileContent = fileContent .. '[' .. value.line .. ':' .. value.column .. ']' .. ' - ' .. value.tokenType .. ' : ' .. (value.value or '_') .. '\n';
    end
    outputFile:write(fileContent);
    print('lexed succesfully');
    return resultTokens;
end

return lexer;