%% @author Couchbase <info@couchbase.com>
%% @copyright 2011-2018 Couchbase, Inc.
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

-module(ale).

-behaviour(gen_server).

-export([start_link/0,
         start_sink/3, stop_sink/1,
         start_logger/1, start_logger/2, start_logger/3,
         stop_logger/1,
         add_sink/2, add_sink/3,
         set_loglevel/2, get_loglevel/1,
         set_sink_loglevel/3, get_sink_loglevel/2,
         sync_sink/1,
         sync_all_sinks/0,

         with_configuration_batching/1,

         capture_logging_diagnostics/0,

         %% counterparts of pseudo-functions handled by ale_transform
         get_effective_loglevel/1, is_loglevel_enabled/2, sync/1,

         debug/2, debug/3, xdebug/4, xdebug/5,
         info/2, info/3, xinfo/4, xinfo/5,
         warn/2, warn/3, xwarn/4, xwarn/5,
         error/2, error/3, xerror/4, xerror/5,
         critical/2, critical/3, xcritical/4, xcritical/5]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-compile({parse_transform, ale_transform}).

-include("ale.hrl").

-record(state, {compile_frozen = false :: boolean(),
                sinks                  :: dict:dict(),
                loggers                :: dict:dict()}).

-record(logger, {name      :: atom(),
                 loglevel  :: loglevel(),
                 sinks     :: dict:dict(),
                 formatter :: module()}).

-record(sink, {name     :: atom(),
               loglevel :: loglevel()}).

%% API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_sink(Name, Module, Args) ->
    gen_server:call(?MODULE, {start_sink, Name, Module:meta(), Module, Args}).

with_configuration_batching(Body) ->
    Old = freeze_compilations(),
    case Old of
        true ->
            Body();
        false ->
            try Body()
            after
                thaw_compilations()
            end
    end.

freeze_compilations() ->
    gen_server:call(?MODULE, freeze_compilations, infinity).

thaw_compilations() ->
    ok = gen_server:call(?MODULE, thaw_compilations, infinity).

stop_sink(Name) ->
    gen_server:call(?MODULE, {stop_sink, Name}).

start_logger(Name) ->
    start_logger(Name, ?DEFAULT_LOGLEVEL).

start_logger(Name, LogLevel) ->
    start_logger(Name, LogLevel, ?DEFAULT_FORMATTER).

start_logger(Name, LogLevel, Formatter) ->
    gen_server:call(?MODULE, {start_logger, Name, LogLevel, Formatter}).

stop_logger(Name) ->
    gen_server:call(?MODULE, {stop_logger, Name}).

add_sink(LoggerName, SinkName) ->
    add_sink(LoggerName, SinkName, debug).

add_sink(LoggerName, SinkName, LogLevel) ->
    gen_server:call(?MODULE, {add_sink, LoggerName, SinkName, LogLevel}).

set_loglevel(LoggerName, LogLevel) ->
    gen_server:call(?MODULE, {set_loglevel, LoggerName, LogLevel}).

get_loglevel(LoggerName) ->
    gen_server:call(?MODULE, {get_loglevel, LoggerName}).

set_sink_loglevel(LoggerName, SinkName, LogLevel) ->
    gen_server:call(?MODULE,
                    {set_sink_loglevel, LoggerName, SinkName, LogLevel}).

get_sink_loglevel(LoggerName, SinkName) ->
    gen_server:call(?MODULE, {get_sink_loglevel, LoggerName, SinkName}).

sync_sink(SinkName) ->
    try
        gen_server:call(ale_utils:sink_id(SinkName), sync, infinity)
    catch
        exit:{noproc, _} ->
            {error, unknown_sink}
    end.

sync_all_sinks() ->
    Sinks = gen_server:call(?MODULE, get_sink_names, infinity),
    [sync_sink(SinkName) || SinkName <- Sinks],
    ok.

get_effective_loglevel(LoggerName) ->
    call_logger_impl(LoggerName, get_effective_loglevel, []).

is_loglevel_enabled(LoggerName, LogLevel) ->
    call_logger_impl(LoggerName, is_loglevel_enabled, [LogLevel]).


debug(LoggerName, Msg) ->
    xdebug(LoggerName, undefined, Msg, []).

debug(LoggerName, Fmt, Args) ->
    xdebug(LoggerName, undefined, Fmt, Args).

xdebug(LoggerName, Data, Fmt, Args) ->
    xdebug(LoggerName, {unknown, unknown, -1}, Data, Fmt, Args).

xdebug(LoggerName, {M, F, L}, Data, Fmt, Args) ->
    call_logger_impl(LoggerName, xdebug, [M, F, L, Data, Fmt, Args]).


info(LoggerName, Msg) ->
    xinfo(LoggerName, undefined, Msg, []).

info(LoggerName, Fmt, Args) ->
    xinfo(LoggerName, undefined, Fmt, Args).

xinfo(LoggerName, Data, Fmt, Args) ->
    xinfo(LoggerName, {unknown, unknown, -1}, Data, Fmt, Args).

xinfo(LoggerName, {M, F, L}, Data, Fmt, Args) ->
    call_logger_impl(LoggerName, xinfo, [M, F, L, Data, Fmt, Args]).


warn(LoggerName, Msg) ->
    xwarn(LoggerName, undefined, Msg, []).

warn(LoggerName, Fmt, Args) ->
    xwarn(LoggerName, undefined, Fmt, Args).

xwarn(LoggerName, Data, Fmt, Args) ->
    xwarn(LoggerName, {unknown, unknown, -1}, Data, Fmt, Args).

xwarn(LoggerName, {M, F, L}, Data, Fmt, Args) ->
    call_logger_impl(LoggerName, xwarn, [M, F, L, Data, Fmt, Args]).


error(LoggerName, Msg) ->
    xerror(LoggerName, undefined, Msg, []).

error(LoggerName, Fmt, Args) ->
    xerror(LoggerName, undefined, Fmt, Args).

xerror(LoggerName, Data, Fmt, Args) ->
    xerror(LoggerName, {unknown, unknown, -1}, Data, Fmt, Args).

xerror(LoggerName, {M, F, L}, Data, Fmt, Args) ->
    call_logger_impl(LoggerName, xerror, [M, F, L, Data, Fmt, Args]).


critical(LoggerName, Msg) ->
    xcritical(LoggerName, undefined, Msg, []).

critical(LoggerName, Fmt, Args) ->
    xcritical(LoggerName, undefined, Fmt, Args).

xcritical(LoggerName, Data, Fmt, Args) ->
    xcritical(LoggerName, {unknown, unknown, -1}, Data, Fmt, Args).

xcritical(LoggerName, {M, F, L}, Data, Fmt, Args) ->
    call_logger_impl(LoggerName, xcritical, [M, F, L, Data, Fmt, Args]).


sync(LoggerName) ->
    call_logger_impl(LoggerName, sync, []).

capture_logging_diagnostics() ->
    #state{sinks = Sinks, loggers = Loggers} = gen_server:call(?MODULE, get_state),
    LoggersD = [{N,
                 [{loglevel, L},
                  {formatter, F},
                  {sinks, [{SN, SL}
                           || {_, #sink{name = SN, loglevel = SL}} <- dict:to_list(LSinks)]}]}
                || {_, #logger{name = N,
                               loglevel = L,
                               sinks = LSinks,
                               formatter = F}} <- dict:to_list(Loggers)],
    [{sinks, dict:to_list(Sinks)},
     {loggers, LoggersD}].

%% Callbacks
init([]) ->
    State = #state{sinks=dict:new(),
                   loggers=dict:new()},

    {ok, State1} = do_start_logger(?ERROR_LOGGER,
                                   ?DEFAULT_LOGLEVEL, ?DEFAULT_FORMATTER, State),
    {ok, State2} = do_start_logger(?ALE_LOGGER,
                                   ?DEFAULT_LOGLEVEL, ?DEFAULT_FORMATTER, State1),

    set_error_logger_handler(),

    {ok, State2}.

handle_call(get_state, _From, State) ->
    {reply, State, State};

handle_call({start_sink, Name, SinkMeta, Module, Args}, _From, State) ->
    RV = do_start_sink(Name, SinkMeta, Module, Args, State),
    handle_result(RV, State);

handle_call({stop_sink, Name}, _From, State) ->
    RV = do_stop_sink(Name, State),
    handle_result(RV, State);

handle_call({start_logger, Name, LogLevel, Formatter}, _From, State) ->
    RV = do_start_logger(Name, LogLevel, Formatter, State),
    handle_result(RV, State);

handle_call({stop_logger, Name}, _From, State) ->
    RV = do_stop_logger(Name, State),
    handle_result(RV, State);

handle_call({add_sink, LoggerName, SinkName, LogLevel},
            _From, State) ->
    RV = do_add_sink(LoggerName, SinkName, LogLevel, State),
    handle_result(RV, State);

handle_call({set_loglevel, LoggerName, LogLevel}, _From, State) ->
    RV = do_set_loglevel(LoggerName, LogLevel, State),
    handle_result(RV, State);

handle_call({get_loglevel, LoggerName}, _From, State) ->
    RV = do_get_loglevel(LoggerName, State),
    handle_result(RV, State);

handle_call({set_sink_loglevel, LoggerName, SinkName, LogLevel},
            _From, State) ->
    RV = do_set_sink_loglevel(LoggerName, SinkName, LogLevel, State),
    handle_result(RV, State);

handle_call({get_sink_loglevel, LoggerName, SinkName}, _From, State) ->
    RV = do_get_sink_loglevel(LoggerName, SinkName, State),
    handle_result(RV, State);

handle_call(get_sink_names, _From, State) ->
    {reply, dict:fetch_keys(State#state.sinks), State};

handle_call(freeze_compilations, _From, State) ->
    {reply, State#state.compile_frozen, State#state{compile_frozen = true}};

handle_call(thaw_compilations, _From, State) ->
    case State#state.compile_frozen of
        false ->
            {reply, ok, State};
        true ->
            [just_compile_logger(State, Logger)
             || {_, Logger} <- dict:to_list(State#state.loggers)],
            {reply, ok, State#state{compile_frozen = false}}
    end;

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'gen_event_EXIT', ale_error_logger_handler, Reason}, State)
  when Reason =/= normal,
       Reason =/= shutdown ->
    ale:error(?ALE_LOGGER,
              "ale_reports_handler terminated with reason ~p; restarting",
              [Reason]),

    set_error_logger_handler(),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

ensure_sink(SinkName, #state{sinks=Sinks} = _State, Fn) ->
    case dict:find(SinkName, Sinks) of
        {ok, _} ->
            Fn();
        error ->
            {error, unknown_sink}
    end.

ensure_logger(LoggerName, #state{loggers=Loggers} = _State, Fn) ->
    case dict:find(LoggerName, Loggers) of
        {ok, Logger} ->
            Fn(Logger);
        error ->
            {error, unknown_logger}
    end.

handle_result(Result, OldState) ->
    case Result of
        {ok, NewState} ->
            {reply, ok, NewState};
        {{ok, RV}, NewState} ->
            {reply, {ok, RV}, NewState};
        _Other ->
            {reply, Result, OldState}
    end.

do_start_sink(Name, SinkMeta, Module, Args, #state{sinks=Sinks} = State) ->
    case dict:find(Name, Sinks) of
        {ok, _} ->
            {error, duplicate_sink};
        error ->
            SinkId = ale_utils:sink_id(Name),
            Args1 = [SinkId | Args],

            RV = ale_dynamic_sup:start_child(SinkId, Module, Args1),
            case RV of
                {ok, _} ->
                    NewSinks = dict:store(Name, SinkMeta, Sinks),
                    NewState = State#state{sinks=NewSinks},
                    {ok, NewState};
                _Other ->
                    RV
            end
    end.

do_stop_sink(Name, #state{sinks=Sinks} = State) ->
    ensure_sink(
      Name, State,
      fun () ->
              SinkId = ale_utils:sink_id(Name),
              ok = ale_dynamic_sup:stop_child(SinkId),
              NewSinks = dict:erase(Name, Sinks),
              NewState = State#state{sinks=NewSinks},
              {ok, NewState}
      end).

do_start_logger(Name, LogLevel, Formatter, State) ->
    case is_valid_loglevel(LogLevel) of
        true ->
            do_start_logger_tail(Name, LogLevel, Formatter, State);
        false ->
            {error, badarg}
    end.

do_start_logger_tail(Name, LogLevel, Formatter,
                     #state{loggers=Loggers} = State) ->
    case dict:find(Name, Loggers) of
        {ok, _Logger} ->
            {error, duplicate_logger};
        error ->
            Logger = #logger{name=Name,
                             loglevel=LogLevel,
                             sinks=dict:new(),
                             formatter=Formatter},

            {ok, compile(State, Logger)}
    end.

do_stop_logger(Name, #state{loggers=Loggers} = State) ->
    ensure_logger(
      Name, State,
      fun (_Logger) ->
              NewLoggers = dict:erase(Name, Loggers),
              State1 = State#state{loggers=NewLoggers},
              {ok, State1}
      end).

do_add_sink(LoggerName, SinkName, LogLevel, State) ->
    case is_valid_loglevel(LogLevel) of
        true ->
            do_add_sink_tail(LoggerName, SinkName, LogLevel, State);
        false ->
            {error, badarg}
    end.

do_add_sink_tail(LoggerName, SinkName, LogLevel, State) ->
    ensure_logger(
      LoggerName, State,
      fun (#logger{sinks=Sinks} = Logger) ->
              ensure_sink(
                SinkName, State,
                fun () ->
                        Sink = #sink{name=SinkName,
                                     loglevel=LogLevel},

                        NewSinks = dict:store(SinkName, Sink, Sinks),
                        NewLogger = Logger#logger{sinks=NewSinks},
                        NewState = compile(State, NewLogger),

                        {ok, NewState}
                end)
      end).

do_set_loglevel(LoggerName, LogLevel, State) ->
    case is_valid_loglevel(LogLevel) of
        true ->
            do_set_loglevel_tail(LoggerName, LogLevel, State);
        false ->
            {error, badarg}
    end.

do_set_loglevel_tail(LoggerName, LogLevel, State) ->
    ensure_logger(
      LoggerName, State,
      fun (#logger{loglevel=CurrentLogLevel} = Logger) ->
              case LogLevel of
                  CurrentLogLevel ->
                      {ok, State};
                  _ ->
                      NewLogger = Logger#logger{loglevel=LogLevel},
                      NewState = compile(State, NewLogger),

                      {ok, NewState}
              end
      end).

do_get_loglevel(LoggerName, State) ->
    ensure_logger(
      LoggerName, State,
      fun (#logger{loglevel=LogLevel}) ->
              {{ok, LogLevel}, State}
      end).

do_set_sink_loglevel(LoggerName, SinkName, LogLevel, State) ->
    case is_valid_loglevel(LogLevel) of
        true ->
            do_set_sink_loglevel_tail(LoggerName, SinkName, LogLevel, State);
        false ->
            {error, badarg}
    end.

do_set_sink_loglevel_tail(LoggerName, SinkName, LogLevel, State) ->
    ensure_logger(
      LoggerName, State,
      fun (#logger{sinks=Sinks} = Logger) ->
              ensure_sink(
                SinkName, State,
                fun () ->
                        case dict:find(SinkName, Sinks) of
                            {ok, #sink{loglevel=LogLevel}} ->   % bound above
                                {ok, State};
                            {ok, Sink} ->
                                NewSink = Sink#sink{loglevel=LogLevel},

                                NewSinks = dict:store(SinkName, NewSink, Sinks),
                                NewLogger = Logger#logger{sinks=NewSinks},
                                NewState = compile(State, NewLogger),
                                {ok, NewState};
                            error ->
                                {error, bad_sink}
                        end
                end)
      end).

do_get_sink_loglevel(LoggerName, SinkName, State) ->
    ensure_logger(
      LoggerName, State,
      fun (#logger{sinks=Sinks}) ->
              ensure_sink(
                SinkName, State,
                fun () ->
                        case dict:find(SinkName, Sinks) of
                            {ok, #sink{loglevel=LogLevel}} ->
                                LogLevel;
                            error ->
                                {error, bad_sink}
                        end
                end)
      end).

set_error_logger_handler() ->
    error_logger:swap_handler(silent),
    ok = gen_event:add_sup_handler(error_logger, ale_error_logger_handler,
                                   [?ERROR_LOGGER]).

compile(#state{compile_frozen = Frozen,
               loggers=Loggers} = State,
        #logger{name=LoggerName} = Logger) ->

    case Frozen of
        false ->
            just_compile_logger(State, Logger);
        _ ->
            ok
    end,

    NewLoggers = dict:store(LoggerName, Logger, Loggers),
    State#state{loggers=NewLoggers}.

just_compile_logger(#state{sinks=SinkMetas} = _State,
                    #logger{name=LoggerName,
                            loglevel=LogLevel,
                            formatter=Formatter,
                            sinks=Sinks} = _Logger) ->
    SinksList =
        dict:fold(
          fun (SinkName,
               #sink{name=SinkName, loglevel=SinkLogLevel},
               Acc) ->
                  SinkId = ale_utils:sink_id(SinkName),
                  {ok, SinkMeta} = dict:find(SinkName, SinkMetas),
                  [{SinkName, SinkId, SinkLogLevel, SinkMeta} | Acc]
          end, [], Sinks),

    ok = ale_codegen:load_logger(LoggerName, LogLevel, Formatter, SinksList).

is_valid_loglevel(LogLevel) ->
    lists:member(LogLevel, ?LOGLEVELS).

-compile({inline, [call_logger_impl/3]}).
call_logger_impl(LoggerName, F, Args) ->
    Module = ale_codegen:logger_impl(LoggerName),
    try
        erlang:apply(Module, F, Args)
    catch
        error:undef ->
            throw(unknown_logger)
    end.
