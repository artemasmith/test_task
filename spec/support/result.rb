# frozen_string_literal: true

class Result
  def self.accept
    true
  end

  def self.deny(exception)
    exception
  end
end
