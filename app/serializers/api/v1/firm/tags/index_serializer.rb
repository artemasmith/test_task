# frozen_string_literal: true

class Api::V1::Firm::Tags::IndexSerializer < BaseSerializer
  extend HashSerializer
  extend HasMetaSerializer
  extend IncludesSerializer

  class MetaSerializer < Base::MetaSerializer
    extend HashSerializer

    attributes :total_count, :total_pages, :current_page
  end

  class TagSerializer < Base::TagSerializer
    def color
      object.old_color
    end
  end

  has_many :tags, serializer: TagSerializer

  hash_attributes :tags, :meta
  includes_has_meta :meta, serializer: MetaSerializer
end

