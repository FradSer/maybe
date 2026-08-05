class AddA2aStateToChats < ActiveRecord::Migration[7.2]
  def change
    add_column :chats, :a2a_state, :string
  end
end
