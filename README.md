# GitHubActions

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://julia-actions.github.io/GitHubActions.jl)
[![Build Status](https://github.com/julia-actions/GitHubActions.jl/workflows/CI/badge.svg)](https://github.com/julia-actions/GitHubActions.jl/actions)

Utilities for working within GitHub Actions, modelled after [`actions/core`](https://github.com/actions/toolkit/tree/master/packages/core).

Perhaps the most common use case is to set the global logger to one compatible with GitHub Actions' log format:

### Inside the package
```
using Logging: global_logger
using GitHubActions: GitHubActionsLogger
function __init__()
    # Using GitHubActions logger in CI
    get(ENV, "GITHUB_ACTIONS", "false") == "true" && global_logger(GitHubActionsLogger())
end
```

### Inside the runtests
```jl
using Logging: global_logger
using GitHubActions: GitHubActionsLogger
# Using GitHubActions logger in CI
get(ENV, "GITHUB_ACTIONS", "false") == "true" && global_logger(GitHubActionsLogger())
@warn "This warning will be visible in your GitHub Actions logs!"
```



For information on the other provided functions, see the documentation.
