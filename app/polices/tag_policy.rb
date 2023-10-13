# frozen_string_literal: true

class TagPolicy < AbstractPolicy

  def can_create?
    #TODO: make me

    default_deny
  end

  def can_update?
    return accept if editor_logged_in_as_owner?
    return accept if editor_logged_in_as_employee? && access_rights.manage_tags
    return deny_on_read_only_mode if logged_in_as_another_user?
    return accept if firm_manager?
    return accept if employee? && access_rights.manage_tags

    default_deny
  end

  def can_destroy?
    return accept if editor_logged_in_as_owner?
    return accept if editor_logged_in_as_employee? && access_rights.manage_tags
    return deny_on_read_only_mode if logged_in_as_another_user?
    return accept if firm_manager?
    return accept if employee? && access_rights.manage_tags

    default_deny
  end

  private

  def same_firm?
    if enumerable_resource?
      resource.all? { |r| user.firm_id == r.firm_id }
    else
      user.firm_id == resource.firm_id
    end
  end
end

