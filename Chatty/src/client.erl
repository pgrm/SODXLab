%% Author: peter
%% Created: Sep 19, 2012
%% Description: TODO: Add description to client
-module(client).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/2, init_client/2]).

%%
%% API Functions
%%
start(ServerPid, MyName) ->
	ClientPid = spawn(client, init_client, [ServerPid, MyName]),
	process_commands(ServerPid, MyName, ClientPid).

init_client(ServerPid, MyName) ->
	ServerPid ! {client_join_req, MyName, self()},
	process_requests().

%%
%% Local Functions
%%

%% This is the background task logic
process_requests() ->
	receive
		{join, Name} ->
			io:format("[JOIN] ~s joined the chat~n", [Name]),
			process_requests();
		{leave, Name} ->
			io:format("[LEAVE] ~s left the chat~n", [Name]),
			process_requests();
		{message, Name, Text} ->
			io:format("[~s] ~s", [Name, Text]),
			process_requests()
	end.

%% This is the main task logic
process_commands(ServerPid, MyName, ClientPid) ->
	%% Read from standard input and send to server
	Text = io:get_line("-> "),
	if
		Text == "exit\n" ->
			ServerPid ! {client_leave_req, MyName, ClientPid};
		true ->
			ServerPid ! {send, MyName, Text},
			process_commands(ServerPid, MyName, ClientPid)
	end.
