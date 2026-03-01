:- module(parser,
[
    parse/2,
    show_parser_error/2
]).

:- encoding(utf8).
:- multifile prolog:message//1.

:- use_module('../lexer/token').
:- use_module(ast).

% Erro sintático
raise_parser_error(Term) :-
    throw(parser_error(Term)).

show_parser_error(parser_error(unexpected(Expected, FoundTokens)), Text) :-
    format(string(Text), "[Erro sintático] Esperava-se ~w, mas encontrou: ~w", [Expected, FoundTokens]).

show_parser_error(parser_error(missing(Expected, AtTokens)), Text) :-
    format(string(Text), "[Erro sintático] Esperava-se ~w em: ~w", [Expected, AtTokens]).

show_parser_error(parser_error(extra_tokens(Tokens)), Text) :-
    format(string(Text), "[Erro sintático] Tokens extras encontrados: ~w", [Tokens]).

prolog:message(parser_error(Term)) -->
    { show_parser_error(parser_error(Term), Text) },
    [ '~s'-[Text] ].

% Lookahead para não consumir tokens nos DCGs a seguir
lookahead(Rest, Rest, Rest).

% Ponto de entrada
parse(Tokens, AST) :- phrase(parse_all(AST), Tokens).

parse_all(AST) --> parse_sum(AST), !, parse_eof.

% Parse eof e lançamento de erro se sobrar tokens
parse_eof --> [tok_eof], !.
parse_eof --> lookahead(Rest), { raise_parser_error(extra_tokens(Rest)) }.

% Soma
parse_sum(AST) --> parse_mul(Left), sum_builder(Left, AST).

sum_builder(Left, AST) --> [tok_plus], !, parse_mul(Right), {Next = sum(Left, Right)}, sum_builder(Next, AST).
sum_builder(Left, AST) --> [tok_minus], !, parse_mul(Right), {Next = sub(Left, Right)}, sum_builder(Next, AST).
sum_builder(AST, AST) --> [].

% Multiplicação
parse_mul(AST) --> parse_pow(Left), mul_builder(Left, AST).

mul_builder(Left, AST) --> [tok_star], !, parse_pow(Right), {Next = mul(Left, Right)}, mul_builder(Next, AST).
mul_builder(Left, AST) --> [tok_slash], !, parse_pow(Right), {Next = div(Left, Right)}, mul_builder(Next, AST).
mul_builder(AST, AST) --> [].

% Exponenciação
parse_pow(AST) --> parse_unary(Left), pow_builder(Left, AST).

pow_builder(Left, pow(Left, Right)) --> [tok_caret], !, parse_pow(Right).
pow_builder(AST, AST) --> [].

% Unário
parse_unary(neg(AST)) --> [tok_minus], !, parse_primary(AST).
parse_unary(pos(AST)) --> [tok_plus], !, parse_primary(AST).
parse_unary(AST) --> parse_primary(AST).

% Primário
parse_primary(int(N)) --> [tok_int(N)], !.
parse_primary(real(R)) --> [tok_real(R)], !.
parse_primary(AST) --> [tok_lparen], !, parse_sum(AST), expect_rparen.

% Se chegou aqui, por conta dos cortes acima, não é int/real/parentese, então lança erro de token inesperado.
parse_primary(_) -->
    lookahead(Rest),
    { raise_parser_error(unexpected("um número ou '('", Rest)) }.

% Checa fechamento de parêntese e lança erro se estiver faltando.
expect_rparen --> [tok_rparen], !.
expect_rparen -->
    lookahead(Rest),
    { raise_parser_error(missing("')'", Rest)) }.