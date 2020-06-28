"""
    event_repository()
Repository information as a Dict
"""
event_repository() = EVENT["repository"]

"""
    event_repository_name()
output is like: `"GitHubActions.jl"`
"""
event_repository_name() = event_repository()["name"]

"""
    event_repository_full_name()
output is like: `"aminya/GitHubActions.jl"`
"""
event_repository_full_name() = event_repository()["full_name"]

"""
    event_repository_html_url()
HTML url as String like `"https://github.com/aminya/GitHubActions.jl"`
"""
event_repository_html_url() = event_repository()["html_url"]

"""
    event_repository_git_url()
git url as String like `"git://github.com/aminya/GitHubActions.jl.git"`
"""
event_repository_git_url() = event_repository()["git_url"]

"""
    event_repository_ssh_url()
ssh url as String like `"git@github.com:aminya/GitHubActions.jl.git"`
"""
event_repository_ssh_url() = event_repository()["ssh_url"]

"""
    package_spec = event_packagespec(packagespec_env_name = "PACKAGESPEC")

This function returns the repository PackageSpec.

It also sets the ENV variable PACKAGESPEC as a String.
# Example
In GitHubActions, you can pass this to `Pkg.develop()` by inerpolating it like this:
```julia
julia -e "using Pkg; Pkg.develop(\"\${{env.PACKAGESPEC}}\")"
```
"""
function event_packagespec(packagespec_env_name = "PACKAGESPEC")
    url = event_repository_html_url()
    rev = event_rev()
    package_spec = PackageSpec(url = url, rev = rev)
    PACKAGESPEC = "PackageSpec(url = \"$url\", rev = \"$rev\")"
    set_env(packagespec_env_name, PACKAGESPEC)
    return package_spec
end

"""
    event_isfork()

Returns true if the running job is in a fork
"""
event_isfork() = event_repository()["fork"]

"""
    rev = event_rev()

This function returns the git revision.
"""
function event_rev()
    if !event_isfork()
        GITHUB_REF = ENV["GITHUB_REF"]
        rev = replace(GITHUB_REF, "refs/heads/"=>"")
    else
        GITHUB_HEAD_REF = ENV["GITHUB_HEAD_REF"]
        rev = GITHUB_HEAD_REF
    end
    return rev
end
