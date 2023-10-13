# frozen_string_literal: true

class TagCreate
  include KindOfService

  log_level INFO

  def initialize(user, actor, tag_params)
    @user = user
    @actor = actor
    @tag_params = tag_params
  end

  private

  def perform
    tag = @user.firm.tags.build(@tag_params)
    transaction do
      tag.save!

      after_commit do
        CustomerIo::InAppMessagesRelatedUserSendWorker.perform_async(@actor.user.id, 'tag_create') if FeaturesHelper.feature_available?(:customer_io)
        HelpScoutUserSendWorker.perform_async(@actor.user.id) if FeaturesHelper.feature_available?(:help_scout)
      end
    end

    success(tag)
  rescue ActiveRecord::RecordInvalid => e
    failure(validation_error(e.record.errors))
  end
end

