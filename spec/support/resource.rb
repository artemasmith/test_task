# frozen_string_literal: true

class Resource
  def initialize(firm_id)
    @firm_id = firm_id
  end

  attr_reader :firm_id
end
