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
    isfork()

Returns true if the repository is a fork
"""
function isfork()
    # TODO check if it returns "" or nothing
    GITHUB_HEAD_REF = get(ENV, "GITHUB_HEAD_REF", nothing)
    return !(GITHUB_HEAD_REF == "" || GITHUB_HEAD_REF === nothing)
end

"""
    REV = get_rev(rev_env_name = "REV")

This function returns the git revision.
It also sets an ENV variable REV by default.
"""
function get_rev(env_name = "REV")
    if !isfork()
        GITHUB_REF = ENV["GITHUB_REF"]
        REV = replace(GITHUB_REF, "refs/heads/"=>"")
    else
        GITHUB_HEAD_REF = ENV["GITHUB_HEAD_REF"]
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
Returns the name of the repository. See [`get_owner_and_name`](@ref)
"""
get_owner() = get_owner_and_name()[1]

"""
Returns the main owner of the repository. See [`get_owner_and_name`](@ref)
"""
get_name() = get_owner_and_name()[2]


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
