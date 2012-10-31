-module(acceptor).
-export([start/3]).

start(Name, Seed, PanelId) ->
    spawn(fun() -> init(Name, Seed, PanelId) end).

init(Name, Seed, PanelId) ->
    random:seed(Seed, Seed, Seed),
    Promise = order:null(),
    Voted = order:null(),
    Accepted = na,
    acceptor(Name, Promise, Voted, Accepted, PanelId).

acceptor(Name, Promise, Voted, Accepted, PanelId) ->
    receive
        {prepare, Proposer, Round} ->
            case order:gr(..., ...) of
                true ->
                    Proposer ! {promise, ..., ..., ...},
                    % Update gui
                    if
                        Accepted == na ->
                            io:format("[Acceptor ~w] set gui: voted ~w promise ~w colour na~n",
                            [Name, ..., ...]),
                            PanelId ! {updateAcc, "Round voted: " ++ lists:flatten(io_lib:format("~p", [Voted])), "Cur. Promise: " ++ lists:flatten(io_lib:format("~p", [...])), {0,0,0}};
                        true ->
                            io:format("[Acceptor ~w] set gui: voted ~w promise ~w colour ~w~n",
                            [Name, ..., ..., Accepted]),
                            PanelId ! {updateAcc, "Round voted: " ++ lists:flatten(io_lib:format("~p", [Voted])), "Cur. Promise: " ++ lists:flatten(io_lib:format("~p", [...])), Accepted}
                    end,
                    acceptor(Name, ..., Voted, Accepted, PanelId);
                false ->
                    Proposer ! {sorry, ...},
                    acceptor(Name, ..., Voted, Accepted, PanelId)
            end;
        {accept, Proposer, Round, Proposal} ->
            case order:goe(..., ...) of
                true ->
                    Proposer ! {vote, ...},
                    case order:goe(..., ...) of
                        true ->
                            % Update gui
                            io:format("[Acceptor ~w] set gui: voted ~w promise ~w colour ~w~n",
                            [Name, ..., ..., ...]),
                            PanelId ! {updateAcc, "Round voted: " ++ lists:flatten(io_lib:format("~p", [...])), "Cur. Promise: " ++ lists:flatten(io_lib:format("~p", [Promise])), ...},
                            acceptor(Name, Promise, ..., ..., PanelId);
                        false ->
                            % Update gui
                            io:format("[Acceptor ~w] set gui: voted ~w promise ~w colour ~w~n",
                            [Name, ..., ..., ...]),
                            PanelId ! {updateAcc, "Round voted: " ++ lists:flatten(io_lib:format("~p", [...])), "Cur. Promise: " ++ lists:flatten(io_lib:format("~p", [Promise])), ...},
                            acceptor(Name, Promise, ..., ..., PanelId)
                    end;
                false ->
                    Proposer ! {sorry, ...},
                    acceptor(Name, Promise, ..., ..., PanelId)
            end;
        stop ->
            ok
    end.