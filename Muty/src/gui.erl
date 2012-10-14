%% Author: peter
%% Created: 3 Oct 2012
%% Description: TODO: Add description to gui
-module(gui).

%%
%% Include files
%%
-include_lib("wx/include/wx.hrl").

%%
%% Exported Functions
%%
-export([start/1, init/1]).

%%
%% API Functions
%%
start(Name) ->
	spawn(gui, init, [Name]).

init(Name) ->
	Width = 200,
	Height = 200,
	Server = wx:new(), %Server will be the parent for the Frame
	Frame = wxFrame:new(Server, -1, Name, [{size,{Width, Height}}]),
	wxFrame:show(Frame),
	loop(Frame).

%%
%% Local Functions
%%
loop(Frame)->
	receive
		waiting ->
			%wxYELLOW doesn’t exist in "wx/include/wx.hrl"
			wxFrame:setBackgroundColour(Frame, {255, 255, 0}),
			wxFrame:refresh(Frame),
			loop(Frame);
		taken ->
			wxFrame:setBackgroundColour(Frame, ?wxRED),
			wxFrame:refresh(Frame),
			loop(Frame);
		leave ->
			wxFrame:setBackgroundColour(Frame, ?wxBLUE),
			wxFrame:refresh(Frame),
			loop(Frame);
		stop ->
			ok;
		Error ->
			io:format("gui: strange message ~w ~n", [Error]),
			loop(Frame)
	end.

