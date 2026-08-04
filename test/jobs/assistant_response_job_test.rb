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
end
