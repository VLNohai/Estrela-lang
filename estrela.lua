Lexer = require('lexer');
Tokens = require('tokens');
Parser = require('parser');
local utils = require('prefabs.utils');
Semnatic = require('semantic');
Generator = require('generator');

Path = 'E:/estrela rep/estrela/extra/example.ela';

Lexems = Lexer.lex(Path);
if Lexems then
    AST = Parser.parse(Lexems);
    if AST and Semnatic.check(AST) then
        Generator.generate(AST);
    end
end

local function a(x, y)

end

local function a(x, y)

end
