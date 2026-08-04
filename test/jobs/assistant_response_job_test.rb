# frozen_string_literal: true

require "test_helper"

class AssistantResponseJobTest < ActiveJob::TestCase
  test "skips a message canceled via A2A" do
    chat = users(:family_admin).chats.start!("Hello", model: "gpt-4.1")
    message = chat.messages.last
    chat.update!(a2a_state: message.id.to_s)

    message.expects(:request_response).never
    AssistantResponseJob.perform_now(message)
  end

  test "skips the legacy chat-level canceled marker" do
    chat = users(:family_admin).chats.start!("Hello", model: "gpt-4.1")
    message = chat.messages.last
    chat.update!(a2a_state: "canceled")

    message.expects(:request_response).never
    AssistantResponseJob.perform_now(message)
  end

  test "requests a response for active chats" do
    chat = users(:family_admin).chats.start!("Hello", model: "gpt-4.1")
    message = chat.messages.last

    message.stubs(:request_response)
    AssistantResponseJob.perform_now(message)
  end

  test "runs a newer message after a different turn was canceled" do
    chat = users(:family_admin).chats.start!("First turn", model: "gpt-4.1")
    canceled_message = chat.messages.last
    chat.update!(a2a_state: canceled_message.id.to_s)
    newer_message = chat.messages.create!(type: "UserMessage", content: "Newer turn", ai_model: "gpt-4.1")

    newer_message.stubs(:request_response)
    AssistantResponseJob.perform_now(newer_message)
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
