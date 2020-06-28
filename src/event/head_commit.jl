"""
    event_head_commit()
Event head commit as a Dict
"""
event_head_commit() = EVENT["head_commit"]

"""
    event_head_commit_id()
Event head commit id like `"f287155523494e3a787e0a03c6b2b61407375341"`
"""
event_head_commit_id() = event_head_commit()["id"]

"""
    event_head_commit_tree_id()
Event head commit tree_id like `"8ebd15ec69c433c072cb58866dfd358a8de772da"`
"""
event_head_commit_tree_id() = event_head_commit()["tree_id"]

"""
    event_head_commit_message()
Event head commit message
"""
event_head_commit_message() = event_head_commit()["message"]

"""
    event_head_commit_url()
Event head commit url like `"https://github.com/aminya/GitHubActions.jl/commit/f287155523494e3a787e0a03c6b2b61407375341"`
"""
event_head_commit_url() = event_head_commit()["url"]

"""
    event_head_commit_committer()
Event head commit committer email, name, and username as a Dict
"""
event_head_commit_committer() = event_head_commit()["committer"]

"""
    event_head_commit_author()
Event head commit author email, name, and username as a Dict
"""
event_head_commit_author() = event_head_commit()["author"]
