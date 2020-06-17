using GitHubActions
using SimpleMock: called_once_with, mock
using Suppressor: @capture_out
using Test: @test, @testset, @test_throws

const GHA = GitHubActions

@testset "GitHubActions.jl" begin
    @test (@capture_out GHA.command("a", (), "")) == "::a::\n"
    @test (@capture_out GHA.command("a", (), nothing)) == "::a::\n"
    @test (@capture_out GHA.command("a", (), "bar")) == "::a::bar\n"
    @test (@capture_out GHA.command("a", (), ())) == "::a::[]\n"
    @test (@capture_out GHA.command("a", (b=1,), "")) == "::a b=1::\n"
    @test (@capture_out GHA.command("a", (b=1, c=2), "")) == "::a b=1,c=2::\n"
    @test (@capture_out GHA.command("a", (b="c%d\re\nf",), "")) == "::a b=c%25d%0De%0Af::\n"
    @test (@capture_out GHA.command("a", (), "a%b\rc\nd:e,f")) == "::a::a%25b%0Dc%0Ad%3Ae%2Cf\n"

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

    withenv("PATH" => "/bin") do
        @test (@capture_out add_path("a")) == "::add-path::a\n"
        sep = Sys.iswindows() ? ';' : ':'
        @test ENV["PATH"] == "a$sep/bin"
    end

    withenv(() -> (@test get_input("A") == ""), "INPUT_A" => "")
    withenv(() -> (@test get_input("A") == ""), "INPUT_A" => nothing)
    withenv(() -> (@test get_input("A") == "b"), "INPUT_A" => "b")
    withenv(() -> (@test get_input("a") == "b"), "INPUT_A" => "b")
    withenv(() -> (@test get_input("a b") == "c"), "INPUT_A_B" => "c")
    withenv(() -> (@test_throws GHA.MissingInputError get_input("a"; required=true)), "INPUT_A" => "")
    withenv(() -> (@test_throws GHA.MissingInputError get_input("a"; required=true)), "INPUT_A" => nothing)

    @test (@capture_out group(() -> println("!"), "a")) == "::group::a\n!\n::endgroup::\n"

    withenv("a" => nothing) do
        @test (@capture_out set_env("a", "b")) == "::set-env name=a::b\n"
        @test ENV["a"] == "b"
        @test (@capture_out set_env("a", ())) == "::set-env name=a::[]\n"
        @test ENV["a"] == "[]"
    end

    mock(atexit) do ae
        @test (@capture_out set_failed("a")) == "::error::a\n"
        @test called_once_with(ae, GHA.fail)
    end
end
