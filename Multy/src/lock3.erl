%% Author: peter
%% Created: 3 Oct 2012
%% Description: TODO: Add description to lock2
-module(lock3).

%%
%% Exported Functions
%%
-export([init/2]).

%%
%% API Functions
%%
init(_, Nodes) ->
    open(Nodes, 0).

%%
%% Local Functions
%%
open(Nodes, MyTime) ->
    receive
	{take, Master} ->
	    Refs = requests(Nodes, MyTime),
	    wait(Nodes, Master, Refs, [], [], MyTime);
	{request, From, Ref, OtherTime} ->
		NewTime = new_time(MyTime, OtherTime),
	    From ! {ok, Ref, NewTime},
	    open(Nodes, NewTime);
	stop ->
	    ok
    end.

requests(Nodes, MyTime) ->
    lists:map(
      fun(P) ->
	      R = make_ref(),
	      P ! {request, self(), R, MyTime},
	      {R, P}
      end,
      Nodes).

wait(Nodes, Master, [], _, Waiting, MyTime) ->
    Master ! taken,
    held(Nodes, Waiting, MyTime);
wait(Nodes, Master, RefsNodes, OkRefsNodes, Waiting, MyTime) ->
    receive
	{request, From, Ref, OtherTime} ->
	    {RefsNodes2, OkRefsNodes2, Waiting2} = request_while_waiting(RefsNodes, OkRefsNodes, Waiting, From, Ref, MyTime, OtherTime),
	    wait(Nodes, Master, RefsNodes2, OkRefsNodes2, Waiting2, new_time(MyTime, OtherTime));
	{ok, Ref, OtherTime} ->
	    RefNode = lists:keyfind(Ref, 1, RefsNodes),
	    RefsNodes2 = lists:keydelete(Ref, 1, RefsNodes),
	    wait(Nodes, Master, RefsNodes2, [RefNode|OkRefsNodes], Waiting, new_time(MyTime, OtherTime));
	release ->
	    ok(Waiting, MyTime),
	    open(Nodes, MyTime)
    end.

request_while_waiting(RefsNodes, OkRefsNodes, Waiting, From, Ref, MyTime, OtherTime) ->
    if
	MyTime > OtherTime ->
		NewTime = new_time(MyTime, OtherTime),
	    From ! {ok, Ref, NewTime},
	    OkRefsNodes2 = lists:keydelete(From, 2, OkRefsNodes),
	    RefsNodes2 = lists:keydelete(From, 2, RefsNodes),
	    R = make_ref(),
	    From ! {request, self(), R, NewTime},
	    Ret = {[{R, From}|RefsNodes2], OkRefsNodes2, Waiting};
	true ->
	    Ret = {RefsNodes, OkRefsNodes, [{From, Ref}|Waiting]}
    end,
    Ret.

new_time(MyTime) -> MyTime + 1.
new_time(MyTime, OtherTime) ->
	if
		MyTime > OtherTime ->
			Ret = new_time(MyTime);
		true ->
			Ret = new_time(OtherTime)
	end,
	Ret.

ok(Waiting, MyTime) ->
    lists:map(
      fun({F,R}) ->
	      F ! {ok, R, MyTime}
      end,
      Waiting).

held(Nodes, Waiting, MyTime) ->
    receive
	{request, From, Ref, OtherTime} ->
	    held(Nodes, [{From, Ref}|Waiting], new_time(MyTime, OtherTime));
	release ->
	    ok(Waiting, MyTime),
	    open(Nodes, MyTime)
    end.
