require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @assistant = mock
  end

  test "user sees all messages in debug mode" do
    chat = chats(:one)
    with_env_overrides AI_DEBUG_MODE: "true" do
      assert_equal chat.messages.count, chat.conversation_messages.count
    end
  end

  test "user sees assistant and user messages in normal mode" do
    chat = chats(:one)
    assert_equal 3, chat.conversation_messages.count
  end

  test "creates with initial message" do
    prompt = "Test prompt"

    assert_difference "@user.chats.count", 1 do
      chat = @user.chats.start!(prompt, model: "gpt-4.1")

      assert_equal 1, chat.messages.count
      assert_equal 1, chat.messages.where(type: "UserMessage").count
    end
  end

  test "a2a_status is working while awaiting a response" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")

    assert_equal [ "working", nil ], chat.a2a_status
  end

  test "a2a_status is completed when last conversation message is assistant" do
    assert_equal [ "completed", nil ], chats(:one).a2a_status
  end

  test "a2a_status is failed with error message" do
    chat = chats(:one)
    chat.update!(error: "boom")

    assert_equal [ "failed", "boom" ], chat.a2a_status
  end

  test "a2a_status is failed with hash error" do
    chat = chats(:one)
    chat.update!(error: { "message" => "boom" })

    assert_equal [ "failed", "boom" ], chat.a2a_status
  end

  test "a2a_status is canceled when marker is set" do
    chat = chats(:one)
    chat.update!(a2a_state: "canceled")

    assert_equal [ "canceled", nil ], chat.a2a_status
  end

  test "cancel! marks a pending task canceled" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")

    assert chat.cancel!
    assert_equal "canceled", chat.a2a_state
  end

  test "cancel! is a no-op on terminal tasks" do
    chat = chats(:one)
    chat.update!(error: "boom")

    assert_not chat.cancel!
    assert_nil chat.a2a_state

    assert_not chats(:one).cancel!
    assert_nil chats(:one).reload.a2a_state
  end

  test "cancel! is idempotent" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")
    chat.update!(a2a_state: "canceled")

    assert_not chat.cancel!
    assert_equal "canceled", chat.a2a_state
  end

  test "resume_from_cancel! clears the marker" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")
    chat.update!(a2a_state: "canceled")

    chat.resume_from_cancel!
    assert_nil chat.a2a_state
  end
end
