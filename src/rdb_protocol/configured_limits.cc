#include "rdb_protocol/configured_limits.hpp"
#include <limits>
#include "rdb_protocol/wire_func.hpp"
#include "rdb_protocol/func.hpp"

namespace ql {

configured_limits_t from_optargs(
    rdb_context_t *ctx, signal_t *interruptor, global_optargs_t *arguments) {
    size_t changefeed_queue_size = configured_limits_t::default_changefeed_queue_size;
    size_t array_size_limit = configured_limits_t::default_array_size_limit;
    // Fake an environment with no arguments.  We have to fake it
    // because of a chicken/egg problem; this function gets called
    // before there are any extant environments at all.  Only
    // because we use an empty argument list do we prevent an
    // infinite loop.
    // TODO: there's a `env_t(interruptor, reql_version)` constructor,
    // should this be using that?
    env_t env(ctx,
              return_empty_normal_batches_t::NO,
              interruptor,
              std::map<std::string, wire_func_t>(),
              nullptr);
    if (arguments->has_optarg("changefeed_queue_size")) {
        int64_t sz = arguments->get_optarg(&env, "changefeed_queue_size")->as_int();
        rcheck_datum(sz > 1, base_exc_t::LOGIC,
                     strprintf("Illegal changefeed queue size `%" PRIi64 "`.", sz));
        changefeed_queue_size = sz;
    }
    if (arguments->has_optarg("array_limit")) {
        int64_t limit = arguments->get_optarg(&env, "array_limit")->as_int();
        rcheck_datum(limit > 1, base_exc_t::LOGIC,
                     strprintf("Illegal array size limit `%" PRIi64 "`.", limit));
        array_size_limit = limit;
    }
    return configured_limits_t(changefeed_queue_size, array_size_limit);
}

RDB_IMPL_SERIALIZABLE_2(configured_limits_t, changefeed_queue_size_, array_size_limit_);
INSTANTIATE_SERIALIZABLE_FOR_CLUSTER(configured_limits_t);

const configured_limits_t configured_limits_t::unlimited(
    std::numeric_limits<size_t>::max(),
    std::numeric_limits<size_t>::max());

} // namespace ql
