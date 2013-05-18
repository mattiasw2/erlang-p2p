-module(ring).
-export([launch/3,init/3,create/4,go/1]).

splice(X,Y) ->
    io:format("splice Y: ~w, X: ~w ~n",[Y,X]),
    X ! {next,self()},
    receive NX ->
        Y ! {next,self()},
        receive NY ->
            io:format("splice NY: ~w, NX:~w ~n",[NY,NX]),
            Y ! {set,NX,self()},
            X ! {set,NY,self()},
            receive ok -> ok end,
            receive ok -> ok end
        end
    end.

init(Mod,Fun,[{Name,Node},Cle,0]) ->
    wait(Mod,Fun,[{Name,Node},Cle,0],{Name,Node}).

wait(Mod,Fun,Uid,Next) ->
    receive
        {next,Who} -> Who ! Next, wait(Mod,Fun,Uid,Next);
        {set,NNext,Who} -> Who ! ok, wait(Mod,Fun,Uid,NNext) ;
        start -> %io:format("~w ~w ~w ~w", [Mod,Fun,Uid,Next]), 
            [Id,Cle,Val] = Uid,
            %io:format("start :  ~w ~w ~w ~n",[Id,Cle,Val]),
            Mod:Fun(Id,Cle,Val,null,Next)

    end.

create(Mod,Fun,[{Cle,{Name,Node}}],1) ->
	Pid = spawn(?MODULE,init,[Mod,Fun,[{Name,Node},Cle,0]]),
	%io:format("before register ~w ~n", [Pid]),
	register(Name,Pid),
	%{Pid,[Pid]};
    {{Name,Node},[{Name,Node}]};
	
create(Mod,Fun,[X|L],N) ->
	{P,B} = create(Mod,Fun,L,N-1),
	{Y,A} = create(Mod,Fun,[X],1),
    aff([Y]),
	%R = walk({P,B},N-2),
	splice(P,Y),
    %splice(P,R),
	{P, A ++ B}.
	
launch(Mod,Fun,List) ->
	%io:format("~w", List),
	ListId = lists:map(fun(X) -> {crypto:sha(term_to_binary({X,node()})),
									{X,node()}} end,List),			
	ListSorted = lists:sort(ListId),
    %aff(ListSorted),
	N = length(ListSorted),
    %io:format("nbelem : ~w~n",[N]),
	{A,L} = create(Mod,Fun,ListSorted,N).
	%go(L).
    
walk(X,0) -> X ;
walk(X,N) ->
    X ! {next,self()},
    receive Z ->
        walk(Z,N-1)
    end.

go([]) -> ok ;
go([X|L]) -> 
    %io:format("~w ~n",[X]),
    X ! start, go(L).

aff([X])->
    io:format("~w ~n",[X]);
aff([X|L])->
    io:format("~w ~n- ",[X]),
    aff(L).
