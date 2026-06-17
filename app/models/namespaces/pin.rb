# frozen_string_literal: true

module Namespaces
  class Pin < ApplicationRecord
    self.table_name = 'namespace_pins'

    belongs_to :namespace, inverse_of: :namespace_pins
    belongs_to :user, inverse_of: :namespace_pins

    validates :namespace_id, uniqueness: { scope: :user_id }
    validates :type, presence: true
  end
end
