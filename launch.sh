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
    			 	
    {d,trt@debug} ! {calcFT, 160},
    timer:sleep(4500),
    {f,trt@debug} ! {logSearch,<<5,197,183,236,203,12,112,78,187,68,106,146,233,225,31,85,75,38,157,137>>},
    timer:sleep(500),
    {y,trt@debug} ! {debug_aff_ft,self()},
    timer:sleep(500),
    receive
    	{R}->
    	ring:aff(R)
    end.
   



