%% Author: peter
%% Created: 3 Oct 2012
%% Description: TODO: Add description to lock3
-module(lock3).

%%
%% Exported Functions
%%
-export([init/2]).

%%
%% API Functions
%%
init(MyId, Nodes) ->
    open(Nodes, MyId, 0).

%%
%% Local Functions
%%
open(Nodes, MyId, MyTime) ->
    receive
	{take, Master} ->
	    Refs = requests(Nodes, MyId, MyTime),
	    wait(Nodes, Master, Refs, [], MyId, MyTime, MyTime);
	{request, From, Ref, _, OtherTime} ->
		NewTime = new_time(MyTime, OtherTime),
	    From ! {ok, Ref, NewTime},
	    open(Nodes, MyId, NewTime);
	stop ->
	    ok
    end.

requests(Nodes, MyId, MyTime) ->
    lists:map(
      fun(P) ->
	      R = make_ref(),
	      P ! {request, self(), R, MyId, MyTime},
	      {R, P}
      end,
      Nodes).

wait(Nodes, Master, [], Waiting, MyId, MyTime, _) ->
    Master ! taken,
    held(Nodes, Waiting, MyId, MyTime);
wait(Nodes, Master, RefsNodes, Waiting, MyId, MyTime, RequestTime) ->
    receive
	{request, From, Ref, OtherId, OtherTime} ->
		NewTime = new_time(MyTime, OtherTime),
	    {RefsNodes2, Waiting2} = request_while_waiting(RefsNodes, Waiting, From, Ref, MyId, NewTime, RequestTime, OtherId, OtherTime),
	    wait(Nodes, Master, RefsNodes2, Waiting2, MyId, new_time(MyTime, OtherTime), RequestTime);
	{ok, Ref, OtherTime} ->
	    RefsNodes2 = lists:keydelete(Ref, 1, RefsNodes),
	    wait(Nodes, Master, RefsNodes2, Waiting, MyId, new_time(MyTime, OtherTime), RequestTime);
	release ->
	    ok(Waiting, MyTime),
	    open(Nodes, MyId, MyTime)
    end.

request_while_waiting(RefsNodes, Waiting, From, Ref, MyId, MyTime, RequestTime, OtherId, OtherTime) ->
	MyTurn = my_priority_higher(MyId, RequestTime, OtherId, OtherTime),
    if
	MyTurn ->
	    Ret = {RefsNodes, [{From, Ref}|Waiting]};
    true ->
        NewTime = new_time(MyTime, OtherTime),
        From ! {ok, Ref, NewTime},
        Ret = {RefsNodes, Waiting}
    end,
    Ret.

my_priority_higher(MyId, RequestTime, OtherId, OtherTime) ->
	if
	RequestTime < OtherTime ->
		Ret = true;
	true ->
		if
		RequestTime == OtherTime ->
			Ret = (MyId < OtherId);
		true ->
			Ret = false
		end
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

held(Nodes, Waiting, MyId, MyTime) ->
    receive
	{request, From, Ref, _, OtherTime} ->
	    held(Nodes, [{From, Ref}|Waiting], MyId, new_time(MyTime, OtherTime));
	release ->
	    ok(Waiting, MyTime),
	    open(Nodes, MyId, MyTime)
    end.
