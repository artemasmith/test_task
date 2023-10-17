# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V1::Firm::TagsController, type: :request do
  let(:firm) { create :firm }
  let(:owner) { firm.owner }
  let(:attrs) { attributes_for(:tag) }
  let(:tag) { create :tag, firm: firm }

  describe 'GET /' do
    def perform
      get api_v1_firm_tags_url(subdomain: firm.subdomain)
    end

    shared_examples 'success' do
      it 'should load firm tags' do
        perform
        expect(response).to be_successful
      end
    end

    context 'when owner login' do
      before { login_as owner.user }

      it_behaves_like 'success'
    end

    context 'when employee login' do
      let(:employee) { create :employee, firm: firm }

      before { login_as employee.user }

      it_behaves_like 'success'
    end

    context 'when client login' do
      before { login_as client.user }

      context 'same firm' do
        let(:client) { create :client, firm: firm }

        it_behaves_like 'success'
      end

      context 'other firm' do
        let(:client) { create :client }

        it 'should not load firm tags' do
          perform

          expect(response).not_to be_successful
          expect(response.status).to eq(403)
          expect(response.parsed_body.dig('errors', 'general', 'reason')).to eq('forbidden')
        end
      end
    end
  end

  describe 'POST /' do
    def perform
      post api_v1_firm_tags_url(subdomain: firm.subdomain), params: {tag: attrs}
    end

    shared_examples 'success' do
      it 'should create tag for firm' do
        perform
        expect(response).to be_successful
      end
    end

    context 'when owner login' do
      before { login_as owner.user }

      it_behaves_like 'success'
    end

    context 'when employee login' do
      before { login_as employee.user }

      context 'without permissions' do
        let(:employee) { create :employee, firm: firm }

        it 'should not create tag' do
          perform

          expect(response).not_to be_successful
          expect(response.status).to eq(403)
          expect(response.parsed_body.dig('errors', 'general', 'reason')).to eq('forbidden')
        end
      end

      context 'with permissions' do
        let(:employee) { create :employee, firm: firm, can_create_tags: true }

        it_behaves_like 'success'
      end
    end

    context 'when manager login' do
      let(:firm_admin) { firm.admin }

      before { login_as firm_admin.user }

      it_behaves_like 'success'
    end
  end

  describe 'PATCH /' do
    context 'when owner login' do
      before { login_as owner.user }

      it 'update' do
        tag = create :tag, firm: firm
        new_name = generate :name

        patch api_v1_firm_tag_url(subdomain: firm.subdomain, id: tag.id), params: {name: new_name}
        expect(response).to be_successful
      end
    end
  end
end