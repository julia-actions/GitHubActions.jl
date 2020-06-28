"""
    event_pusher()
Pusher email and name as a Dict
"""
event_pusher() = EVENT["pusher"]

"""
    event_sender()
Sender information as a Dict
"""
event_sender() = EVENT["sender"]

"""
    event_sender_html_url()
Sender html_url like `"https://github.com/aminya"`
"""
event_sender_html_url() = event_sender()["html_url"]

"""
    event_sender_login()
Sender login like `"aminya"`
"""
event_sender_login() = event_sender()["login"]

"""
    event_sender_url()
Sender profile json API url
"""
event_sender_url() = event_sender()["url"]


"""
    event_actor()

Returns the login of event's actor
"""
function event_actor()
    actor = ENV["GITHUB_ACTOR"]
    return actor
end
