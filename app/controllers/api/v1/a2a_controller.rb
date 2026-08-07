# frozen_string_literal: true

# A2A protocol (v1.0) over JSON-RPC 2.0. Single dispatch endpoint; auth
# (OAuth Bearer or X-Api-Key), rate limiting, and audit logging come from
# Api::V1::BaseController. An A2A Task maps 1:1 to a Chat.
#
# v1.0 wire format:
#   - PascalCase methods: SendMessage / GetTask / CancelTask
#   - Task id params: GetTask/CancelTask use params.id (resource id)
#   - Message parts are presence-based: { "text": "..." } (no kind/type)
#   - TaskState serializes uppercase: TASK_STATE_COMPLETED etc.
#   - Requests carry an A2A-Version: 1.0 header (missing is accepted as v1.0)
class Api::V1::A2aController < Api::V1::BaseController
  # Rails raises this while parsing an invalid JSON body before the action runs
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_json_parse_error

  def create
    payload = parse_body
    return if performed?

    unless payload.is_a?(Hash) && payload["jsonrpc"] == "2.0" && payload["method"].is_a?(String)
      return render_a2a_error(-32600, "Invalid Request: 'jsonrpc' must be '2.0' and 'method' is required", :bad_request)
    end

    # JSON-RPC 2.0: only an *absent* id marks a notification (a null id is a
    # valid request id and must be echoed).
    @a2a_request_id = payload["id"]
    @a2a_notification = !payload.key?("id")

    case payload["method"]
    when "SendMessage" then handle_message_send(payload["params"])
    when "GetTask" then handle_tasks_get(payload["params"])
    when "CancelTask" then handle_tasks_cancel(payload["params"])
    else render_a2a_error(-32601, "Method not found: #{payload["method"]}")
    end

    head :no_content if @a2a_notification && !performed?
  end

  private

    def parse_body
      request.body.rewind
      JSON.parse(request.body.read)
    rescue JSON::ParserError
      render_a2a_error(-32700, "Parse error: invalid JSON body", :bad_request, id: nil)
      nil
    end

    def handle_message_send(params)
      return unless authorize_scope!(:write)
      return if performed?
      unless current_resource_owner&.ai_enabled?
        render_a2a_error(-32000, "AI features are not enabled for this user - feature_disabled", :forbidden) unless @a2a_notification
        return
      end

      unless params.is_a?(Hash) && params["message"].is_a?(Hash)
        return render_a2a_error(-32602, "Invalid params: 'message' object is required")
      end

      # v1.0: parts are presence-based -- a text part carries `text` directly
      # (no `kind`/`type` discriminator). Accept a `type: "text"` legacy part too.
      text = Array(params.dig("message", "parts"))
        .find { |part| part.is_a?(Hash) && part["text"].is_a?(String) && part["text"].present? }
        &.dig("text")
      return render_a2a_error(-32602, "Invalid params: message must contain a non-empty text part") if text.blank?

      chat = find_or_build_chat(params, text)
      return unless chat

      render_a2a_result(a2a_task(chat))
    end

    def find_or_build_chat(params, text)
      # v1.0: SendMessage continuation uses message.taskId (the Message carries
      # the task id it belongs to). Accept message.taskId and a top-level
      # params.taskId for compatibility with v0.2-style callers.
      task_id = params.dig("message", "taskId").presence || params["taskId"].presence
      if task_id.present?
        chat = find_task(task_id)
        return unless chat
        UserMessage.create!(chat: chat, content: text, ai_model: Provider::Openai::MODELS.first)
        # Resume a canceled chat only after the message persists.
        chat.resume_from_cancel!
        chat
      else
        Current.user.chats.start!(text, model: Provider::Openai::MODELS.first)
      end
    end

    def handle_tasks_get(params)
      return unless authorize_scope!(:read)
      return if performed?

      # v1.0 GetTask uses params.id (the resource id).
      task_id = params.is_a?(Hash) ? (params["id"].presence || params["taskId"].presence) : nil
      return render_a2a_error(-32602, "Invalid params: 'id' is required") if task_id.blank?

      chat = find_task(task_id)
      return unless chat

      render_a2a_result(a2a_task(chat))
    end

    def handle_tasks_cancel(params)
      return unless authorize_scope!(:write)
      return if performed?

      # v1.0 CancelTask uses params.id (the resource id).
      task_id = params.is_a?(Hash) ? (params["id"].presence || params["taskId"].presence) : nil
      return render_a2a_error(-32602, "Invalid params: 'id' is required") if task_id.blank?

      chat = find_task(task_id)
      return unless chat

      chat.cancel!
      render_a2a_result(a2a_task(chat))
    end

    def find_task(task_id)
      unless task_id.is_a?(String) && task_id.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
        render_a2a_error(-32001, "TaskNotFoundError: task #{task_id} not found")
        return nil
      end

      chat = Current.user.chats.find_by(id: task_id)
      render_a2a_error(-32001, "TaskNotFoundError: task #{task_id} not found") unless chat
      chat
    end

    # ─── v1.0 wire Task ────────────────────────────────────────────────────
    # Maps the internal lowercase Chat state to the uppercase v1.0 TaskState,
    # emits presence-based text parts, and marks the Task with an artifact for
    # the completed assistant turn. No `kind` discriminator on the wire.

    TASK_STATE_WIRE = {
      "submitted" => "TASK_STATE_SUBMITTED",
      "working" => "TASK_STATE_WORKING",
      "completed" => "TASK_STATE_COMPLETED",
      "failed" => "TASK_STATE_FAILED",
      "canceled" => "TASK_STATE_CANCELED",
      "input-required" => "TASK_STATE_INPUT_REQUIRED",
      "auth-required" => "TASK_STATE_AUTH_REQUIRED",
      "rejected" => "TASK_STATE_REJECTED"
    }.freeze

    def wire_state(state)
      TASK_STATE_WIRE.fetch(state, "TASK_STATE_UNSPECIFIED")
    end

    def a2a_task(chat)
      state, error_message = chat.a2a_status
      status = { state: wire_state(state), timestamp: chat.updated_at.iso8601 }
      status[:error] = { code: -32000, message: error_message } if error_message.present?

      {
        id: chat.id,
        status: status,
        artifacts: a2a_artifacts(chat),
        metadata: { title: chat.title }
      }
    end

    def a2a_artifacts(chat)
      # A genuinely canceled task (marker matches the last user turn) delivers
      # no artifacts, even if a raced generation finished after the cancel.
      # A resumed chat (newer turn) serves its completed response.
      return [] if chat.a2a_state.present? && chat.a2a_state == chat.last_user_message_id

      last_assistant = chat.conversation_messages.ordered.last
      return [] unless last_assistant&.role == "assistant" && last_assistant.status == "complete"

      [ { name: "assistant_message", parts: [ { text: last_assistant.content.to_s } ] } ]
    end

    def render_a2a_result(task)
      return if @a2a_notification

      render json: { jsonrpc: "2.0", id: @a2a_request_id, result: task }
    end

    def render_a2a_error(code, message, http_status = :ok, id: :request_id)
      # JSON-RPC 2.0: MUST NOT reply to a notification. Errors raised before
      # the request id is known (parse / invalid request) still reply with
      # id: null, as the spec permits.
      return if @a2a_notification

      resolved_id = id == :request_id ? @a2a_request_id : id
      render json: { jsonrpc: "2.0", id: resolved_id, error: { code: code, message: message } }, status: http_status
    end

    def handle_json_parse_error
      render_a2a_error(-32700, "Parse error: invalid JSON body", :bad_request, id: nil)
    end

    # Wrap every error rendered by the base stack (auth 401, scope/ai 403,
    # rate limit 429) in the JSON-RPC error envelope. Base renders use symbol
    # keys ({ error: "..." }), so both string and symbol keys are handled.
    def render_json(data, status: :ok)
      error_code = data.is_a?(Hash) && (data["error"] || data[:error])

      if error_code.present?
        code = { "record_not_found" => -32001, "insufficient_scope" => -32000, "feature_disabled" => -32000,
                 "unauthorized" => -32000, "rate_limit_exceeded" => -32000, "bad_request" => -32602 }
          .fetch(error_code.to_s, -32000)
        message = [ data["message"] || data[:message], error_code ].compact.join(" - ")
        render_a2a_error(code, message, status)
      else
        super
      end
    end
end
