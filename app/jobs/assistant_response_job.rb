class AssistantResponseJob < ApplicationJob
  queue_as :high_priority

  def perform(message)
    # A2A tasks/cancel may race with a queued response; the persisted
    # marker is the source of truth (no Sidekiq job removal in v1).
    return if message.chat.a2a_state == "canceled"

    message.request_response
  end
end
