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
createJInterface(List),
test(List,N).

test([X|L],N)->
    			 	
    {papa,trt@debug} ! {calcFT, 20},
    timer:sleep(4500).
   
createJInterface(List) ->
	io:format("Je suis dans createJInterface avec la liste : ~w ~n",[List]),
	{j,'java@localhost'} ! {self(), List},
	receive
		{Res} -> 
			io:format("~w ! Echange avec Java ok ! ~p", [Res])
	end.



