# frozen_string_literal: true

class AbstractPolicy
  class PolicyError < StandardError
    def self.kind(kind = nil)
      @kind = kind || @kind
    end

    def kind
      self.class.kind
    end
  end

  # Exception for unauthorized access
  # The basic exception for authorization purposes.
  # All exceptions MUST be inherited from it.
  class UnauthorizedAccessError < PolicyError
    kind 'forbidden'
  end

  class TokenUnauthorizedAccessError < UnauthorizedAccessError
    kind 'forbidden'
  end

  # Exception for non-existent firms
  # Use it when you want to notify a user about non-existent firms.
  class FirmNotFoundError < PolicyError
    kind 'firm_not_found'
  end

  # Exception for unauthorized access
  # The basic exception for authorization purposes.
  # All exceptions MUST be inherited from it.
  class ForbiddenAccessError < PolicyError
    kind 'forbidden'
  end

  # Exception for read-only mode ONLY!
  # Use it when you want to notify a user about read-only access.
  class ReadOnlyAccessError < PolicyError
    kind 'read_only_mode'
  end

  class SealedDocumentAccessError < PolicyError
    kind 'sealed_document'
  end

  class SealedDirectoryAccessError < PolicyError
    kind 'sealed_directory'
  end

  class ArchivedAccountAccessError < PolicyError
    kind 'account_archived'
  end

  # Exception for permission denied
  # Use when you want to deny a employee access
  class NoPermissionForImportError < PolicyError
    kind 'no_permission_for_import'
  end

  class DeactivatedFirmAccessError < PolicyError
    kind 'deactivated_firm_access'
  end

  class InvalidSubscriptionError < PolicyError
    kind 'invalid_subscription'
  end

  class SealedOrganizerAccessError < PolicyError
    kind 'sealed_organizer'
  end

  class IncompletedOrganizerAccessError < PolicyError
    kind 'incomplette_organizer'
  end

  class NoPermissionForRemovingFirm < PolicyError
    kind 'forbidden'
  end

  class NoPermissionForDeactivatingFirm < PolicyError
    kind 'forbidden'
  end

  class << self
    def authorize!(user, actor, ability, resource = nil, options = {})
      new(user, actor, resource, options).authorize!(ability)
    end

    def authorize(user, actor, ability, resource = nil, options = {})
      new(user, actor, resource, options).result(ability)
    end

    def authorized?(user, actor, ability, resource = nil, options = {})
      new(user, actor, resource, options).authorized?(ability)
    end
    alias can? authorized?
  end

  def initialize(user, actor, resource = nil, options = {})
    @user = user
    @actor = actor
    @resource = resource
    @options = options
  end

  def deny(reason:, exception_class_name: 'AbstractPolicy::UnauthorizedAccessError')
    Result.deny(reason: reason, exception_class_name: exception_class_name)
  end

  def default_deny
    deny reason: I18n.t('policies.abstract_policy.action_forbidden'), exception_class_name: 'AbstractPolicy::ForbiddenAccessError'
  end

  def deny_on_read_only_mode
    deny reason: I18n.t('policies.abstract_policy.read_only'), exception_class_name: 'AbstractPolicy::ReadOnlyAccessError'
  end

  def deny_on_import
    deny reason: I18n.t('policies.abstract_policy.cant_import_clients'), exception_class_name: 'AbstractPolicy::NoPermissionForImportError'
  end

  def deny_on_sealed_document
    deny reason: I18n.t('policies.abstract_policy.you_cant_edit_document'), exception_class_name: 'AbstractPolicy::SealedDocumentAccessError'
  end

  def deny_on_sealed_directory
    deny reason: I18n.t('policies.abstract_policy.you_cant_edit_directory'), exception_class_name: 'AbstractPolicy::SealedDirectoryAccessError'
  end

  def deny_on_sealed_organizer
    deny reason: I18n.t('policies.abstract_policy.you_cant_edit_organizer'), exception_class_name: 'AbstractPolicy::SealedOrganizerAccessError'
  end

  def deny_on_quickbooks_connection
    deny reason: I18n.t('policies.abstract_policy.you_cant_change_quickbooks_connection')
  end

  def deny_on_incompleted_organizer
    deny reason: I18n.t('policies.abstract_policy.you_cant_complette_organizer'), exception_class_name: 'AbstractPolicy::IncompletedOrganizerAccessError'
  end

  def deny_on_archived_account
    deny reason: I18n.t('policies.abstract_policy.account_archived'), exception_class_name: 'AbstractPolicy::ArchivedAccountAccessError'
  end

  def accept
    Result.accept
  end

  def result(ability)
    return accept if admin? || logged_in_from_admin? || system?

    send("can_#{ability}?")
  end

  def authorized?(ability)
    result(ability).value
  end
  alias can? authorized?

  def authorize!(ability)
    result = result(ability)

    raise result.exception unless result.successful?
  end

  def resource_id
    resource.id if resource.present?
  end

  private

  attr_reader :user, :resource, :actor, :options

  def admin?
    actor.admin?
  end

  def system?
    actor.system?
  end

  def editor?
    actor.editor?
  end

  def firm_member?
    owner? || (employee? || editor_logged_in_as_employee?)
  end

  def owner?
    return false if logged_in_from_editor?
    actor.owner?
  end

  def firm_admin?
    return false if logged_in_from_editor?
    actor.firm_admin?
  end

  def firm_manager?
    owner? || firm_admin?
  end

  def employee?
    return false if logged_in_from_editor?
    actor.employee?
  end

  def regular_employee?
    return false if logged_in_from_editor?
    actor.employee? && !firm_admin?
  end

  def client?
    return false if logged_in_from_editor?
    actor.client?
  end

  def access_rights
    actor.access_rights
  end

  def creator?
    if enumerable_resource?
      resource.all? { |r| r.creator_id == actor.id && r.creator_type = actor.class.name }
    else
      resource.creator_id == actor.id && resource.creator_type == actor.class.name
    end
  end

  def same_firm?
    if enumerable_resource?
      resource.all? { |r| user.firm_id == r.user.firm_id }
    else
      user.firm_id == resource.user.firm_id
    end
  end

  def same_entity?
    actor == resource
  end

  def queryable_resource?
    resource.respond_to? :where
  end

  def enumerable_resource?
    resource.respond_to? :all?
  end

  def logged_in_as_another_user?
    LoginAsAnotherUser.logged_in_as_another_user?
  end

  def owner_logged_in_as_employee?
    LoginAsAnotherUser.logged_in_from_owner? && actor.employee?
  end

  def firm_admin_logged_in_as_employee?
    LoginAsAnotherUser.logged_in_from_firm_admin? && actor.employee?
  end

  def logged_in_from_admin?
    LoginAsAnotherUser.logged_in_from_admin?
  end

  def logged_in_from_editor?
    LoginAsAnotherUser.logged_in_from_editor?
  end

  def editor_logged_in_as_owner?
    logged_in_from_editor? && actor.owner?
  end

  def editor_logged_in_as_employee?
    logged_in_from_editor? && actor.employee?
  end

  def editor_logged_in_as_firm_admin?
    logged_in_from_editor? && actor.firm_admin?
  end

  def update_params_allowed?(update_params, allowed_keys)
    return true if update_params.blank?
    return true if (update_params.keys.map(&:to_sym) - allowed_keys).blank?
    false
  end
end

