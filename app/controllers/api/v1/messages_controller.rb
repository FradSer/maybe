# frozen_string_literal: true

class Api::V1::MessagesController < Api::V1::BaseController
  before_action :require_ai_enabled
  before_action :ensure_write_scope, only: [ :create, :retry ]
  before_action :set_chat

  def create
    @message = @chat.messages.build(
      content: message_params[:content],
      type: "UserMessage",
      ai_model: message_params[:model] || "gpt-4"
    )

    if @message.save
      # New user intent persists first; only resume a canceled chat once the
      # message is actually saved, so a failed save keeps the cancel marker.
      # UserMessage#after_create_commit enqueues the response exactly once.
      @chat.resume_from_cancel!
      render :show, status: :created
    else
      render json: { error: "Failed to create message", details: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def retry
    # Retry by re-enqueuing the last user message, matching the web
    # Chat#retry_last_message! pattern (AssistantResponseJob expects a
    # UserMessage). Creates no new message row.
    last_user = @chat.conversation_messages.ordered.where(type: "UserMessage").last

    if last_user.present?
      # Retrying is new user intent: clear any prior error and — when the
      # canceled turn is the one being retried — clear the marker so the
      # response job actually runs (resume_from_cancel! keeps the marker).
      @chat.clear_error
      @chat.update!(a2a_state: nil) if @chat.a2a_state == last_user.id.to_s
      AssistantResponseJob.perform_later(last_user)
      render json: { message: "Retry initiated", message_id: last_user.id }, status: :accepted
    else
      render json: { error: "No user message to retry" }, status: :unprocessable_entity
    end
  end

  private

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def set_chat
      @chat = Current.user.chats.find(params[:chat_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Chat not found" }, status: :not_found
    end

    def message_params
      params.permit(:content, :model)
    end
end
