:- module(lexer,
[
    lexer_string/2,
    show_lexer_error/2
]).
:- multifile prolog:message//1.

% Erro léxico
raise_lexer_error(Msg, Occ) :-
    must_be(string, Msg),
    must_be(string, Occ),
    throw(lexer_error(Msg, Occ)).

show_lexer_error(lexer_error(Msg, Occ), Text) :-
    string_concat("Erro léxico: ", Msg, T1),
    string_concat(T1, ": ", T2),
    string_concat(T2, Occ, Text).
    
prolog:message(lexer_error(Msg, Occ)) -->
    { show_lexer_error(lexer_error(Msg, Occ), Text) },
    [ '~s'-[Text] ].

% Wrapper de string para lista de char
lexer_string(Str, Tokens) :-
    string_chars(Str, Chars), 
    lexer(Chars, Tokens).

% Converte lista de chars para número
number_from_chars(Chars, N) :-
    string_chars(Str, Chars),
    number_string(N, Str).

% Regras básicas do lexer
lexer([], [tok_eof]) :- !.
lexer([' '|T], TokRest) :- lexer(T, TokRest), !.
lexer(['+'|T], [tok_plus|TokRest]) :- lexer(T, TokRest), !.
lexer(['-'|T], [tok_minus|TokRest]) :- lexer(T, TokRest), !.
lexer(['*'|T], [tok_star|TokRest]) :- lexer(T, TokRest), !.
lexer(['/'|T], [tok_slash|TokRest]) :- lexer(T, TokRest), !.
lexer(['^'|T], [tok_caret|TokRest]) :- lexer(T, TokRest), !.
lexer(['('|T], [tok_lparen|TokRest]) :- lexer(T, TokRest), !.
lexer([')'|T], [tok_rparen|TokRest]) :- lexer(T, TokRest), !.

% Trata casos númericos
lexer([C|Cs], Tokens) :-
    char_type(C, digit),
    lexer_num([C|Cs], Tokens), !.

% Erro para caracteres inválidos
lexer([C|_], _) :-
    atom_string(C, Occ),
    raise_lexer_error("Caractere inválido", Occ), !.

% Lexer numérico
lexer_num(Input, [Tok|RestTokens]) :-
    take_integer(Input, IntegerPart, Rest1),
    finish_number(IntegerPart, Rest1, Tok, Rest2),
    lexer(Rest2, RestTokens), !.

% take_integer coleta a parte inteira do número e unifica o resto
take_integer([H|T], [H|R], Rest) :-
    char_type(H, digit),
    take_integer(T, R, Rest), !.

take_integer(Rest, [], Rest) :- !.

% finish_number decide se é real ou int, e unifica o tok correspondente
finish_number(IntegerPart, ['.', D|T], tok_real(N), Rest) :-
    char_type(D, digit),
    take_frac(T, FracPart, Rest),
    append(IntegerPart, ['.', D|FracPart], Chars),
    number_from_chars(Chars, N), !.

finish_number(_, ['.'|T], _, _) :-
    string_chars(Occ, ['.'|T]),
    raise_lexer_error("Número real mal formado (esperava-se números após o ponto)", Occ), !.

finish_number(IntegerPart, Rest, tok_int(N), Rest) :-
    number_from_chars(IntegerPart, N), !.

% take_frac obtem a parte fracionária de um número real e unifica o resto
take_frac([H|T], [H|R], Rest) :-
    char_type(H, digit),
    take_frac(T, R, Rest), !.

take_frac(['.'|Rest], _, Rest) :-
    string_chars(Occ, ['.'|Rest]),
    raise_lexer_error("Número real mal formado (múltiplos pontos)", Occ), !.

take_frac(Rest, [], Rest) :- !.