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
    {frodo,trt@debug} ! {calcFT},
    timer:sleep(500).
   


