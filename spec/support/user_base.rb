# frozen_string_literal: true

class UserBase
  class AccessRights
    def initialize(access_rights)
      @can_manage_tags = access_rights[:can_manage_tags] || false
    end

    def manage_tags
      true if @can_manage_tags
    end
  end

  def initialize(role, firm_id, access_rights)
    @role = role
    @firm_id = firm_id
    @access_rights = access_rights
  end

  attr_reader :firm_id

  def owner?
    @role == 'owner'
  end

  def employee?
    @role == 'employee'
  end

  def firm_admin?
    @role == 'firm_admin'
  end

  def client?
    @role == 'client'
  end

  def access_rights
    AccessRights.new(@access_rights)
  end
end
