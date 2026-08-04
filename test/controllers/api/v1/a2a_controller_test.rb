# frozen_string_literal: true

require "test_helper"

class Api::V1::A2aControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.update!(ai_enabled: true)

    @oauth_app = Doorkeeper::Application.create!(
      name: "Test API App",
      redirect_uri: "https://example.com/callback",
      scopes: "read write read_write"
    )

    @read_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read"
    )

    @write_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_write"
    )

    @api_key = api_keys(:active_key)
    @api_key_header = { "X-Api-Key" => @api_key.plain_key }

    # Clear any existing rate limit data (shared Redis counter across test runs)
    Redis.new.del("api_rate_limit:#{@api_key.id}")
  end

  teardown do
    Redis.new.del("api_rate_limit:#{@api_key.id}")
  end

  test "requires authentication" do
    post a2a_path, params: send_message_rpc("Hello"), headers: json_headers

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert body["error"].present?
  end

  test "authenticates with API key" do
    post a2a_path, params: send_message_rpc("Hello"), headers: json_headers.merge(@api_key_header)

    assert_response :success
  end

  test "rejects invalid API key" do
    post a2a_path, params: send_message_rpc("Hello"), headers: json_headers.merge("X-Api-Key" => "wrong-key")

    assert_response :unauthorized
  end

  test "message/send creates a chat and enqueues a response" do
    assert_difference [ "Chat.count", "Message.count" ] do
      assert_enqueued_jobs 1, only: AssistantResponseJob do
        post a2a_path, params: send_message_rpc("What is my net worth?", id: 42), headers: json_headers.merge(@api_key_header)
      end
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert_equal 42, body["id"]
    task = body["result"]
    assert_equal "working", task.dig("status", "state")
    assert_equal "What is my net worth?", UserMessage.find_by(chat_id: task["id"]).content
  end

  test "message/send requires write scope" do
    post a2a_path, params: send_message_rpc("Hello"), headers: json_headers.merge(bearer_auth_header(@read_token))

    assert_response :forbidden
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert_equal(-32000, body.dig("error", "code"))
    assert_includes body.dig("error", "message"), "insufficient_scope"
  end

  test "message/send requires AI to be enabled" do
    @user.update!(ai_enabled: false)

    post a2a_path, params: send_message_rpc("Hello"), headers: json_headers.merge(@api_key_header)

    assert_response :forbidden
    assert_includes JSON.parse(response.body).dig("error", "message"), "feature_disabled"
  end

  test "tasks/get reports completed state with artifact" do
    post a2a_path, params: tasks_get_rpc(chats(:one).id), headers: json_headers.merge(@api_key_header)

    assert_response :success
    task = JSON.parse(response.body)["result"]
    assert_equal "completed", task.dig("status", "state")
    assert_equal 1, task["artifacts"].size
    assert_equal "assistant_message", task["artifacts"].first["name"]
    assert task["artifacts"].first.dig("parts", 0, "text").present?
  end

  test "tasks/get reports working state" do
    chat = @user.chats.start!("In progress", model: "gpt-4.1")

    post a2a_path, params: tasks_get_rpc(chat.id), headers: json_headers.merge(@api_key_header)

    task = JSON.parse(response.body)["result"]
    assert_equal "working", task.dig("status", "state")
    assert_empty task["artifacts"]
  end

  test "tasks/get reports failed state with error" do
    chat = chats(:one)
    chat.update!(error: "boom")

    post a2a_path, params: tasks_get_rpc(chat.id), headers: json_headers.merge(@api_key_header)

    task = JSON.parse(response.body)["result"]
    assert_equal "failed", task.dig("status", "state")
    assert_equal "boom", task.dig("status", "error", "message")
  end

  test "tasks/get reports canceled state" do
    chat = chats(:one)
    chat.update!(a2a_state: "canceled")

    post a2a_path, params: tasks_get_rpc(chat.id), headers: json_headers.merge(@api_key_header)

    task = JSON.parse(response.body)["result"]
    assert_equal "canceled", task.dig("status", "state")
  end

  test "tasks/get works with read scope" do
    post a2a_path, params: tasks_get_rpc(chats(:one).id), headers: json_headers.merge(bearer_auth_header(@read_token))

    assert_response :success
  end

  test "tasks/cancel marks a pending task canceled" do
    chat = @user.chats.start!("To cancel", model: "gpt-4.1")

    post a2a_path, params: tasks_cancel_rpc(chat.id), headers: json_headers.merge(@api_key_header)

    assert_response :success
    assert_equal "canceled", JSON.parse(response.body).dig("result", "status", "state")
    assert_equal "canceled", chat.reload.a2a_state
  end

  test "tasks/cancel is a no-op on completed tasks" do
    chat = chats(:one)

    post a2a_path, params: tasks_cancel_rpc(chat.id), headers: json_headers.merge(@api_key_header)

    assert_response :success
    assert_equal "completed", JSON.parse(response.body).dig("result", "status", "state")
    assert_nil chat.reload.a2a_state
  end

  test "tasks/cancel requires write scope" do
    post a2a_path, params: tasks_cancel_rpc(chats(:one).id), headers: json_headers.merge(bearer_auth_header(@read_token))

    assert_response :forbidden
  end

  test "message/send continues an existing task" do
    chat = @user.chats.start!("First message", model: "gpt-4.1")

    assert_difference "Message.count", 1 do
      assert_no_difference "Chat.count" do
        assert_enqueued_jobs 1, only: AssistantResponseJob do
          post a2a_path, params: send_message_rpc("Follow-up question", task_id: chat.id), headers: json_headers.merge(@api_key_header)
        end
      end
    end

    assert_response :success
    assert_equal chat.id, JSON.parse(response.body).dig("result", "id")
  end

  test "message/send resumes a canceled task" do
    chat = @user.chats.start!("Canceled task", model: "gpt-4.1")
    chat.update!(a2a_state: "canceled")

    post a2a_path, params: send_message_rpc("Continue anyway", task_id: chat.id), headers: json_headers.merge(@api_key_header)

    assert_response :success
    assert_nil chat.reload.a2a_state
  end

  test "returns TaskNotFoundError for unknown task" do
    post a2a_path, params: tasks_get_rpc(SecureRandom.uuid), headers: json_headers.merge(@api_key_header)

    assert_response :success
    error = JSON.parse(response.body)["error"]
    assert_equal(-32001, error["code"])
  end

  test "returns TaskNotFoundError for another user's task" do
    other_chat = chats(:two) # belongs to family_member

    post a2a_path, params: tasks_get_rpc(other_chat.id), headers: json_headers.merge(@api_key_header)

    error = JSON.parse(response.body)["error"]
    assert_equal(-32001, error["code"])
  end

  test "returns method not found for unknown methods" do
    post a2a_path, params: JSON.generate({ jsonrpc: "2.0", id: 1, method: "tasks/list", params: {} }), headers: json_headers.merge(@api_key_header)

    error = JSON.parse(response.body)["error"]
    assert_equal(-32601, error["code"])
  end

  test "returns parse error for invalid JSON" do
    post a2a_path, params: "not json", headers: json_headers.merge(@api_key_header)

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_nil body["id"]
    assert_equal(-32700, body.dig("error", "code"))
  end

  test "returns invalid request when jsonrpc is missing" do
    post a2a_path, params: JSON.generate({ id: 1, method: "tasks/get", params: {} }), headers: json_headers.merge(@api_key_header)

    assert_response :bad_request
    assert_equal(-32600, JSON.parse(response.body).dig("error", "code"))
  end

  test "returns invalid params when message is missing" do
    post a2a_path, params: JSON.generate({ jsonrpc: "2.0", id: 1, method: "message/send", params: {} }), headers: json_headers.merge(@api_key_header)

    assert_equal(-32602, JSON.parse(response.body).dig("error", "code"))
  end

  test "returns invalid params for empty text part" do
    rpc = JSON.generate({
      jsonrpc: "2.0", id: 1, method: "message/send",
      params: { "message" => { "role" => "user", "parts" => [ { "type" => "text", "text" => "" } ] } }
    })
    post a2a_path, params: rpc, headers: json_headers.merge(@api_key_header)

    assert_equal(-32602, JSON.parse(response.body).dig("error", "code"))
  end

  test "returns invalid params for non-hash parts elements" do
    [ [ 123 ], [ nil ], { "type" => "text" } ].each do |bad_parts|
      rpc = JSON.generate({
        jsonrpc: "2.0", id: 1, method: "message/send",
        params: { "message" => { "role" => "user", "parts" => bad_parts } }
      })
      post a2a_path, params: rpc, headers: json_headers.merge(@api_key_header)

      assert_response :success
      assert_equal(-32602, JSON.parse(response.body).dig("error", "code"), "parts=#{bad_parts.inspect}")
    end
  end

  test "returns invalid params when taskId is missing" do
    post a2a_path, params: JSON.generate({ jsonrpc: "2.0", id: 1, method: "tasks/get", params: {} }), headers: json_headers.merge(@api_key_header)

    assert_equal(-32602, JSON.parse(response.body).dig("error", "code"))
  end

  test "notification requests get no response body" do
    assert_difference "Chat.count" do
      post a2a_path, params: JSON.generate({
        jsonrpc: "2.0", method: "message/send",
        params: { "message" => { "role" => "user", "parts" => [ { "type" => "text", "text" => "Fire and forget" } ] } }
      }), headers: json_headers.merge(@api_key_header)
    end

    assert_response :no_content
  end

  private

    def a2a_path
      "/api/v1/a2a"
    end

    def json_headers
      { "Content-Type" => "application/json" }
    end

    def send_message_rpc(text, id: 1, task_id: nil)
      params = { "message" => { "role" => "user", "parts" => [ { "type" => "text", "text" => text } ] } }
      params["taskId"] = task_id if task_id.present?
      JSON.generate({ jsonrpc: "2.0", id: id, method: "message/send", params: params })
    end

    def tasks_get_rpc(task_id, id: 1)
      JSON.generate({ jsonrpc: "2.0", id: id, method: "tasks/get", params: { "taskId" => task_id } })
    end

    def tasks_cancel_rpc(task_id, id: 1)
      JSON.generate({ jsonrpc: "2.0", id: id, method: "tasks/cancel", params: { "taskId" => task_id } })
    end

    def bearer_auth_header(token)
      { "Authorization" => "Bearer #{token.token}" }
    end
end
