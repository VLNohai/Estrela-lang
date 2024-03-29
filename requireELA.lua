local requireELA = {};

if not Packageloaded then
Packageloaded = true;
Lexer = require('lexer');
Tokens = require('tokens');
Parser = require('parser');
Semantic = require('semantic');
Generator = require('generator');
Utils = require('utils');
MainFilePath = nil;
end

function requireELA.linkElaFile(path)
    local filename = nil;
    local isMainFile = false;
    if not MainFilePath then
        filename = path:match(".*/(.-)%.");
        if not filename then filename = path:match("(.-)%.") end;
        MainFilePath = Utils.pathTo(path);
        isMainFile = true;
    else
        filename = string.match(path, "[^.]+$");
        path = Utils.getModulePath(MainFilePath, path);
    end
    if not Utils.fileExists(path) then
        return nil;
    end
    local Lexems = Lexer.lex(path);
    if Lexems then
        local AST, exportedType = Parser.parse(Lexems, filename);
        if AST then
            local linkResult = Semantic.check(AST, path, exportedType);
            if linkResult and linkResult.safeToGenerate then
                Generator.generate(AST, linkResult, MainFilePath, filename, isMainFile);
            end
            return linkResult;
        end
    end
end

return requireELA;