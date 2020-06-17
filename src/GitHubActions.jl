module GitHubActions

export
    GitHubActionsLogger,
    add_path,
    end_group,
    get_input,
    get_state,
    group,
    log_debug,
    log_error,
    log_warning,
    save_state,
    set_command_echo,
    set_env,
    set_failed,
    set_output,
    set_secret,
    start_group

using Logging: Logging, AbstractLogger, Debug, Info, Warn, Error

using JSON: json

const CMD_MARKER = "::"

struct MissingInputError <: Exception
    k::String
end

Base.showerror(io::IO, e::MissingInputError) =
    print(io, "Input required and not supplied: $(e.k)")

cmd_value(::Nothing) = ""
cmd_value(s::AbstractString) = s
cmd_value(x) = json(x)

function esc_prop(val)
    s = cmd_value(val)
    s = replace(s, '%' => "%25")
    s = replace(s, '\r' => "%0D")
    s = replace(s, '\n' => "%0A")
    return s
end

function esc_data(val)
    s = cmd_value(val)
    s = replace(s, '%' => "%25")
    s = replace(s, '\r' => "%0D")
    s = replace(s, '\n' => "%0A")
    s = replace(s, ':' => "%3A")
    s = replace(s, ',' => "%2C")
    return s
end

format_props(props) =
    join(map(p -> string(p.first, "=", esc_prop(p.second)), collect(pairs(props))), ',')

function command(cmd, props, val)
    s = CMD_MARKER * cmd
    isempty(props) || (s *= ' ' * format_props(props))
    s *= CMD_MARKER * esc_data(val)
    println(s)
end

end_group() = command("endgroup", (), "")
get_state(k) = get(ENV, "STATE_$k", "")
log_debug(msg) = command("debug", (), msg)
log_error(msg) = command("error", (), msg)
log_warning(msg) = command("warning", (), msg)
save_state(k, v) = command("save-state", (name=k,), v)
set_command_echo(enable) = command("echo", (), enable ? "on" : "off")
set_output(k, v) = command("set-output", (name=k,), v)
set_secret(k) = command("add-mask", (), k)
start_group(name) = command("group", (), name)

function add_path(v)
    sep = @static Sys.iswindows() ? ';' : ':'
    ENV["PATH"] = v * sep * ENV["PATH"]
    command("add-path", (), v)
end

function get_input(k; required=false)
    val = get(ENV, "INPUT_" * uppercase(replace(k, ' ' => '_')), "")
    required && isempty(val) && throw(MissingInputError(k))
    return string(strip(val))
end

function group(f, name)
    start_group(name)
    return try f() finally end_group() end
end

function set_env(k, v)
    val = cmd_value(v)
    ENV[k] = val
    command("set-env", (name=k,), val)
end

fail() = exit(1)
function set_failed(msg)
    atexit(fail)
    log_error(msg)
end

struct GitHubActionsLogger <: AbstractLogger end

Logging.shouldlog(::GitHubActionsLogger, args...) = true

Logging.min_enabled_level(::GitHubActionsLogger) =
    get(ENV, "RUNNER_DEBUG", "") == "1" ? Debug : Info

Logging.catch_exceptions(::GitHubActionsLogger) = false

function Logging.handle_message(
    ::GitHubActionsLogger, level, msg, _module, group, id, file, line; kwargs...,
)
    message = string(msg)
    for (k, v) in kwargs
        message *= "\n  $k=$v"
    end
    if level === Info
        if isempty(kwargs)
            println(message)
        else
            group(() -> println(message), "info")
        end
    else
        cmd = if level === Debug
            "debug"
        elseif level === Warn
            "warning"
        elseif level === Error
            "error"
        end
        command(cmd, (file=file, line=line), message)
    end
end

end
