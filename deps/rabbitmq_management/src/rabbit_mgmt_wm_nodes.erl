%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Console.
%%
%%   The Initial Developer of the Original Code is GoPivotal, Inc.
%%   Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.
%%

-module(rabbit_mgmt_wm_nodes).

-export([init/1, to_json/2, content_types_provided/2, is_authorized/2]).
-export([all_nodes/1, all_nodes_raw/0]).
-export([encodings_provided/2]).

-include("rabbit_mgmt.hrl").
-include_lib("webmachine/include/webmachine.hrl").
-include_lib("rabbit_common/include/rabbit.hrl").

%%--------------------------------------------------------------------

init(_Config) -> {ok, #context{}}.

content_types_provided(ReqData, Context) ->
   {[{"application/json", to_json}], ReqData, Context}.

encodings_provided(ReqData, Context) ->
    {[{"identity", fun(X) -> X end},
     {"gzip", fun(X) -> zlib:gzip(X) end}], ReqData, Context}.

to_json(ReqData, Context) ->
    try
        rabbit_mgmt_util:reply_list(all_nodes(ReqData), ReqData, Context)
    catch
        {error, invalid_range_parameters, Reason} ->
            rabbit_mgmt_util:bad_request(iolist_to_binary(Reason), ReqData, Context)
    end.

is_authorized(ReqData, Context) ->
    rabbit_mgmt_util:is_authorized_monitor(ReqData, Context).

%%--------------------------------------------------------------------

all_nodes(ReqData) ->
    rabbit_mgmt_db:augment_nodes(
      all_nodes_raw(), rabbit_mgmt_util:range_ceil(ReqData)).

all_nodes_raw() ->
    S = rabbit_mnesia:status(),
    Nodes = proplists:get_value(nodes, S),
    Types = proplists:get_keys(Nodes),
    Running = proplists:get_value(running_nodes, S),
    [[{name, Node}, {type, Type}, {running, lists:member(Node, Running)}] ||
        Type <- Types, Node <- proplists:get_value(Type, Nodes)].
