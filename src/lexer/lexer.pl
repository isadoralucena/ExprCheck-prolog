:- module(lexer, [raise_lexer_error/2, show_lexer_error/2]).

% Tipo de erro do lexer
raise_lexer_error(Msg, Occ) :-
    must_be(string, Msg),
    must_be(string, Occ),
    throw(error(lexer_error(Msg, Occ), _)).

show_lexer_error(lexer_error(Msg, Occ), Text) :-
    string_concat("Erro léxico: ", Msg, ": ", Occ, Text).


% Wrapper do lexer para entrada String
lexer_string(Str, Tokens) :-
    string_chars(Str, Chars),
    lexer(Chars, Tokens).

% Regras básicas do lexer
lexer([], [tok_eof]).
lexer([' '|T], TokRest) :- lexer(T, TokRest).
lexer(['+'|T], [tok_plus|TokRest]) :- lexer(T, TokRest).
lexer(['-'|T], [tok_minus|TokRest]) :- lexer(T, TokRest).
lexer(['*'|T], [tok_star|TokRest]) :- lexer(T, TokRest).
lexer(['/'|T], [tok_slash|TokRest]) :- lexer(T, TokRest).
lexer(['^'|T], [tok_caret|TokRest]) :- lexer(T, TokRest).
lexer(['('|T], [tok_lparen|TokRest]) :- lexer(T, TokRest).
lexer([')'|T], [tok_rparen|TokRest]) :- lexer(T, TokRest).
lexer([C|_], _) :- throw(error(lexer_error("caractere inválido", C), _)).
