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
test(List,N),
createJInterface(List).


test([X|L],N)->
    			 	    
%% LOOKUP   

	{alpha, trt@debug} ! {lookup,<<37,223,227,122,143,5,161,114,235,127,71,120,216,88,158,38,130,0,217,156>>,self()},
	receive
    	{res_lookup,Succ} -> 
			io: format(" Le résultat du lookup est : ~w ~n", [Succ])
    end,
   
%% PUT
	{papa, trt@debug} ! {put,<<37,223,227,122,143,5,161,114,235,127,71,120,216,88,158,38,130,0,217,157>>,777},
	timer:sleep(500),


%% GET
	{papa, trt@debug} ! {get,<<37,223,227,122,143,5,161,114,235,127,71,120,216,88,158,38,130,0,217,157>>,self()},
	receive
		{get_val_res, Who} ->
			io: format(" Le résultat du get est : ~w~n", [Who])		
	end.

  
   
createJInterface(List) ->
	{j,'java@localhost'} ! {self(), List},
	receive
		{Res} -> 
			io:format("~w ! Echange avec Java ok !", [Res])
	end.



