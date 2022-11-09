using Logging: with_logger
using UUIDs: UUID, uuid4
using Test: @test, @testset, @test_throws

using GitHubActions
using SimpleMock: called_once_with, mock, Mock
using Suppressor: @capture_out

const GHA = GitHubActions

@testset "GitHubActions.jl" begin
    @test (@capture_out GHA.command("a", (), "")) == "::a::\n"
    @test (@capture_out GHA.command("a", (), nothing)) == "::a::\n"
    @test (@capture_out GHA.command("a", (), "bar")) == "::a::bar\n"
    @test (@capture_out GHA.command("a", (), ())) == "::a::[]\n"
    @test (@capture_out GHA.command("a", (b=1,), "")) == "::a b=1::\n"
    @test (@capture_out GHA.command("a", (b=1, c=2), "")) == "::a b=1,c=2::\n"
    @test (@capture_out GHA.command("a", (b="c%d\re\nf",), "")) == "::a b=c%25d%0De%0Af::\n"
    @test (@capture_out GHA.command("a", (), "a%b\rc\nd:e,f")) == "::a::a%25b%0Dc%0Ad:e,f\n"

    @test (@capture_out end_group()) == "::endgroup::\n"

    withenv(() -> (@test get_state("a") == ""), "STATE_a" => nothing)
    withenv(() -> (@test get_state("a") == ""), "STATE_a" => "")
    withenv(() -> (@test get_state("a") == "b"), "STATE_a" => "b")

    @test (@capture_out log_debug("a")) == "::debug::a\n"
    @test (@capture_out log_error("a")) == "::error::a\n"
    @test (@capture_out log_warning("a")) == "::warning::a\n"

    @test (@capture_out save_state("a", "b")) == "::save-state name=a::b\n"

    @test (@capture_out set_command_echo(true)) == "::echo::on\n"
    @test (@capture_out set_command_echo(false)) == "::echo::off\n"

    @test (@capture_out set_output("a", "b")) == "::set-output name=a::b\n"

    @test (@capture_out set_secret("a")) == "::add-mask::a\n"

    @test (@capture_out start_group("a")) == "::group::a\n"

    mktemp() do file, io
        withenv("GITHUB_PATH" => file, "PATH" => "/bin") do
            sep = Sys.iswindows() ? ';' : ':'
            add_path("a")
            @test ENV["PATH"] == string("a", sep, "/bin")
            @test read(file, String) == "a\n"
            add_path("b")
            @test ENV["PATH"] == string("b", sep, "a", sep, "/bin")
            @test read(file, String) == "a\nb\n"
        end
    end

    withenv(() -> (@test get_input("A") == ""), "INPUT_A" => "")
    withenv(() -> (@test get_input("A") == ""), "INPUT_A" => nothing)
    withenv(() -> (@test get_input("A") == "b"), "INPUT_A" => "b")
    withenv(() -> (@test get_input("a") == "b"), "INPUT_A" => "b")
    withenv(() -> (@test get_input("a b") == "c"), "INPUT_A_B" => "c")
    withenv(() -> (@test_throws GHA.MissingInputError get_input("a"; required=true)), "INPUT_A" => "")
    withenv(() -> (@test_throws GHA.MissingInputError get_input("a"; required=true)), "INPUT_A" => nothing)

    @test (@capture_out group(() -> println("!"), "a")) == "::group::a\n!\n::endgroup::\n"

    mktemp() do file, io
        uuid = UUID("9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d")
        delimiter = "ghadelimiter_$uuid"
        mock((uuid4) => Mock(uuid)) do _
            withenv("GITHUB_ENV" => file, map(c -> string(c) => nothing, 'a':'z')...) do
                set_env("a", "b")
                @test ENV["a"] == "b"
                @test read(file, String) == "a<<$delimiter\nb\n$delimiter\n"

                mock(set_failed) do ae
                    set_env("b", "foo$(delimiter)bar")
                    @test called_once_with(ae, "value of environment variable must not contain the delimiter $delimiter")
                end

                mock(set_failed) do ae
                    set_env("b$(delimiter)", "c")
                    @test called_once_with(ae, "name of environment variable must not contain the delimiter $delimiter")
                end

                rm(file)
                set_env("c", [])
                @test ENV["c"] == "[]"
                @test read(file, String) == "c<<$delimiter\n[]\n$delimiter\n"
                set_env("d", nothing)
                @test ENV["d"] == ""
                @test read(file, String) == "c<<$delimiter\n[]\n$delimiter\nd<<$delimiter\n\n$delimiter\n"
            end
        end
    end

    if VERSION.minor < 6
        mock(atexit) do ae
            @test (@capture_out set_failed("a")) == "::error::a\n"
            @test called_once_with(ae, GHA.fail)
        end
    end

    function rx(level)
        workspace = get(ENV, "GITHUB_WORKSPACE", nothing)
        file = @__FILE__
        if workspace !== nothing
            file = relpath(file, workspace)
        end
        return Regex("^::$level file=$(file),line=\\d+::a")
    end

    with_logger(GitHubActionsLogger()) do
        @test match(rx("debug"), (@capture_out @debug "a")) !== nothing
        @test match(rx("warning"), (@capture_out @warn "a")) !== nothing
        @test match(rx("error"), (@capture_out @error "a")) !== nothing
        @test (@capture_out @info "a") == "a\n"

        @test (@capture_out @info "a" b=1 c=2 d=Text("e\nf")) == "a\n  b = 1\n  c = 2\n  d = \n    e\n    f\n"
        @test endswith((@capture_out @warn "a" b=1 c=2), "::a%0A  b = 1%0A  c = 2\n")

        expected = "::warning file=test/bar,line=1::foo\n"
        @test (@capture_out @warn "foo" location=("bar", 1)) == expected
    end
end
