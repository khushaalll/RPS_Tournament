-module(players).
-export([player/3, remove_player_by_name/2]).
-import(rand, [uniform/1]).
player(Name, MasterId, PlayerList) ->
    receive
        {start, RName, Players} ->
            timer:sleep(uniform(100)),
            MasterId ! {selfCheck, self(), Name},
            receive
                {selfRecv, Creds} ->
                    if
                        Creds =<0 ->
                            self() ! {start, Name, PlayerList};
                        Creds > 0 ->
            Opponents = remove_player_by_name(Players, RName),
            {_,_,Opp_Pid} = lists:nth(uniform(length(Opponents)), Opponents),
            Opp_Pid ! {send, self()}
            end
        end,
        player(Name, MasterId, Players);
        {send, OppId} ->
            MasterId ! {checkCredit, self(), Name, OppId},
            player(Name, MasterId, PlayerList);
        {recvCredits, Credits, OppId} ->
            if
                Credits > 0 ->
                    OppId ! {accept, Name, self(), PlayerList};
                Credits =< 0 ->
                    io:fwrite("Game rejected by ~p\n",[Name]),
                    OppId ! {start, Name, PlayerList}
            end,
            timer:sleep(uniform(100)),
            player(Name, MasterId, PlayerList);
        {accept, OppName, OppId, Players} ->
            MasterId ! {requestNewGame, Name, self(), OppName, OppId},
            timer:sleep(uniform(100)),
            player(Name, MasterId, Players);
        {reject, OppName, OppId, Players} ->
            io:fwrite("INTO REJECTION, REJECTED BY: ~p\n",[Name]),
            timer:sleep(uniform(100)),
            player(Name, MasterId, Players);
        {sendMove, Game_id, Name, MasterId} ->
                MyMove = make_a_guess(),
                MasterId ! {move, MyMove, Game_id, self(), Name, PlayerList},
                player(Name, MasterId, PlayerList)       
    end.

remove_player_by_name(PlayerList, NameToExclude) ->
    lists:filter(fun({Name, Credits, Id}) -> Name /= NameToExclude end, PlayerList).


make_a_guess()->
    Moves = [rock, paper, scissors],
    MoveIndex = rand:uniform(length(Moves)),
    Move = lists:nth(MoveIndex, Moves),
    Move.