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
    last_message = @chat.messages.ordered.last

    if last_message&.type == "AssistantMessage"
      new_message = @chat.messages.create!(
        type: "AssistantMessage",
        content: "",
        ai_model: last_message.ai_model
      )

      # Retrying is new user intent; resume a canceled chat only after the
      # message persists, so a failed create keeps the cancel marker.
      @chat.resume_from_cancel!
      AssistantResponseJob.perform_later(new_message)
      render json: { message: "Retry initiated", message_id: new_message.id }, status: :accepted
    else
      render json: { error: "No assistant message to retry" }, status: :unprocessable_entity
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
