"""
    event()
Returns the event.json content as a Dict.
Returns `nothing` if the current environment is not CI.
"""
function event()
    if isinCI()
        filename = ENV["GITHUB_EVENT_PATH"]
        return JSON.parsefile(filename; dicttype=Dict, inttype=Int64, use_mmap=true)
    else
        return nothing
    end
end

"""
    EVENT
Current event.json as a Dict.
It will be `nothing` if the current environment is not CI.
"""
EVENT = event()


"""
    event_refs()

Event refs like `"refs/heads/test"`
"""
event_refs() = EVENT["refs"]

"""
    event_after()

Event after commit id `"f287155523494e3a787e0a03c6b2b61407375341"`
"""
event_after() = EVENT["after"]

"""
    event_before()

Event before commit id `"f287155523494e3a787e0a03c6b2b61407375341"`
"""
event_before() = EVENT["before"]

"""
    event_iscreated()

Returns true if the event is created
"""
event_iscreated() = EVENT["created"]

"""
    event_isdeleted()

Returns true if the event is deleted
"""
event_isdeleted() = EVENT["deleted"]

"""
    event_isforced()

Returns true if the event is forced
"""
event_isforced() = EVENT["forced"]

"""
    event_isonpullrequest()

Returns true if the running job is triggered on a pull request
"""
function event_isonpullrequest()
    GITHUB_REF = ENV["GITHUB_REF"]
    return occursin("pull", GITHUB_REF)
end

include("head_commit.jl")
include("repository.jl")
include("owner.jl")
include("pusher_sender_actor.jl")
