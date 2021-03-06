%% @author Couchbase <info@couchbase.com>
%% @copyright 2020 Couchbase, Inc.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%      http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% This process sends itself a message using send_after and then measures
%% the lag of when the message is received vs when it is expected.

-module(timer_lag_recorder).

-include("ns_common.hrl").

%% How often to send ourself a message in milliseconds.
-define(TIMER_INTERVAL, 1000).

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_info/2, handle_cast/2]).

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    send_check_time_msg(),
    {ok, #state{}}.

handle_call(Msg, _From, _State) ->
    erlang:error({unknown_msg, Msg}).

handle_cast(Msg, _State) ->
    erlang:error({unknown_cast, Msg}).

report_missed_msgs(Skipped, Lag) when Skipped > 10 ->
    error_logger:error_msg("Detected time forward jump (or too large "
                           "erlang scheduling latency).  Skipping ~w "
                           "samples (or ~w milliseconds)",
                           [Skipped, Lag]);
report_missed_msgs(Skipped, _Lag) when Skipped > 0 ->
    ?log_warning("Skipped ~p 'check_time' messages", [Skipped]);
report_missed_msgs(_Skipped, _Lag) ->
    ok.

handle_info({check_time, ExpectedTime}, State) ->
    TimeNow = erlang:monotonic_time(millisecond),
    Lag = TimeNow - ExpectedTime,
    system_stats_collector:add_histo(timer_lag, Lag * 1000),

    Skipped = trunc(Lag / ?TIMER_INTERVAL),
    report_missed_msgs(Skipped, Lag),

    send_check_time_msg(),

    {noreply, State}.

send_check_time_msg() ->
    ExpectedTime = erlang:monotonic_time(millisecond) + ?TIMER_INTERVAL,
    erlang:send_after(ExpectedTime, self(), {check_time, ExpectedTime},
                      [{abs, true}]).
