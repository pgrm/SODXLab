-module(gms3).
-export([start/1, start/2]).
-define(arghh, 100).

start(Id) ->
    Rnd = random:uniform(1000),
    Self = self(),
    spawn_link(fun()-> initMaster(Id, Rnd, Self) end).

initMaster(Id, Rnd, Master) ->
    random:seed(Rnd, Rnd, Rnd),
    leader(Id, Master, 1, []).

start(Id, Grp) ->
    Self = self(),
    spawn_link(fun()-> initSlave(Id, Grp, Self) end).

initSlave(Id, Grp, Master) ->
    Self = self(),
    Grp ! {join, Self},
    receive
        {view, N, State, Leader, Peers} ->
            erlang:monitor(process, Leader),
            Master ! {ok, State},
            slave(Id, Master, Leader, N, State, Peers)
        after 1000 ->
            Master ! {error, "no reply from leader"}
    end.

slave(Id, Master, Leader, N, Last, Peers) ->
    receive
        {mcast, Msg} ->
            Leader ! {mcast, Msg},
            slave(Id, Master, Leader, N, Last, Peers);
        {join, Peer} ->
            Leader ! {join, Peer},
            slave(Id, Master, Leader, N, Last, Peers);
        {msg, N, Msg} ->
            Master ! {deliver, Msg},
            slave(Id, Master, Leader, N + 1, Msg, Peers);
        {msg, I, _} when I < N ->
            slave(Id, Master, Leader, N, Last, Peers);    
        {view, _, _, _, View} ->
            slave(Id, Master, Leader, N, Last, View);
        {'DOWN', _Ref, process, Leader, _Reason} ->
            election(Id, Master, N, Last, Peers);
        stop ->
            ok;
        Error ->
            io:format("gms ~w: slave, strange message ~w~n", [Id, Error])
    end.

election(Id, Master, N, Last, [Leader|Rest]) ->
    if
        Leader == self() ->
            bcast(Id, {msg, N, Last}, Rest),
            leader(Id, Master, N, Rest);
        true ->
            erlang:monitor(process, Leader),
            slave(Id, Master, Leader, N, Last, Rest)
    end.

leader(Id, Master, N, Peers) ->
    receive
        {mcast, Msg} ->
            bcast(Id, {msg, N, Msg}, Peers),
            Master ! {deliver, Msg},
            leader(Id, Master, N + 1, Peers);
        {join, Peer} ->
            Master ! request,
            joining(Id, Master, N, Peer, Peers);
        stop ->
            ok;
        Error ->
            io:format("gms ~w: leader, strange message ~w~n", [Id, Error])
    end.

joining(Id, Master, N, Peer, Peers) ->
    receive
        {ok, State} ->
            Peers2 = lists:append(Peers, [Peer]),
            bcast(Id, {view, N, State, self(), Peers2}, Peers2),
            leader(Id, Master, N, Peers2);
        stop ->
            ok
    end.

bcast(Id, Msg, Nodes) ->
    lists:foreach(fun(Node) -> Node ! Msg, crash(Id) end, Nodes).

crash(Id) ->
    case random:uniform(?arghh) of
        ?arghh ->
            io:format("leader ~w: crash~n", [Id]),
            exit(no_luck);
        _ ->
            ok
    end.