# frozen_string_literal: true

class Dashboard::ApplicationController < ApplicationController
  layout 'dashboard'

  private

  def order_pinned_first(relation)
    table = relation.klass.table_name

    relation
      .select("#{table}.*, namespace_pins.id AS pin_id")
      .joins(
        "LEFT JOIN namespace_pins
           ON namespace_pins.namespace_id = #{table}.namespace_id
          AND namespace_pins.user_id = #{current_user.id}"
      )
      .order(Arel.sql("pin_id ASC NULLS LAST, #{table}.namespace_id DESC"))
  end
end
