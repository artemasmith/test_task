# frozen_string_literal: true

require_relative '../../app/polices/abstract_policy'
require_relative '../../app/polices/tag_policy'
require_relative '../support/user_base'
require_relative '../support/resource'
require_relative '../support/result'
require_relative '../support/login_as_another_user'

# just to not load entire I18n gem
class I18n
  def self.t(message)
    message
  end
end

RSpec.describe TagPolicy do
  describe 'check policies' do
    let(:user) { UserBase.new(role, firm_id, access_rights) }
    let(:policy) { TagPolicy.new(user, actor, resource, options) }
    let(:resource) { Resource.new(firm_id) }

    # testing existing functionality
    context 'Can update?' do
      subject { policy.can_update? }

      context 'when firm owner' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'owner' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end
      end

      context 'when employee' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'employee' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'when have no rights' do
          let(:access_rights) { { can_manage_tags: false } }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end
      end
    end

    # actual tests
    context 'Can create?' do
      subject { policy.can_create? }

      context 'when firm owner' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'owner' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end
      end

      context 'when firm Manager' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'firm_admin' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end
      end

      context 'when employee' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'employee' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'when have no rights' do
          let(:access_rights) { { can_manage_tags: false } }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end
      end

      context 'when some one else' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'client' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: false } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq({
                                  exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                  reason: 'policies.abstract_policy.action_forbidden'
                                })
        end
      end
    end

    context 'Can read?' do
      subject { policy.can_read? }

      context 'when firm owner' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'owner' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'cant read resource of another firm' do
          let(:resource) { Resource.new(2) }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq(true)
          end
        end
      end

      context 'when firm Manager' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'firm_admin' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'cant read resource of another firm' do
          let(:resource) { Resource.new(2) }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq(true)
          end
        end
      end

      context 'when employee' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'employee' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: true } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(true)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'cant read resource of another firm' do
          let(:resource) { Resource.new(2) }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end

        context 'when not logged in from editor' do
          before do
            allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
          end

          it do
            expect(subject).to eq(true)
          end
        end
      end

      context 'when some one else' do
        let(:actor) { user }
        let(:options) { nil }
        let(:role) { 'client' }
        let(:firm_id) { 1 }
        let(:access_rights) { { can_manage_tags: false } }

        before do
          allow(LoginAsAnotherUser).to receive(:logged_in_from_editor?).and_return(false)
        end

        it do
          expect(subject).to eq(true)
        end

        context 'cant read resource of another firm' do
          let(:resource) { Resource.new(2) }

          it do
            expect(subject).to eq({
                                    exception_class_name: 'AbstractPolicy::ForbiddenAccessError',
                                    reason: 'policies.abstract_policy.action_forbidden'
                                  })
          end
        end
      end
    end
  end
end
