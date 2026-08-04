class Chat < ApplicationRecord
  include Debuggable

  belongs_to :user

  has_one :viewer, class_name: "User", foreign_key: :last_viewed_chat_id, dependent: :nullify # "Last chat user has viewed"
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def start!(prompt, model:)
      create!(
        title: generate_title(prompt),
        messages: [ UserMessage.new(content: prompt, ai_model: model) ]
      )
    end

    def generate_title(prompt)
      prompt.first(80)
    end
  end

  def needs_assistant_response?
    conversation_messages.ordered.last.role != "assistant"
  end

  def retry_last_message!
    update!(error: nil)

    last_message = conversation_messages.ordered.last

    if last_message.present? && last_message.role == "user"

      ask_assistant_later(last_message)
    end
  end

  def update_latest_response!(provider_response_id)
    update!(latest_assistant_response_id: provider_response_id)
  end

  def add_error(e)
    update! error: e.to_json
    broadcast_append target: "messages", partial: "chats/error", locals: { chat: self }
  end

  def clear_error
    update! error: nil
    broadcast_remove target: "chat-error"
  end

  def assistant
    @assistant ||= Assistant.for_chat(self)
  end

  def ask_assistant_later(message)
    clear_error
    # Any new user intent (web message, retry, or A2A continuation) resumes a
    # canceled chat so the guard only skips the already-queued response.
    resume_from_cancel!
    AssistantResponseJob.perform_later(message)
  end

  def ask_assistant(message)
    assistant.respond_to(message)
  end

  def conversation_messages
    if debug_mode?
      messages
    else
      messages.where(type: [ "UserMessage", "AssistantMessage" ])
    end
  end

  # A2A protocol task state (v1). Only "canceled" is persisted; all other
  # states are derived from live pipeline state.
  def a2a_status
    return [ "canceled", nil ] if a2a_state == "canceled"

    if error.present?
      message = error.is_a?(Hash) ? error["message"] : error.to_s
      return [ "failed", message ]
    end

    last = conversation_messages.ordered.last
    return [ "completed", nil ] if last&.role == "assistant"

    [ "working", nil ]
  end

  def cancel!
    return false if [ "completed", "failed", "canceled" ].include?(a2a_status.first)

    update!(a2a_state: "canceled")
  end

  def resume_from_cancel!
    update!(a2a_state: nil) if a2a_state == "canceled"
  end
end
