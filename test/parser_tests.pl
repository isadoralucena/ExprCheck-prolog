:- module(parser_tests, [run_parser_tests/0]).
:- use_module('../src/lexer/lexer').
:- use_module('../src/parser/parser').
:- use_module('unit_test').            
:- encoding(utf8).

% Valida se a regra Mul possui precedência sobre Sum.
valid_syntax("1 + 2 * 3", sum(int(1), mul(int(2), int(3)))).
% Teste relacionado com a capacidade de inverter a precedência natural.
valid_syntax("(3 + 2) * 7", mul(sum(int(3), int(2)), int(7))).
% Mostra o reconheciemnto dos tipos reais.
valid_syntax("12.3 + 4.56", sum(real(12.3), real(4.56))).
% Prova que a regra Pow aceita um termo Unary como seu segundo operando.
valid_syntax("5 ^ -2", pow(int(5), neg(int(2)))).
valid_syntax("5 ++ 5", sum(int(5), pos(int(5)))).
% Valida a associatividade à direita da potência.
valid_syntax("2 ^ 3 ^ 2", pow(int(2), pow(int(3), int(2)))).
% Valida a associatividade à esquerda da subtração.
valid_syntax("10 - 5 - 2", sub(sub(int(10), int(5)), int(2))).
% Demonstra a ordem de avaliação para operadores de mesma precedência.
valid_syntax("10 / 2 * 5", mul(div(int(10), int(2)), int(5))).
% Teste relacionado com a recursão mútua. Mostra que o parser aceita multiplos níveis de alinhamento sem perder valor atômico.
valid_syntax("((42))", int(42)).
% Valida a aplicação de um unário sobre uma expressão composta. Mostre que o nó neg envolve toda a subárvore sum.
valid_syntax("-(5 + 2)", neg(sum(int(5), int(2)))).

% Erro por falta de balanceamento de parênteses
invalid_input("(5 * 2", parser_error(missing("')'", [tok_eof]))).
% Erro léxico imediato; o símbolo @ não pertence ao alfabeto definido na linguagem.
invalid_input("1 + @", lexer_error("Caractere inválido", "@")).
% Erro por expressão vazia.
invalid_input("()", parser_error(unexpected("um número ou '('", [tok_rparen, tok_eof]))).
% Erro por sequência inválida de operadores.
invalid_input("5 + * 2", parser_error(unexpected("um número ou '('", [tok_star, tok_int(2), tok_eof]))).

valid_syntax_test(Input, ExpectedAST, Result) :-
    lexer:lexer_string(Input, Tokens),
    parser:parse(Tokens, AST),
    assert_equals(ExpectedAST, AST, Result).

invalid_input_test(Input, ExpectedError, Result) :-
    assert_throws(
        (lexer:lexer_string(Input, Tokens), parser:parse(Tokens, _)),
        ExpectedError,
        Result
    ).

test(Name, parser_tests:valid_syntax_test(In, Out)) :-
    valid_syntax(In, Out),
    format(atom(Name), "Aceito: ~s", [In]).

test(Name, parser_tests:invalid_input_test(In, Err)) :-
    invalid_input(In, Err),
    format(atom(Name), "Rejeitado: ~s", [In]).

run_parser_tests :- run_suite(parser_tests), !.