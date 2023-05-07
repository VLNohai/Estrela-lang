Lexer = require('lexer');
Tokens = require('tokens');
Parser = require('parser');
Utils = require('utils');
Semnatic = require('semantic');
Generator = require('generator');

Path = 'E:/estrela rep/estrela/extra/example.ela';

AST = Parser.parse(Lexer.lex(Path));
if (Semnatic.check(AST)) then
    Generator.generate(AST);
end
