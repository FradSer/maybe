class AssistantResponseJob < ApplicationJob
  queue_as :high_priority

  def perform(message)
    chat = message.chat

    # A2A tasks/cancel may race with a queued response. Skip when the chat is
    # still canceled, or when this message has been superseded by a newer
    # *user* turn (a resumed chat must not re-answer a canceled, older message;
    # comparing against user turns keeps retries and follow-ups runnable even
    # when an AssistantMessage for the previous turn is the last row).
    return if chat.a2a_state == "canceled"
    return if message != chat.conversation_messages.ordered.where(type: "UserMessage").last

    message.request_response
  end
end
