local linker = {};

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

function linker.linkElaFile(path)
    local filename = nil;
    local isMainFile = false;
    if not MainFilePath then
        filename = path:match(".*/(.-)%.");
        MainFilePath = Utils.pathTo(path);
        isMainFile = true;
    else
        filename = string.match(path, "[^.]+$");
        path = Utils.getModulePath(MainFilePath, path);
    end
    if not Utils.fileExists(path) then
        return nil;
    end
    print('now on file ' .. path);
    local Lexems = Lexer.lex(path);
    if Lexems then
        local AST, exportedType = Parser.parse(Lexems);
        if AST then
            local linkResult = Semantic.check(AST, exportedType);
            if linkResult then
                Generator.generate(AST, linkResult, MainFilePath, filename, isMainFile);
            end
            return linkResult;
        end
    end
end

return linker;