-module(node).
-export([wait/5]).

% RINGTOP est le + grand index de l'espace de nommage des index
-define(RINGTOP, trunc(math:pow(2,160)-1)). 

%retourne un noeud a partir d'une clef donne
	%besoin d'implementer les finger tables
	% <=> parcours de liste chainee circulaire

%compare si une clef est entre moi et mon voisin
between_me_next(Key,MyKey, MyNeighbor)->
	NextKey = crypto:sha(term_to_binary(MyNeighbor)),
	if
		MyKey > NextKey ->
			Key >= MyKey;
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
				true  -> Succ ! {change_val,Val},
						io:format("~w sends change_val to ~w~n",[Key,Succ]);

				false -> Succ ! {put,Key,Val}
	end.



calcFingerTable(MyId, MyKey, Succ, Who)->
	if Who /= MyKey ->
		FingerTable = computeList(MyId, Succ, MyKey,[],0),
		%io:format("I AM : ~w fingerTable : ~w ~n", [MyId,FingerTable]),
		Succ ! {calcFingerTable, Who}
	end.


initCalcFingerTable(MyId, MyKey,Succ)->
	FingerTable = computeList(MyId,Succ,MyKey,[],0),
	%io:format(" I AM : ~w fingerTable : ~w ~n", [MyId, FingerTable]),
	Succ ! {calcFingerTable, MyKey}.



computeList(MyId, Succ, Key, B , I) ->   
    if I < 80 ->
    	% cle vers integer + calculs
    	A = (binary:decode_unsigned(Key, big) + erlang:round(math:pow(2, I - 1))) rem erlang:round(math:pow(2, 160)),
    	% creation de la liste
    	C = [A|B],
    	computeList(MyId,Succ,Key,C, I+1);
    	I>=80 ->
    	FingerTableInt = lists:reverse(B),
    	% back to binary
		FingerTable = lists:map(fun(X) -> binary:encode_unsigned(X,big) end, FingerTableInt),
		% ajout du nom du noeud
		CompleteFingerTable = lists:map(fun(X) -> {X, succ(MyId,X,Succ)} end, FingerTable),
    	CompleteFingerTable
    end.

succ(MyId, Key, Destinataire) ->
	MyKey = crypto:sha(term_to_binary(MyId)),
	lookup(Key,MyId,MyKey,Destinataire),
	receive
		{res_lookup,Node} -> 
		%io:format("dring resultat du look up ~w key is ~w ~n", [Node,Key]),
		Node
	end.



wait(MyId,MyKey,MyVal,Pred,Succ)->
	receive 
		%primitives
		{lookup,Key,Who} -> %changer par une fonction plus pratique
		io:format("~w : receive ~w,~w,~w ~n",[MyId,lookup,Key,Who]),
		io:format("~w lookup return : ~w~n ",[MyId,lookup(Key,Who,MyKey,Succ) == res_lookup]),
		wait(MyId,MyKey,MyVal,Pred,Succ);

		{get,Key,Who} ->
		io:format("~w : receive ~w,~w,~w ~n",[MyId,get,Key,Who]),
		get(Key,Who,MyKey,Succ),
		wait(MyId,MyKey,MyVal,Pred,Succ);
			
		{put,Key,Val} ->
		io:format("~w : receive ~w,~w,~w ~n",[MyId,put,Key,Val]),
		put(Key,Val,MyKey,Succ),
		wait(MyId,MyKey,MyVal,Pred,Succ);
		
		%retour des valeurs
		{get_val,Who} -> 
			Who ! {get_val_res,MyVal},
			wait(MyId,MyKey,MyVal,Pred,Succ);
		{change_val,Val} -> 
		io:format("~w : receive change val ~w ~w ~n",[MyId,put,Val]),
			wait(MyId,MyKey,Val,Pred,Succ);

		% calcul des fingertables
		{calcFT} ->
			io:format("~w : calcFT received ~n",[MyId]),
			initCalcFingerTable(MyId, MyKey, Succ);

		{calcFingerTable, Who} ->
			calcFingerTable(MyId, MyKey, Succ, Who)
	end.
