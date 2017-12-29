%% @author Ricardo Alberto Harari - ricardo.harari@gmail.com
%% @doc algoritmo genetico para posicionar 8 rainhas em um tabuleiro de xadrez sem que nenhuma ataque a outra 
%% @doc para simplificar, o algortimo considera nao aceitar 2 rainhas na mesma linha.
%% @doc ex resultado: "57248136" significa -> na primeira linha uma rainha esta na coluna 5, na segunda linha uma reinha na coluna 7, ...

-module(eightQueens).

-define(POP_SIZE, 10).
-define(PROB_MUTACAO, 0.15).
-define(MAX_FITNESS, 8).
-define(MAX_ITERACOES, 5000).

%% ====================================================================
-export([start/0]).

%% ====================================================================
start() -> 
	T0 = erlang:system_time(micro_seconds),
	{Status, Indv, Qtd} = iteracoes(?MAX_ITERACOES, carregarPopulacao(?POP_SIZE), ?PROB_MUTACAO, -?MAX_FITNESS),
	T1 = (erlang:system_time(micro_seconds) - T0)/1000,
	io:format("Status: ~w - Iteracoes: ~w - Resultado: ~p - Tempo Processamento: ~w ms ~n", [Status, Qtd, Indv, T1]).

iteracoes(Qtd, Populacao, ProbMutacao, BestFitness) ->
	NewPop = geneticAlgorithm(Populacao, ProbMutacao, BestFitness),
	Fitness = [fitness(X) || X <- NewPop],
	Max1 = lists:max(Fitness),
	Pos1 = string:str(Fitness, [Max1]),
	case Qtd of
		0 -> {fail, lists:nth(Pos1, NewPop), ?MAX_ITERACOES};
		_Else ->
			case Max1 >= ?MAX_FITNESS of
				true -> {ok, lists:nth(Pos1, NewPop), ?MAX_ITERACOES - Qtd};
				false -> iteracoes(Qtd -1, NewPop, ProbMutacao, Max1)
			end
	end.

geneticAlgorithm(Populacao, ProbMutacao, BestFitness) ->
	Filhos = preencherFilhos(removerDuplicados(carregarFilho(?POP_SIZE, Populacao, ProbMutacao, BestFitness))),

	FFitness1 = [fitness(X) || X <- Populacao],
	Max1 = lists:max(FFitness1),
	Pos1 = string:str(FFitness1, [Max1]),
	FFitness2 = lists:sublist(FFitness1,Pos1-1) ++ [-?MAX_FITNESS - 1] ++ lists:nthtail(Pos1,FFitness1),
	Max2 = lists:max(FFitness2),
	Pos2 = string:str(FFitness2, [Max2]),

	FFitnessA = [fitness(X) || X <- Filhos],
	MinA = lists:min(FFitnessA),
	PosA = string:str(FFitnessA, [MinA]),
	FFitnessB = lists:sublist(FFitnessA,PosA-1) ++ [?MAX_FITNESS + 1] ++ lists:nthtail(PosA,FFitnessA),
	MinB = lists:min(FFitnessB),
	PosB = string:str(FFitnessB, [MinB]),
	TmpPop = lists:sublist(Filhos,PosA-1) ++ [lists:nth(Pos1, Populacao)] ++ lists:nthtail(PosA,Filhos),
	lists:sublist(TmpPop,PosB-1) ++ [lists:nth(Pos2, Populacao)] ++ lists:nthtail(PosB,TmpPop).

preencherFilhos(L) ->
	case length(L) of
		?POP_SIZE -> L;
		_Else -> preencherFilhos(L ++ [gerarIndividuo(8)])
	end.

carregarFilho(Size, _, _, _) when Size < 1 -> [];
carregarFilho(Size, Populacao, ProbMutacao, BestFitness) ->
	I1 = selecionarIndividuo(Populacao, ""),
	I2 = selecionarIndividuo(Populacao, I1),
	F1 = crossover(I1, I2),
	Fitness = fitness(F1),
	P1 = random:uniform(),
	case P1 < ProbMutacao of
		true ->
			case Fitness =< BestFitness of
				true ->
					[mutate(F1)] ++ carregarFilho(Size - 1, Populacao, ProbMutacao, Fitness);
				false ->
					[F1] ++ carregarFilho(Size - 1, Populacao, ProbMutacao, BestFitness)
			end;
		false ->
			[F1] ++ carregarFilho(Size - 1, Populacao, ProbMutacao, BestFitness)
	end.

selecionarIndividuo(Populacao, Individuo) ->
	Individuo2 = lists:nth(random:uniform(length(Populacao)), Populacao),
	case Individuo == Individuo2 of
		true -> selecionarIndividuo(Populacao, Individuo);
		false -> Individuo2
	end.

crossover(I1, I2) ->
	N = random:uniform(length(I1) - 1),
	string:substr(I1, 1, N) ++ string:substr(I2, N + 1).

mutate(I1) ->
	L = length(I1) - 1,
	N = random:uniform(length(I1)) - 1,
	S = getRandomGene(),
	case N of
		L -> string:substr(I1, 1, N) ++ S;
		_Else -> string:substr(I1, 1, N) ++ S ++ string:substr(I1, N + 2)
	end.
 
getRandomGene() -> integer_to_list(random:uniform(8)).

fitness(I1) -> fitnessVertical(I1) - fitnessDiagonal(I1, 1, 1) - fitnessDiagonal(I1, 1, -1).
fitnessVertical([]) -> 0;
fitnessVertical([H|T]) ->
	N = string:str(T, [H]),
	case N of 
		0 -> 1 + fitnessVertical(T);
		_Else -> 0 + fitnessVertical(T)
	end.
fitnessDiagonal([H|T], Linha, Direction) -> fitnessDiagonal(H - 48 + Direction, T, Linha + 1, Direction) + fitnessDiagonal(T, Linha + 1, Direction);
fitnessDiagonal([], _, _) -> 0.
fitnessDiagonal(I, _, _, _) when I > 8 orelse I < 1 -> 0;
fitnessDiagonal(_, _, Linha, _) when Linha > 8 -> 0;
fitnessDiagonal(I, [H|T], Linha, Direction) ->
	 I1 = H - 48,
	 case I of
		 I1 -> 1;
		 _Else -> fitnessDiagonal(I + Direction, T, Linha + 1, Direction)
	 end;
fitnessDiagonal(_, [], _, _) -> 0.

removerDuplicados(L) -> S = sets:from_list(L), sets:to_list(S).

%% carregar a populacao inicial
carregarPopulacao(1) -> [gerarIndividuo(8)];
carregarPopulacao(Size) -> [gerarIndividuo(8)] ++ carregarPopulacao(Size - 1).
gerarIndividuo(1) -> integer_to_list(random:uniform(8));
gerarIndividuo(Size) -> integer_to_list(random:uniform(8)) ++ gerarIndividuo(Size - 1).
