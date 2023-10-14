# frozen_string_literal: true

RSpec.describe 'Rspec test', type: :request do
  describe 'check rspec successfully installed and working without rails' do
    it 'should be eq' do
      expect(3).to eq(3)
    end
  end
end
