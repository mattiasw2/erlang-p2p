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
				true  -> Succ ! {change_val,Val},
						io:format("~w sends change_val to ~w~n",[Key,Succ]);

				false -> Succ ! {put,Key,Val}
	end.



calcFingerTable(MyId, MyKey, Succ, Who,FT)->
	io:format("~w got order ~n", [MyId]),
	if Who /= MyKey ->
		io:format("~w order ttmt : is computing ~n", [MyId]),
		FingerTable = computeList(MyId, Succ, MyKey,[],0),
		io:format("I AM : ~w and my fingerTable is : ~w ~n", [MyId,FingerTable]),
		io:format("~w send order to ~w ~n", [MyId, Succ]),
		Succ ! {calcFingerTable, Who};
		true -> FT
	end.


initCalcFingerTable(MyId, MyKey,Succ)->
	FingerTable = computeList(MyId,Succ,MyKey,[],1),
	io:format(" I AM : ~w  and my fingerTable is : ~w ~n", [MyId, FingerTable]),
	Succ ! {calcFingerTable, MyKey}.



computeList(MyId, Succ, Key, B , I) ->   
    if I < 160 ->
    	% calcul
    	A = binary:encode_unsigned(
    		(binary:decode_unsigned(Key, little) + erlang:round(math:pow(2, I - 1))) 
    		rem erlang:round(math:pow(2, 160)), little),

    	C = [A|B],
    	% appel i+1
    	computeList(MyId,Succ,Key,C, I+1);
    	% arrêt
    	I>=160 ->
    	FingerTableBin = lists:reverse(B),

    	io:format("I AM  ~w and bla bla SUCC~n", [MyId]),

		CompleteFingerTable = lists:map(fun(X) -> {X, succ(MyId,X,Succ)} end, FingerTableBin),
		io:format("I AM  ~w and I have FINISHED~n", [MyId]),

    	CompleteFingerTable
    end.

succ(MyId, Key, Destinataire) ->
	%io:format("~w send to ~w ~n",[MyId,Destinataire]),
	MyKey = crypto:sha(term_to_binary(MyId)),
	lookup(Key,MyId,MyKey,Destinataire),
	receive
		{res_lookup,Node} -> 
		%io:format("dring resultat du look up ~w key is ~w ~n", [Node,Key]),
		Node
	end.



wait(MyId,MyKey,MyVal,Pred,Succ,FT)->
	receive 
		%primitives
		{lookup,Key,Who} -> %changer par une fonction plus pratique
			io:format("~w : receive ~w,~w,~w ~n",[MyId,lookup,Key,Who]),
			io:format("~w lookup return : ~w~n ",[MyId,lookup(Key,Who,MyKey,Succ)]),
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
		{calcFT} ->
			io:format("~w : calcFT received ~n",[MyId]),
			FT2 = initCalcFingerTable(MyId, MyKey, Succ),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT2);

		{calcFingerTable, Who} ->
			io:format("~w : calcFT received ~n",[MyId]),
			FT2 = calcFingerTable(MyId, MyKey, Succ, Who,FT),
			wait(MyId,MyKey,MyVal,Pred,Succ,FT2)
	end.
