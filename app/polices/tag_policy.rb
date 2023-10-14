# frozen_string_literal: true

class TagPolicy < AbstractPolicy
  # Создавать тэги может только FirmOwner, FirmManager, Emplyee c правами access_rights.can_create_tags
  def can_create?
    return accept if editor_logged_in_as_owner?
    return accept if editor_logged_in_as_firm_admin?
    return accept if editor_logged_in_as_employee? && access_rights.manage_tags

    default_deny
  end

  # Считаем, что читать может FirmOwner, FirmManager, FirmMember или Сlient, если они в этой фирме (same_firm? == true)
  def can_read?
    return accept if firm_member? && same_firm?
    return accept if editor_logged_in_as_owner? && same_firm?
    return accept if editor_logged_in_as_firm_admin? && same_firm?
    return accept if editor_logged_in_as_employee? && same_firm?
    return accept if client? && same_firm?

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
