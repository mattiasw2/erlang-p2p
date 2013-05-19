-module(node).
-export([wait/5]).

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
				true  -> Succ ! {getVal,Who};
				false -> Succ ! {get,Key,Who}
	end.

put(Key,Val,MyKey,Succ)->
	case (between_me_next(Key,MyKey,Succ)) of
				true  -> Succ ! {changeVal,Val};
				false -> Succ ! {put,Key,Val}
	end.

wait(MyId,MyKey,MyVal,Pred,Succ)->
	receive 
		%primitives
		{lookup,Key,Who} -> %changer par une fonction plus pratique
	io:format("~w : receive ~w,~w,~w ~n",[MyId,lookup,Key,Who]),
			io:format("~w lookup return : ~w~n ",[MyId,lookup(Key,Who,MyKey,Succ) == res_lookup]),
			wait(MyId,MyKey,MyVal,Pred,Succ);

		{get,Key,Who} ->
			get(Key,Who,MyKey,Succ),
			wait(MyId,MyKey,MyVal,Pred,Succ);
			
		{put,Key,Val} ->
			put(Key,Val,MyKey,Succ),
			wait(MyId,MyKey,MyVal,Pred,Succ);
		%retour des valeurs
		{get_val,Who} -> 
			Who ! {get_val_res,MyVal},
			wait(MyId,MyKey,MyVal,Pred,Succ);
		{change_val,Val} -> 
			wait(MyId,MyKey,Val,Pred,Succ)
	end.
