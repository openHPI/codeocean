# frozen_string_literal: true

class CreateTipsIntervention < ActiveRecord::Migration[6.1]
  class Intervention < ApplicationRecord
  end

  def change
    Intervention.find_or_create_by(name: 'TipsIntervention')
  end
end
