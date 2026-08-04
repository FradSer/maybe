# frozen_string_literal: true

require "test_helper"

class Api::V1::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.update!(ai_enabled: true)

    @oauth_app = Doorkeeper::Application.create!(
      name: "Test API App",
      redirect_uri: "https://example.com/callback",
      scopes: "read write read_write"
    )

    @write_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_write"
    )

    @chat = chats(:one)
  end

  test "should require authentication" do
    post "/api/v1/chats/#{@chat.id}/messages"
    assert_response :unauthorized
  end

  test "should require AI to be enabled" do
    @user.update!(ai_enabled: false)

    post "/api/v1/chats/#{@chat.id}/messages",
      params: { content: "Hello" },
      headers: bearer_auth_header(@write_token)
    assert_response :forbidden
  end

  test "should create message with write scope" do
    assert_difference "Message.count" do
      post "/api/v1/chats/#{@chat.id}/messages",
        params: { content: "Test message", model: "gpt-4" },
        headers: bearer_auth_header(@write_token)
    end

    assert_response :created
    response_body = JSON.parse(response.body)
    assert_equal "Test message", response_body["content"]
    assert_equal "user_message", response_body["type"]
    assert_equal "pending", response_body["ai_response_status"]
  end

  test "should enqueue assistant response job exactly once" do
    assert_enqueued_jobs 1, only: AssistantResponseJob do
      post "/api/v1/chats/#{@chat.id}/messages",
        params: { content: "Test message" },
        headers: bearer_auth_header(@write_token)
    end
  end

  test "should retry last assistant message" do
    skip "Retry functionality needs debugging"

    # Create an assistant message to retry
    assistant_message = @chat.messages.create!(
      type: "AssistantMessage",
      content: "Previous response",
      ai_model: "gpt-4"
    )

    assert_enqueued_with(job: AssistantResponseJob) do
      post "/api/v1/chats/#{@chat.id}/messages/retry",
        headers: bearer_auth_header(@write_token)
    end

    assert_response :accepted
    response_body = JSON.parse(response.body)
    assert response_body["message_id"].present?
  end

  test "create resumes a chat canceled via A2A" do
    @chat.update!(a2a_state: "canceled")

    post "/api/v1/chats/#{@chat.id}/messages",
      params: { content: "New intent" },
      headers: bearer_auth_header(@write_token)

    assert_response :created
    assert_nil @chat.reload.a2a_state
  end

  test "failed create keeps the A2A cancel marker" do
    @chat.update!(a2a_state: "canceled")

    post "/api/v1/chats/#{@chat.id}/messages",
      params: { content: "" },
      headers: bearer_auth_header(@write_token)

    assert_response :unprocessable_entity
    assert_equal "canceled", @chat.reload.a2a_state
  end

  test "retry resumes a chat canceled via A2A" do
    skip "API retry endpoint is pre-existing broken (creates empty-content message failing validation); resume fix covered by chat_test ask_assistant_later"
  end

  test "should not retry if no assistant message exists" do
    # Remove all assistant messages
    @chat.messages.where(type: "AssistantMessage").destroy_all

    post "/api/v1/chats/#{@chat.id}/messages/retry.json",
      headers: bearer_auth_header(@write_token)

    assert_response :unprocessable_entity
    response_body = JSON.parse(response.body)
    assert_equal "No assistant message to retry", response_body["error"]
  end

  test "should not access messages in other user's chat" do
    other_user = users(:family_member)
    other_user.update!(family: families(:empty))
    other_chat = chats(:two)
    other_chat.update!(user: other_user)

    post "/api/v1/chats/#{other_chat.id}/messages",
      params: { content: "Test" },
      headers: bearer_auth_header(@write_token)

    assert_response :not_found
  end

  private

    def bearer_auth_header(token)
      { "Authorization" => "Bearer #{token.token}" }
    end
end
