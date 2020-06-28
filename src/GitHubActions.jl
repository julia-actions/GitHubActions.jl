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

fail() = exit(1)

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
    command("add-path", (), v)
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
    command("set-env", (name=k,), val)
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
    ::GitHubActionsLogger, level, msg, _module, group, id, file, line; kwargs...,
)
    message = string(msg)
    for (k, v) in kwargs
        message *= "\n  $k = $v"
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

"""
    PACKAGESPEC = get_packagespec(packagespec_env_name = "PACKAGESPEC")

This function returns the repository PackageSpec as a String.
It also sets the ENV variable PACKAGESPEC by default.

# Example
In GitHubActions, you can pass this to `Pkg.develop()` by inerpolating it like this:
```julia
julia -e "using Pkg; Pkg.develop(\"\${{env.PACKAGESPEC}}\")"
```
"""
function get_packagespec(packagespec_env_name = "PACKAGESPEC")
    PACKAGESPEC = "PackageSpec(url = \"$(get_url())\", rev = \"$(get_rev())\")"
    set_env(packagespec_env_name, PACKAGESPEC)
    return PACKAGESPEC
end

"""
    REV = get_rev(rev_env_name = "REV")

This function returns the git revision.
It also sets an ENV variable REV by default.
"""
function get_rev(env_name = "REV")
    GITHUB_HEAD_REF = get(ENV, "GITHUB_HEAD_REF", nothing)
    GITHUB_REF = ENV["GITHUB_REF"]
    if GITHUB_HEAD_REF == "" || GITHUB_HEAD_REF === nothing
        REV = replace(GITHUB_REF, "refs/heads/"=>"")
    else
        REV = GITHUB_HEAD_REF
    end
    set_env(rev_env_name, REV)
    return REV
end

"""
    REPOSITORY_URL = get_url(url_env_name = "REPOSITORY_URL")

Returns the url of the repository.
It also sets the ENV variable REPOSITORY_URL by default.
"""
function get_url(url_env_name = "REPOSITORY_URL")
    # TODO find a more robust way
    REPOSITORY_URL = "https://github.com/$(get_actor())/$(get_owner_and_name()[2])"
    set_env(url_env_name, REPOSITORY_URL)
    return REPOSITORY_URL
end

"""
    REPOSITORY_OWNER, REPOSITORY_NAME = get_owner_and_name(owner_env_name = "REPOSITORY_OWNER", name_env_name = "REPOSITORY_NAME")

Returns the main owner and the name of the repository.
It also sets the ENV variables REPOSITORY_OWNER and REPOSITORY_NAME by default.
"""
function get_owner_and_name(owner_env_name = "REPOSITORY_OWNER", name_env_name = "REPOSITORY_NAME")
    GITHUB_REPOSITORY = ENV["GITHUB_REPOSITORY"]
    REPOSITORY_OWNER, REPOSITORY_NAME = split(GITHUB_REPOSITORY, '/')
    set_env(owner_env_name, REPOSITORY_OWNER)
    set_env(name_env_name, REPOSITORY_NAME)
    return REPOSITORY_OWNER, REPOSITORY_NAME
end

"""
ACTOR = get_actor(actor_env_name = "ACTOR")

Returns the actor of GitHub action.
It also sets the ENV variable ACTOR by default.
"""
function get_actor(actor_env_name = "ACTOR")
    ACTOR = ENV["GITHUB_ACTOR"]
    set_env(actor_env_name, ACTOR)
    return ACTOR
end

end
