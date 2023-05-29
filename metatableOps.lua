local TokenType = require('tokens').TokenType;
local mapTokensToFields = {
    [TokenType.UNARY_MINUS_OPERATOR] = "__unm";
    [TokenType.PLUS_OPERATOR] = "__add";
    [TokenType.MINUS_OPERATOR] = "__sub";
    [TokenType.STAR_OPERATOR] = "__mul";
    [TokenType.SLASH_OPERATOR] = "__div";
    [TokenType.PERCENT_OPERATOR] = "__mod";
    [TokenType.CARET_OPERATOR] = "__pow";
    [TokenType.DOUBLE_POINT_MARK] = "__concat";
    [TokenType.EQUALS_OPERATOR] = "__eq";
    [TokenType.LESS_OPERATOR] = "__lt";
    [TokenType.LESS_OR_EQUAL_OPERATOR] = "__le"
}

return mapTokensToFields;