# frozen_string_literal: true

class AddUserToProxyExercise < ActiveRecord::Migration[5.2]
  def change
    add_reference :proxy_exercises, :user, polymorphic: true, index: true
    add_column :proxy_exercises, :public, :boolean, null: false, default: false

    internal_user = InternalUser.find_by(id: 46) || InternalUser.first
    ProxyExercise.update(user_id: internal_user&.id || 1, user_type: internal_user.class.name)
  end
end
