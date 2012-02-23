-module(mud_context).
-export([ create/2, delete/1, exists/1, set_context/4, set_synched_context/4, set_map_context/3 ]).

create(Key, Data) ->
   send_command(Key, {create, Key, Data}).

delete(Key) ->
   send_command(Key, {delete, Key}).

exists(Key) ->
   send_synched_command(Key, {exists, Key}).

-spec mud_context:set_context(Key::term(), Module::atom(), 
                              Fun::atom(), Arg::term()) -> 'ok'.
set_context(Key, Module, Fun, Arg) ->
   send_command(Key, {set_context, Key, Module, Fun, Arg}).

-spec mud_context:set_synched_context(Key::term(), Module::atom(), 
                              Fun::atom(), Arg::term()) -> 'ok'.
set_synched_context(Key, Module, Fun, Arg) ->
   send_synched_command(Key, {set_synched_context, Key, Module, Fun, Arg}).

set_map_context(Module, Fun, Arg) ->
   send_map({set_map_context, Module, Fun, Arg}).


-spec mud_context:send_command(Key::term(), Command::term()) -> 'ok'.
send_command(Key, Command) ->
   CKey = chash:key_of(term_to_binary(Key)),
   NVal = 1,
   [Pref] = riak_core_apl:get_apl(CKey, NVal, mud_context),
   riak_core_vnode_master:command(Pref, Command, mud_context_vnode_master),
   ok.


-spec mud_context:send_synched_command(Key::term(), Command::term()) -> 'ok'.
send_synched_command(Key, Command) ->
   CKey = chash:key_of(term_to_binary(Key)),
   NVal = 1,
   [Pref] = riak_core_apl:get_apl(CKey, NVal, mud_context),
   riak_core_vnode_master:sync_command(Pref, Command, mud_context_vnode_master, infinity).

send_map(Command) ->
   mud_context_map_fsm_sup:start_map_fsm(node(), [{raw, mk_reqid(), self()}, [Command, 10000, plain]]).

mk_reqid() -> erlang:phash2(erlang:now()).
   
