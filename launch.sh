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
    %io:format("~w ~n",[X]),
    {e,trt@debug} ! {lookup,<<141,186,206,103,134,101,197,13,232,151,223,244,198,14,130,52,173,111,182,83>>,self()},
    receive 
        {res_lookup,Node} -> 
            io:format(" main receive ~w ~n",[Node])
    end.

get([{A,B}],N) -> A;
get([{A,B}|L],0) -> A;
get([{A,B}|L],N) ->
    get(L,N - 1).
