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
    if not MainFilePath then
        filename = path:match(".*/(.-)%.");
        MainFilePath = Utils.pathTo(path);
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
        local AST = Parser.parse(Lexems);
        if AST then
            local linkResult = Semantic.check(AST);
            Generator.generate(AST, MainFilePath, filename);
            return linkResult;
        end
    end
end

return linker;