# frozen_string_literal: true

class Api::V1::Firm::TagsController < Api::V1::Firm::ApplicationController
  before_action { check_feature_availability! :tags }

  def index
    form = Api::V1::Firm::Tags::IndexForm.new(params)
    tags = current_firm.tags.ransack(form.search_params).result(distinct: true)
    tags = tags.page(form.page).per(form.per)

    json = Api::V1::Firm::Tags::IndexSerializer.new({tags: tags, meta: tags}, current_user: current_user, current_actor: current_actor, includes: 
params[:includes]).as_json

    render json: json
  end

  def create
    form = Api::V1::Firm::Tags::CreateForm.new(params)
    result = TagCreate.call(current_user, current_actor, form.params)

    if result.successful?
      render json: {tag: Base::TagSerializer.new(result.data)}, status: :created
    else
      render json: {errors: result.errors}, status: :unprocessable_entity
    end
  end

  ### Other actions
end

