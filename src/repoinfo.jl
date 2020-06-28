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

Returns true if the running job is in a fork
"""
function isfork()
    # TODO check if it returns "" or nothing
    GITHUB_HEAD_REF = get(ENV, "GITHUB_HEAD_REF", nothing)
    return !(GITHUB_HEAD_REF == "" || GITHUB_HEAD_REF === nothing)
end


"""
    ispullrequest()

Returns true if the running job is in a pull request
"""
function ispullrequest()
    # TODO find a more robust way
    owner = get_owner_and_name()[1]
    actor = get_actor()
    return owner != actor
end

"""
    rev = get_rev()

This function returns the git revision.
"""
function get_rev()
    if !isfork()
        GITHUB_REF = ENV["GITHUB_REF"]
        rev = replace(GITHUB_REF, "refs/heads/"=>"")
    else
        GITHUB_HEAD_REF = ENV["GITHUB_HEAD_REF"]
        rev = GITHUB_HEAD_REF
    end
    return rev
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
    repository_owner, repository_name = get_owner_and_name()

Returns the main owner and the name of the repository.
"""
function get_owner_and_name()
    GITHUB_REPOSITORY = ENV["GITHUB_REPOSITORY"]
    repository_owner, repository_name = split(GITHUB_REPOSITORY, '/')
    return repository_owner, repository_name
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
actor = get_actor(actor_env_name = "actor")

Returns the actor of GitHub action.
"""
function get_actor()
    actor = ENV["GITHUB_ACTOR"]
    return actor
end
