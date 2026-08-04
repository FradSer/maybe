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

  test "a2a_status is working while assistant response is pending" do
    chat = @user.chats.start!("Streaming", model: "gpt-4.1")
    chat.messages.create!(type: "AssistantMessage", content: "partial", ai_model: "gpt-4.1", status: "pending")

    assert_equal [ "working", nil ], chat.a2a_status
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

  test "a2a_status surfaces only the message from stored exception JSON" do
    chat = chats(:one)
    chat.update!(error: { "message" => "LLM error", "backtrace" => [ "/app/models/x.rb:1" ] }.to_json)

    assert_equal [ "failed", "LLM error" ], chat.a2a_status
  end

  test "a2a_status is canceled when marker matches the last user turn" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")
    last_user = chat.conversation_messages.ordered.where(type: "UserMessage").last
    chat.update!(a2a_state: last_user.id.to_s)

    assert_equal [ "canceled", nil ], chat.a2a_status
  end

  test "a2a_status is not canceled when marker is a stale canceled turn" do
    chat = chats(:one)
    chat.update!(a2a_state: "canceled")

    assert_not_equal "canceled", chat.a2a_status.first
  end

  test "cancel! marks a pending task canceled" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")
    last_user = chat.conversation_messages.ordered.where(type: "UserMessage").last

    assert chat.cancel!
    assert_equal last_user.id.to_s, chat.a2a_state
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
    last_user = chat.conversation_messages.ordered.where(type: "UserMessage").last
    chat.update!(a2a_state: last_user.id.to_s)

    assert_not chat.cancel!
    assert_equal last_user.id.to_s, chat.a2a_state
  end

  test "resume_from_cancel! keeps the marker so the canceled job stays suppressed" do
    chat = @user.chats.start!("Pending", model: "gpt-4.1")
    chat.update!(a2a_state: "canceled")

    chat.resume_from_cancel!
    assert_equal "canceled", chat.a2a_state
  end

  test "a2a_status stops reporting canceled once a newer user turn arrives" do
    chat = @user.chats.start!("Canceled turn", model: "gpt-4.1")
    canceled_message = chat.messages.last
    chat.update!(a2a_state: canceled_message.id.to_s)
    assert_equal [ "canceled", nil ], chat.a2a_status

    chat.messages.create!(type: "UserMessage", content: "Newer turn", ai_model: "gpt-4.1")
    assert_equal [ "working", nil ], chat.a2a_status
    # Marker persists so the canceled turn's queued job stays suppressed.
    assert_equal canceled_message.id.to_s, chat.a2a_state
  end
end
