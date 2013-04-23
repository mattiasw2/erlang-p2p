-module(node).
-export([wait/5]).

%retourne un noeud a partir d'une clef donne
	%besoin d'implementer les finger tables
	% <=> parcours de liste chainee circulaire

wait(MyId,MyKey,MyVal,Pred,Succ)->
	receive 
		%primitives
		{lookup,Key,Who} -> %changer par une fonction plus pratique
	io:format("~w : receive ~w,~w,~w ~n",[MyId,lookup,Key,Who]),
			if 
				Key == MyKey ->
					Who ! {res_lookup,self()};
				Key /= MyKey ->
					Succ ! {lookup,Key,self()},
					receive
						{res_lookup,Pid} -> 
							Who ! {res_lookup,Pid}
					end
			end,
			wait(MyId,MyKey,MyVal,Pred,Succ);

		{get,Key,Who} ->
			self() ! {lookup,Key,self()},
			receive {res_lookup, Pid} -> 
				Pid ! {get_val,self()},
				receive 
					{get_val_res,Val} -> 
						Who ! {get_val_res,Val}
				end
			end,
			wait(MyId,MyKey,MyVal,Pred,Succ);
			
		{put,Key,Val} ->
			self() ! {lookup,Key,self()},
			receive {res_lookup, Pid} -> 
				Pid ! {change_val,Val}
			end,
			wait(MyId,MyKey,MyVal,Pred,Succ);
		%retour des valeurs
		{get_val,Who} -> Who ! {get_val_res,MyVal},
			wait(MyId,MyKey,MyVal,Pred,Succ);
		{change_val,Val} -> wait(MyId,MyKey,Val,Pred,Succ)
	end.
