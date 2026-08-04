# frozen_string_literal: true

require "test_helper"

class AssistantResponseJobTest < ActiveJob::TestCase
  test "skips chats canceled via A2A" do
    chat = users(:family_admin).chats.start!("Hello", model: "gpt-4.1")
    chat.update!(a2a_state: "canceled")
    message = chat.messages.last

    message.expects(:request_response).never
    AssistantResponseJob.perform_now(message)
  end

  test "requests a response for active chats" do
    chat = users(:family_admin).chats.start!("Hello", model: "gpt-4.1")
    message = chat.messages.last

    message.stubs(:request_response)
    AssistantResponseJob.perform_now(message)
  end

  test "skips a superseded message after the chat is resumed" do
    chat = users(:family_admin).chats.start!("First turn", model: "gpt-4.1")
    canceled_message = chat.messages.last
    # A newer turn arrives (chat no longer canceled), making the old job stale.
    chat.messages.create!(type: "UserMessage", content: "Newer turn", ai_model: "gpt-4.1")

    canceled_message.expects(:request_response).never
    AssistantResponseJob.perform_now(canceled_message)
  end

  test "runs a retried user message even when an assistant message is the last row" do
    chat = users(:family_admin).chats.start!("Retry me", model: "gpt-4.1")
    user_message = chat.messages.last
    # The chat ends with an AssistantMessage (normal state after a response).
    chat.messages.create!(type: "AssistantMessage", content: "Previous answer", ai_model: "gpt-4.1", status: "complete")

    user_message.stubs(:request_response)
    AssistantResponseJob.perform_now(user_message)
  end
end
