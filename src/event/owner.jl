"""
    event_owner()
Owner information as a Dict
"""
event_owner() = event_repository()["owner"]

"""
    event_owner_login()
Owner login like `"aminya"`
"""
event_owner_login() = event_owner()["login"]

"""
    event_owner_name()
Owner name like `"aminya"`
"""
event_owner_name() = event_owner()["name"]

"""
    event_owner_email()
Owner email
"""
event_owner_email() = event_owner()["email"]

"""
    event_owner_url()
Owner profile json API url
"""
event_owner_url() = event_owner()["url"]
