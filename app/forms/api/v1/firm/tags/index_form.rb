# frozen_string_literal: true

module Api
  module V1
    module Firm
      module Tags
        class IndexForm < Api::V1::Firm::ApplicationForm
          def initialize(params)
            @params = params
            set_pagination_params(params)
          end

          def search_params
            params = permitted_params[:q] || ActionController::Parameters.new.permit
            params[:s] ||= ['name asc']
            params
          end

          private

          def permitted_params
            @params.permit(q: [:name_cont, { id_in: [], s: [] }])
          end
        end
      end
    end
  end
end
