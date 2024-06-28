% THE CODE WHILE RUNNING: THE GAME.ERL AND PLAYERS.ERL BOTH NEEDS TO BE COMPILED FIRST, THEN RUN THE GAME.ERL FILE.
% THE GAME RUNS FINE BUT NOT EXACTLY SEQUENTIALLY, LIKE GAME WITH GAME ID 7 MIGHT FINISH ITS GAME BEFORE GAME WITH
% GAME ID 5.
% THE CODE WAS WRITTEN BY ******KHUSHAL JAIN (40233877)******
% NOTE: THE PRINT STATEMENTS MIGHT BE SLIGHTLY DIFFERENT FROM ONE MENTIONED IN THE PDF.
% I AM UNABLE TO RUN THE CODE USING "erl -noshell -run game start p1.txt -s init stop" ON DOCKER AS WELL AS WINDOWS CMD.
% I RAN ON DOCKER BY COMPILING BOTH THE FILES SEPARATELY AND THEN RAN IS USING "game:start(["players.txt"])."
-module(game).
-export([start/1, master/2, get_active_players/1]).

-import(rand, [uniform/1]).

start([PlayerFile]) ->
    io:fwrite("**RPS championship**\n\n\n"),
    Dict = #{},
    {ok, PlayerInfo} = file:consult(PlayerFile),
    MasterId = self(),
    PlayerList = lists:map(fun({Name, Credits}) -> {Name, Credits, []} end, PlayerInfo),
    Players = lists:map(fun({Name, Credits}) ->
                              {Name, Credits, spawn(players, player, [Name, MasterId, []])}
                      end, PlayerInfo),
    ets:new(player_credits_table, [named_table, set, public]),
    lists:foreach(fun({Name, Credits, _}) -> ets:insert(player_credits_table, {Name, Credits}) end, Players),
    timer:sleep(uniform(100)),
    lists:foreach(fun({Name, _, Pid}) -> Pid ! {start, Name, Players} end, Players),
    master(Dict, 1).



master(Dict, Game_id) ->
    receive
        {requestNewGame, Name1, Id1, Name2, Id2} ->
            timer:sleep(100),
            io:fwrite("+ [~p] New game for ~p -> ~p\n",[Game_id, Name1, Name2]),
            Dict2 = maps:put(Game_id, {'_','_','_','_'}, Dict),
            timer:sleep(100),
            Id1 ! {sendMove, Game_id, Name1, self()},
            Id2 ! {sendMove, Game_id, Name2, self()},
            master(Dict2, Game_id+1);
        {selfCheck, Pid, Name} ->
            Credits = ets:lookup_element(player_credits_table, Name, 2),
            Pid ! {selfRecv, Credits},
            master(Dict, Game_id);
        {checkCredit, Pid, Name, OppId} ->
            Credits = ets:lookup_element(player_credits_table, Name, 2),
            Pid ! {recvCredits, Credits, OppId},
            master(Dict, Game_id);
        {move, Move, CurrGameid, Pid, Name, Players} ->
            case maps:find(CurrGameid, Dict) of
                {ok,{'_','_','_','_'}} ->
                    Dict2 = maps:put(CurrGameid, {Move, Name, Pid}, Dict),
                    master(Dict2, Game_id);
                {ok, {Move1, Name1, TempPid}} ->
                    io:fwrite("Game id: ~p ~p:~p -> ~p:~p\n",[CurrGameid, Name1, Move1, Name, Move]),
                    Output = determine_winner(Move1, Move),
                    case Output of
                        win ->
                            Credit = ets:lookup_element(player_credits_table, Name, 2),
                            io:fwrite("\n$ [~p] ~p -> ~p Loser is: ~p [Credits left ~p]\n",[CurrGameid, Name1, Name, Name, Credit-1]),
                            UpdatedEntry = {2, Credit-1},
                            ets:update_element(player_credits_table, Name, UpdatedEntry);
                        tie ->
                            io:fwrite("\n[GameId: ~p ~p vs ~p] its a tie\n",[CurrGameid, Name1, Name]),
                            Dict2 = maps:remove(CurrGameid, Dict);
                            % remove the value from dictionary
                        lose ->
                            Credit1 = ets:lookup_element(player_credits_table, Name1, 2),
                            io:fwrite("\n[GameId: ~p ~p vs ~p] Loser is: ~p[Credits left: ~p]\n",[CurrGameid,Name1, Name, Name1,Credit1-1]),
                            UpdatedEntry = {2, Credit1-1},
                            ets:update_element(player_credits_table, Name1, UpdatedEntry)
                    end,
                    ActivePlayers = get_active_players(Players),
                    case length(ActivePlayers) of
                        1 ->
                            Temp = lists:foreach(fun({_,_,Pid}) ->
                        exit(Pid, normal)
                        end, Players),
                        io:fwrite("We have a winner!!!\n"),
                            io:fwrite("Summary\n\nPlayers:\n"),
                            Winner = element(1, lists:nth(1,ActivePlayers)),
                            Winner_Credits = element(2, lists:nth(1,ActivePlayers)),
                            {TempName, TempCreds, _} = lists:keyfind(Winner, 1, Players),
                            io:fwrite("~p: Credits used: ~p Credits left:~p\n",[Winner, TempCreds-Winner_Credits, Winner_Credits]),
                            lists:foreach(
                            fun({Name, _, _}) when Name =:= Winner ->
                            ok;
                            ({Name, Creds, _}) -> io:format("~p: Credits used: ~p, Credits left:0\n", [Name, Creds])
                            end,
                            Players),
                            io:fwrite("Total Games:~p\n",[Game_id]),
                            io:fwrite("Winner of the game is: ~p\n", [Winner]),
                            io:fwrite("See you next year\n");
                        _ ->
                            timer:sleep(100),
                            Cred1 = ets:lookup_element(player_credits_table, Name1, 2),
                            if
                                Cred1 >0 ->
                                    timer:sleep(uniform(100)),
                                    TempPid ! {start, Name1, Players};
                                true ->
                                    ok
                        end,
                        Cred2 = ets:lookup_element(player_credits_table, Name, 2),
                        if
                                Cred2 >0 ->
                                    timer:sleep(uniform(100)),
                                    Pid ! {start, Name, Players};
                                true ->
                                    ok
                        end,
                            master(Dict, Game_id)
                    end
                    
            end
    end.                
                    

determine_winner(rock, scissors) -> win;
determine_winner(scissors, rock) -> lose;
determine_winner(paper, rock) -> win;
determine_winner(rock, paper) -> lose;
determine_winner(scissors, paper) -> win;
determine_winner(paper, scissors) -> lose;
determine_winner(_, _) -> tie.

get_active_players(PlayerList) ->
    Player_And_Credits = lists:map(
        fun({PlayerName, _, _}) ->
            Credits = ets:lookup_element(player_credits_table, PlayerName, 2),
            {PlayerName, Credits}
        end,
        lists:filter(
            fun({PlayerName, _, _}) ->
                Credits = ets:lookup_element(player_credits_table, PlayerName, 2),
                Credits > 0
            end,
            PlayerList
        )
    ),
    Player_And_Credits.