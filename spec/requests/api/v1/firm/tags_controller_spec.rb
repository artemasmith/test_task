# frozen_string_literal: true

require 'spec_helper'

# disabled example
# RSpec.describe Api::V1::Firm::TagsController, type: :request do
#   let(:firm) { create :firm }
#   let(:owner) { firm.owner }
#   let(:attrs) { attributes_for(:tag) }
#   let(:tag) { create :tag, firm: }
#
#   before do
#     login_as owner.user
#   end
#
#   it 'update' do
#     tag = create(:tag, firm:)
#     new_name = generate :name
#
#     patch api_v1_firm_tag_url(subdomain: firm.subdomain, id: tag.id), params: { name: new_name }
#     expect(response).to be_successful
#   end
#
#   it 'should load firm tags' do
#     get api_v1_firm_tags_url(subdomain: firm.subdomain)
#     expect(response).to be_successful
#   end
#
#   it 'should not create tag when there are no permissions' do
#     employee = create(:employee, firm:)
#     login_as employee.user
#
#     post api_v1_firm_tags_url(subdomain: firm.subdomain), params: { tag: attrs }
#
#     expect(response).not_to be_successful
#     expect(response.status).to eq(403)
#     expect(response.parsed_body.dig('errors', 'general', 'reason')).to eq('forbidden')
#   end
#
#   it 'should create tag for firm' do
#     post api_v1_firm_tags_url(subdomain: firm.subdomain), params: { tag: attrs }
#     expect(response).to be_successful
#   end
# end
