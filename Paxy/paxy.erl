-module(paxy).
-export([start/1, stop/0, stop/1]).

-define(RED, {255,0,0}).
-define(BLUE, {0,0,255}).
-define(GREEN, {0,255,0}).
-define(YELLOW, {255, 255, 0}).
-define(PURPLE, {255, 0, 255}).

start(Seed) ->
    AcceptorNames = ["Acceptor 1", "Acceptor 2", "Acceptor 3", "Acceptor 4", "Acceptor 5", "Acceptor 6", "Acceptor 7", "Acceptor 8", "Acceptor 9", "Acceptor 10", "Acceptor 11", "Acceptor 12", "Acceptor 13", "Acceptor 14", "Acceptor 15", "Acceptor 16", "Acceptor 17"],
    AccRegister = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q],
    ProposerNames = ["Proposer 1", "Proposer 2", "Proposer 3", "Proposer 4", "Proposer 5", "Proposer 6", "Proposer 7", "Proposer 8", "Proposer 9", "Proposer 10"],
    PropInfo = [{kurtz, ?GREEN, 3}, {kilgore, ?BLUE, 2}, {cillard, ?YELLOW, 7}, {andy, ?RED, 10}, {george, ?PURPLE, 8}, {six, {128, 0, 0}, 16}, {seven, {128, 255, 0}, 17}, {eight, {128, 0, 255}, 18}, {nine, {128, 255, 255}, 19}, {ten, {0, 128, 128}, 20}],
    % computing panel heights
    AccPanelHeight = length(AcceptorNames)*50 + 20, %plus the spacer value
    PropPanelHeight = length(ProposerNames)*50 + 20,
    register(gui, spawn(fun() -> gui:start(AcceptorNames, ProposerNames,
    AccPanelHeight, PropPanelHeight) end)),
    gui ! {reqState, self()},
    receive
        {reqState, State} ->
            {AccIds, PropIds} = State,
            start_acceptors(AccIds, AccRegister, Seed),
            start_proposers(PropIds, PropInfo, AccRegister, Seed+1)
    end,
    true.

start_acceptors(AccIds, AccReg, Seed) ->
    case AccIds of
        [] ->
            ok;
        [AccId|Rest] ->
            [RegName|RegNameRest] = AccReg,
            register(RegName, acceptor:start(RegName, Seed, AccId)),
            start_acceptors(Rest, RegNameRest, Seed+1)
    end.

start_proposers(PropIds, PropInfo, Acceptors, Seed) ->
    case PropIds of
        [] ->
            ok;
        [PropId|Rest] ->
            [{RegName, Colour, Inc}|RestInfo] = PropInfo,
            proposer:start(RegName, Colour, Acceptors, Seed+Inc, PropId),
            start_proposers(Rest, RestInfo, Acceptors, Seed)
    end.

stop() ->
    stop(gui),
    stop(a),
    stop(b),
    stop(c),
    stop(d),
    stop(e).

stop(Name) ->
    case whereis(Name) of
        undefined ->
            ok;
        Pid ->
            Pid ! stop
    end.
