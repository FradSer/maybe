class AssistantResponseJob < ApplicationJob
  queue_as :high_priority

  def perform(message)
    # A2A tasks/cancel may race with a queued response. The persisted marker
    # is the source of truth (no Sidekiq job removal in v1): any new user
    # intent (web message, API create, retry, or A2A continuation) resumes a
    # canceled chat before enqueuing, so the guard only skips a response for a
    # task that is still canceled with no newer turn.
    return if message.chat.a2a_state == "canceled"

    message.request_response
  end
end
