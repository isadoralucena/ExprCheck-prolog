:- use_module(parser_tests).
:- use_module(lexer_tests).
:- use_module(unit_test).

run_all_tests :-
    run_suite(parser_tests),
    run_suite(lexer_tests).