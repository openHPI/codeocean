# frozen_string_literal: true

class CreateProxyExercises < ActiveRecord::Migration[4.2]
  def change
    create_table :proxy_exercises do |t|
      t.string :title
      t.string :description
      t.string :token
      t.timestamps
    end

    create_table :exercises_proxy_exercises, id: false do |t|
      t.belongs_to :proxy_exercise, index: true
      t.belongs_to :exercise, index: true
      t.timestamps
    end

    create_table :user_proxy_exercise_exercises do |t|
      t.belongs_to :user, polymorphic: true, index: true
      t.belongs_to :proxy_exercise, index: true
      t.belongs_to :exercise, index: true
      t.timestamps
    end
  end
end
