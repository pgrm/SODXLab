%% Author: peter
%% Created: 3 Oct 2012
%% Description: TODO: Add description to lock2
-module(lock2).

%%
%% Exported Functions
%%
-export([init/2]).

%%
%% API Functions
%%
init(Id, Nodes) ->
    open(Id, Nodes).

%%
%% Local Functions
%%
open(MyId, Nodes) ->
    receive
	{take, Master} ->
	    Refs = requests(MyId, Nodes),
	    wait(MyId, Nodes, Master, Refs, [], []);
	{request, From, Ref, _} ->
	    From ! {ok, Ref},
	    open(MyId, Nodes);
	stop ->
	    ok
    end.

requests(MyId, Nodes) ->
    lists:map(
      fun(P) ->
	      R = make_ref(),
	      P ! {request, self(), R, MyId},
	      {R, P}
      end,
      Nodes).

wait(MyId, Nodes, Master, [], _, Waiting) ->
    Master ! taken,
    held(MyId, Nodes, Waiting);
wait(MyId, Nodes, Master, RefsNodes, OkRefsNodes, Waiting) ->
    receive
	{request, From, Ref, RefId} ->
	    {RefsNodes2, OkRefsNodes2, Waiting2} = request_while_waiting(MyId, RefsNodes, OkRefsNodes, Waiting, From, Ref, RefId),
	    wait(MyId, Nodes, Master, RefsNodes2, OkRefsNodes2, Waiting2);
	{ok, Ref} ->
	    RefNode = lists:keyfind(Ref, 1, RefsNodes),
	    RefsNodes2 = lists:keydelete(Ref, 1, RefsNodes),
	    wait(MyId, Nodes, Master, RefsNodes2, [RefNode|OkRefsNodes], Waiting);
	release ->
	    ok(Waiting),
	    open(MyId, Nodes)
    end.

request_while_waiting(MyId, RefsNodes, OkRefsNodes, Waiting, From, Ref, RefId) ->
    if
	MyId < RefId ->
	    Ret = {RefsNodes, OkRefsNodes, [{From, Ref}|Waiting]};
	RefId < MyId ->
	    From ! {ok, Ref},
	    OkRefsNodes2 = lists:keydelete(From, 2, OkRefsNodes),
	    RefsNodes2 = lists:keydelete(From, 2, RefsNodes),
	    R = make_ref(),
	    From ! {request, self(), R, MyId},
	    Ret = {[{R, From}|RefsNodes2], OkRefsNodes2, Waiting}
    end,
    Ret.

ok(Waiting) ->
    lists:map(
      fun({F,R}) ->
	      F ! {ok, R}
      end,
      Waiting).

held(MyId, Nodes, Waiting) ->
    receive
	{request, From, Ref, _} ->
	    held(MyId, Nodes, [{From, Ref}|Waiting]);
	release ->
	    ok(Waiting),
	    open(MyId, Nodes)
    end.
