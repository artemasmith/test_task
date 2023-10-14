# frozen_string_literal: true

module Api
  module V1
    module Firm
      module Tags
        class IndexSerializer < BaseSerializer
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
      end
    end
  end
end
