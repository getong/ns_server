%% @author Couchbase <info@couchbase.com>
%% @copyright 2018 Couchbase, Inc.
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
%% @doc - This module contains the logic to reprovision a bucket when
%% the active vbuckets are found to be in "missing" state. Typically,
%% such a scenario would arise in case of ephemeral buckets when the
%% memcached process on a node restarts within the auto-failover
%% timeout.
-module(cut_tests).

-include("cut.hrl").
-include_lib("eunit/include/eunit.hrl").

foo3(F, A, B, C) ->
    F(A, B, C).

simple_params_test() ->
    ?assertEqual({1, 2, 3}, foo3({_, _, _}, 1, 2, 3)),
    ?assertEqual({1, 2, 3}, foo3(?cut({_, _, _}), 1, 2, 3)).

numbered_params_test() ->
    ?assertEqual({1, 2, 3}, foo3(?cut({_1, _2, _3}), 1, 2, 3)),
    ?assertEqual({3, 2, 1}, foo3(?cut({_3, _2, _1}), 1, 2, 3)),
    ?assertEqual({1, 2, 3, 1, 3, 2}, foo3(?cut({_1, _2, _3, _1, _3, _2}),
                                          1, 2, 3)),
    ?assertEqual({2, 3}, foo3(?cut({_2, _3}), 1, 2, 3)),
    ?assertEqual({1, 3}, foo3(?cut({_1, _3}), 1, 2, 3)),
    ?assertEqual({1, [2, 3]}, foo3(?cut({_1, [_2, _3]}), 1, 2, 3)),
    ?assertEqual({[3, 2], 1},
                 foo3(?cut({lists:reverse([_2, _3]), _1}), 1, 2, 3)).
