class AssistantResponseJob < ApplicationJob
  queue_as :high_priority

  def perform(message)
    chat = message.chat

    # A2A tasks/cancel may race with a queued response. Chat#cancel! stores the
    # id of the canceled user message in a2a_state; skip that exact turn (a
    # newer message that resumes the chat still runs). The literal "canceled"
    # marker is skipped too, covering the pre-message-id fallback.
    canceled = chat.a2a_state
    return if canceled.present? && (canceled == "canceled" || canceled == message.id.to_s)

    message.request_response
  end
end
