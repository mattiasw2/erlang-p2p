-module(node).
-export([wait/6]).

% RINGTOP est le + grand index de l'espace de nommage des index
-define(RINGTOP, trunc(math:pow(2,160)-1)). 

%retourne un noeud a partir d'une clef donne
	%besoin d'implementer les finger tables
	% <=> parcours de liste chainee circulaire

%compare si une clef est entre moi et mon voisin
between_me_next(Key,MyKey, MyNeighbor)->
	NextKey = crypto:sha(term_to_binary(MyNeighbor)),
	hash_between_me_next(Key,MyKey,NextKey).


hash_between_me_next(Key,MyKey,NextKey)->
	if
		MyKey > NextKey ->
			Key >= MyKey orelse Key < NextKey;
		MyKey < NextKey->
		if 

			%cas normal
			Key >= MyKey ->%andalso Key < NextKey -> 
				%io:format("lookup => Key >= MyKey~n",[]),
				if
					Key < NextKey ->
						%io:format("lookup => Key < NextKey => True~n",[]),
						true;
					true ->
						%io:format("lookup => return false ~n",[]),
						false
				end;
			true ->
				false
		end
	end.

lookup(Key,Who,MyKey,Succ)->
	case (between_me_next(Key,MyKey,Succ)) of
		true  -> Who ! {res_lookup,Succ},true;
		false -> Succ ! {lookup,Key,Who},false
	end.

get(Key,Who,MyKey,Succ)->
	case (between_me_next(Key,MyKey,Succ)) of
		true  -> Succ ! {get_val,Who};
		false -> Succ ! {get,Key,Who}
	end.

put(Key,Val,MyKey,Succ)->
	case (between_me_next(Key,MyKey,Succ)) of
		true  -> Succ ! {change_val,Val};	
		false -> Succ ! {put,Key,Val}
	end.



calcFingerTable(MyId, MyKey, Succ, Who,FT, M)->
	if Who /= MyKey ->
		FingerTable = computeList(MyId, Succ, MyKey,[],1, M),
		Succ ! {calcFingerTable, Who, M},
		FingerTable;
		true -> FT
	end.


initCalcFingerTable(MyId, MyKey,Succ, M)->
	FingerTable = computeList(MyId,Succ,MyKey,[],1, M),
	Succ ! {calcFingerTable, MyKey, M},
	FingerTable.



computeList(MyId, Succ, Key, B , I, M) -> 
    if I < M ->
    	% calcul
    	A = binary:encode_unsigned(
    		(binary:decode_unsigned(Key, little) + erlang:round(math:pow(2, I - 1))) 
    		rem erlang:round(math:pow(2, M)), little),
    	C = [A|B],
    	% appel i+1
    	computeList(MyId,Succ,Key,C, I+1, M);
    	% arrêt
    	I >= M ->
    	FingerTableBin = lists:reverse(B),
		CompleteFingerTable = lists:map(fun(X) -> {X, succ(MyId,X,Succ)} end, FingerTableBin),
    	CompleteFingerTable
    end.


succ(MyId, Key, Destinataire) ->
	%io:format("~w send to ~w ~n",[MyId,Destinataire]),
	MyKey = crypto:sha(term_to_binary(MyId)),
	lookup(Key,MyId,MyKey,Destinataire),
	receive
		{res_lookup,Node} -> 
		Node
	end.

find_successor(N, Key, Succ,FT) ->
	io:format("LOG ~w entre dans find_successor ~w ~n",[N, Key]),
	Pred = find_predecessor(N,Key,Succ,FT, N),
	receive
		{res_lookupLOG, Result} ->
		io:format("Res:LOG ~w sort de find_successor ~w avec ~w ~n",[N, Key, Result]),
		Result
	end.

find_predecessor(N, Key, Succ, FT, Who) ->
	io:format("LOG ~w entre dans find_predecessor ~w ~n",[N, Key]),
	Aux = N,
	KN = crypto:sha(term_to_binary(N)),
	%if Aux <= Key andalso Key <= succ(N, Aux, Succ) ->
	case (between_me_next(Key,KN,Succ)) of
		true->
			Who ! {res_lookupLOG, Succ},
			io:format("LOG ~w sort de find_predecessor ~w ~n",[N, Key]),
			Aux;
		false->
			Aux2 = closest_preceding_finger(Aux, Key, Succ,FT),
			%find_predecessor(Aux2, Key, Succ,FT)
			io:format("debug=> node ~w passe a ~w ~n",[N,Aux2]),
			Aux2 ! {find_predecessor, Key, Who}
	end.


closest_preceding_finger(N,_,_,[])->N;

closest_preceding_finger(N,Key,Succ,[{K,No}|L]) ->
	io:format("LOG ~w entre dans closest_preceding_finger ~w ~n",[N, Key]),
	KN = crypto:sha(term_to_binary(N)),
	%id in (n,id)
	case (hash_between_me_next(K,KN,Key)) of
		%K >= KN andalso K <= Key->
		true->
			io:format("LOG ~w sort de closest_preceding_finger ~w ~n",[N, Key]),			
			No;
		false->
			closest_preceding_finger(N,Key,Succ,L)
	end .


wait(MyId,MyKey,MyVal,Pred,Succ,FT)->
	receive 
		%primitives
		{lookup,Key,Who} -> %changer par une fonction plus pratique
			lookup(Key,Who,MyKey,Succ),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT);

		{get,Key,Who} ->
		io:format("~w : receive ~w,~w,~w ~n",[MyId,get,Key,Who]),
		get(Key,Who,MyKey,Succ),
		wait(MyId,MyKey,MyVal,Pred,Succ,FT);
			
		{put,Key,Val} ->
		io:format("~w : receive ~w,~w,~w ~n",[MyId,put,Key,Val]),
		put(Key,Val,MyKey,Succ),
		wait(MyId,MyKey,MyVal,Pred,Succ,FT);
		
		%retour des valeurs
		{get_val,Who} -> 
			Who ! {get_val_res,MyVal},
			wait(MyId,MyKey,MyVal,Pred,Succ,FT);
		{change_val,Val} -> 
		io:format("~w : receive change val ~w ~w ~n",[MyId,put,Val]),
			wait(MyId,MyKey,Val,Pred,Succ,FT);

		% calcul des fingertables
		{calcFT, M} ->
			FT2 = initCalcFingerTable(MyId, MyKey, Succ, M),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT2);

		{calcFingerTable, Who, M} ->
			%io:format("~w : 2 calcFT received ~n",[MyId]),
			FT2 = calcFingerTable(MyId, MyKey, Succ, Who,FT, M),
			%io:format("CALC FT :  I am : ~w  and my fingerTable is : ~w ~n", [MyId, FT2]),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT2);

		% recherche logarithmique
		{logSearch, Key} ->
			io:format("LOG ~w execute la recherche logarithmique de ~w ~n",[MyId, Key]),
			Node = find_successor(MyId, Key, Succ,FT),
			io:format("LOG ~w a recu pour reponse ~w ~n",[MyId, Node]),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT);
		{find_predecessor, Key, Who} ->
			find_predecessor(MyId, Key, Succ, FT, Who),
			io:format("LOG changement de noeud -> ~w ~w ~n",[MyId, Key]),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT);
		{debug_aff_ft,Who}->
		    LL = lists:map(fun({X,Y})-> {binary:decode_unsigned(X,little),Y} end,FT),
    		%ring:aff(LL),
			Who  ! {LL}
	end.
