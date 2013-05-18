#!/usr/bin/env escript
%% -*- erlang -*-
%%! -sname trt@debug

%creation anneau
main(L)-> 
LL=lists:map(fun(X) -> 
    list_to_atom(X) end,L),
LL,
{X,List} = ring:launch(node,wait,LL),
%lancement 
ring:go(List),
N=length(List),
test(List,N).

test([X|L],N)->
    %C=get(L,random:uniform(N-1)),
    X ! {lookup,<<112,79,249,193,8,230,23,155,171,51,178,67,50,88,239,113,16,164,241,100>>,self()},
    receive 
        {res_lookup,Node} -> 
            io:format(" main receive ~w ~n",[Node])
    end.

get([{A,B}],N) -> A;
get([{A,B}|L],0) -> A;
get([{A,B}|L],N) ->
    get(L,N - 1).
