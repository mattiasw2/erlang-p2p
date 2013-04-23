-module(ring).
-export([launch/3,init/3,create/4,go/1]).

splice(X,Y) ->
    X ! {next,self()},
    receive NX ->
        Y ! {next,self()},
        receive NY ->
            Y ! {set,NX,self()},
            X ! {set,NY,self()},
            receive ok -> ok end,
            receive ok -> ok end
        end
    end.

init(Mod,Fun,Param) ->
    wait(Mod,Fun,Param,self()).

wait(Mod,Fun,Uid,Next) ->
    receive
        {next,Who} -> Who ! Next, wait(Mod,Fun,Uid,Next) ;
        {set,NNext,Who} -> Who ! ok, wait(Mod,Fun,Uid,NNext) ;
        start -> io:format("~w ~w ~w ~w", [Mod,Fun,Uid,Next]), Mod:Fun(Uid,Next)
    end.

create(Mod,Fun,[{Cle,{Name,Node}}],1) ->
	Pid = spawn(?MODULE,init,[Mod,Fun,[{Name,Node},Cle,0]]),
	%io:format("~w", [Pid]),
	register(Name,Pid),
	{Pid,[Pid]};
	
create(Mod,Fun,[X|L],N) ->
	{P,B} = create(Mod,Fun,L,N-1),
	{Y,A} = create(Mod,Fun,[X],1),
	%R = walk({X,A},N-2),
	splice(P,Y),
	{P, A ++ B}.
	
launch(Mod,Fun,List) ->
	%io:format("~w", List),
	ListId = lists:map(fun(X) -> {crypto:sha(term_to_binary({X,node()})),
									{X,node()}} end,List),			
	ListSorted = lists:sort(ListId),
	N = length(ListSorted),
	{X,L} = create(Mod,Fun,ListSorted,N).
	%go(L).
    
walk(X,0) -> X ;
walk(X,N) ->
    X ! {next,self()},
    receive Z ->
        walk(Z,N-1)
    end.

go([]) -> ok ;
go([X|L]) -> X ! start, go(L).
