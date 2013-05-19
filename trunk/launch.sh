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
    {e,trt@debug} ! {lookup,<<141,186,206,103,134,101,197,13,232,151,223,244,198,14,130,52,173,111,182,83>>,self()},    
    receive 
        {res_lookup,Node} -> 
            io:format("LOOKUP : main receive ~w ~n",[Node])
    end,			 
	{c,trt@debug} ! {put,<<141,186,206,103,134,101,197,13,232,151,223,244,198,14,130,52,173,111,182,83>>,777}, 
	timer:sleep(500),   
	{b,trt@debug} ! {get,<<141,186,206,103,134,101,197,13,232,151,223,244,198,14,130,52,173,111,182,83>>,self()}, 
	timer:sleep(500),
    receive
    	{get_val_res,Val} ->
        io:format("GET : main receive ~w ~n",[Val])
    end,
    timer:sleep(500),
    c:flush().



