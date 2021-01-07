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

"""
    MissingInputError(k)

Indicates that a required input was not provided.
The input's name is stored in `k`.
"""
struct MissingInputError <: Exception
    k::String
end

Base.showerror(io::IO, e::MissingInputError) =
    print(io, "Input required and not supplied: $(e.k)")

cmd_value(::Nothing) = ""
cmd_value(s::AbstractString) = s
cmd_value(x) = json(x)

function esc_data(val)
    s = cmd_value(val)
    s = replace(s, '%' => "%25")
    s = replace(s, '\r' => "%0D")
    s = replace(s, '\n' => "%0A")
    return s
end

function esc_prop(val)
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

fail() = exit(1)

add_to_file(k, v) = open(f -> println(f, v), ENV[k], "a")

"""
    end_group()

End a group that was started with [`start_group`](@ref).
"""
end_group() = command("endgroup", (), "")

"""
    get_state(k)

Get the state variable with name `k`.
"""
get_state(k) = get(ENV, "STATE_$k", "")

"""
    log_debug(msg)

Log a debug message.
See also [`GitHubActionsLogger`](@ref).
"""
log_debug(msg) = command("debug", (), msg)

"""
    log_error(msg)

Log an error message.
See also [`GitHubActionsLogger`](@ref).
"""
log_error(msg) = command("error", (), msg)

"""
    log_warning(msg)

Log a warning message.
See also [`GitHubActionsLogger`](@ref).
"""
log_warning(msg) = command("warning", (), msg)

"""
    save_state(k, v)

Save value `v` with name `k` to state.
"""
save_state(k, v) = command("save-state", (name=k,), v)

"""
    set_command_echo(enable)

Enable or disable command echoing.
"""
set_command_echo(enable) = command("echo", (), enable ? "on" : "off")

"""
    set_output(k, v)

Set the output with name `k` to value `v`.
"""
set_output(k, v) = command("set-output", (name=k,), v)

"""
    set_secret(v)

Mask the value `v` in logs.
"""
set_secret(v) = command("add-mask", (), v)

"""
    start_group(name)

Start a foldable group called `name`.
"""
start_group(name) = command("group", (), name)

"""
    add_path(v)

Add `v` to the system `PATH`.
"""
function add_path(v)
    sep = @static Sys.iswindows() ? ';' : ':'
    ENV["PATH"] = v * sep * ENV["PATH"]
    add_to_file("GITHUB_PATH", v)
end

"""
    get_input(k; required=false)

Get an input.
If `required` is set and the input is not, a [`MissingInputError`](@ref) is thrown.
"""
function get_input(k; required=false)
    val = get(ENV, "INPUT_" * uppercase(replace(k, ' ' => '_')), "")
    required && isempty(val) && throw(MissingInputError(k))
    return string(strip(val))
end

"""
    group(f, name)

Run `f` inside of a foldable group.
See also [`start_group`](@ref) and [`end_group`](@ref).
"""
function group(f, name)
    start_group(name)
    return try f() finally end_group() end
end

"""
    set_env(k, v)

Set environment variable `k` to value `v`.
"""
function set_env(k, v)
    val = cmd_value(v)
    ENV[k] = val
    delimiter = "EOF"
    while occursin(delimiter, val)
        delimiter *= "EOF"
    end
    add_to_file("GITHUB_ENV", join(["$k<<$delimiter", val, delimiter], "\n"))
end

"""
    set_failed(msg)

Error with `msg`, and set the process exit code to `1`.
"""
function set_failed(msg)
    atexit(fail)
    log_error(msg)
end

"""
    GitHubActionsLogger()

A logger that prints to standard output in the format expected by GitHub Actions.
"""
struct GitHubActionsLogger <: AbstractLogger end

Logging.catch_exceptions(::GitHubActionsLogger) = true
Logging.min_enabled_level(::GitHubActionsLogger) = Debug
Logging.shouldlog(::GitHubActionsLogger, args...) = true

function Logging.handle_message(
    ::GitHubActionsLogger,
    level, msg, _module, group, id, file, line;
    location=nothing, kwargs...,
)
    file, line = something(location, (file, line))
    message = string(msg)
    for (k, v) in kwargs
        result = sprint(Logging.showvalue, v)
        message *= "\n  $k = " * if occursin('\n', result)
            replace("\n" * result, '\n' => "\n    ")
        else
            result
        end
    end
    if level === Info
        println(message)
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
