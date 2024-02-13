local M = {
    trace = function(msg) print(msg) end,
    debug = function(msg) print(msg) end,
    info = function(msg) print(msg) end,
    warn = function(msg) print(msg) end,
    error = function(msg) print(msg) end,
    fatal = function(msg) print(msg) end
}

M.configure = function(logger)
    M.trace = logger.trace
    M.debug = logger.debug
    M.info = logger.info
    M.warn = logger.warn
    M.error = logger.error
    M.fatal = logger.fatal
end

return M
