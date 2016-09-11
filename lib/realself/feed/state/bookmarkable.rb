module RealSelf
  module Feed
    module State
      module Bookmarkable
        TOP_LEVEL_KEY = :bookmarks
        DEFAULT_BOOKMARK_KEY = :position
        ##
        # Retrieve bookmark position of a user
        #
        # @param [ Objekt ] the owner of the bookmark
        # @param [ Symbol/String ] the key of a bookmark
        #
        # @returns [ BSON::ObjectId ] The position expressed as a ObjectId. nil if no bookmark
        def get_bookmark(owner, key=DEFAULT_BOOKMARK_KEY)
          field_key = "#{TOP_LEVEL_KEY}.#{key}".to_sym
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, field_key => 1}}
          ).limit(1)

          result.first && result.first[TOP_LEVEL_KEY] ? result.first[TOP_LEVEL_KEY][key] : nil
        end

        ##
        # Place a bookmark position of a user
        #
        # @param [ Objekt ] the owner of the bookmark
        # @param [ Symbol/String ] the key of the bookmark
        # @param [ BSON::ObjectId ] the position to place the bookmark
        #
        # @returns [ BSON::ObjectId ] The position that has been set
        def set_bookmark(owner, position, key=DEFAULT_BOOKMARK_KEY)
          raise(
            FeedError,
            "Illegal position: #{position}. Position must be a legal BSON::ObjectId"
          ) unless position.is_a?(BSON::ObjectId) and BSON::ObjectId.legal?(position)

          field_key = "#{TOP_LEVEL_KEY}.#{key}".to_sym
          result = state_do_update(
            owner,
            {
            :owner_id => owner.id
          },
            {
            :'$set' => {field_key => position}
          })

          position
        end

        ##
        # Remove a bookmark position of a user
        def remove_bookmark(owner, key=DEFAULT_BOOKMARK_KEY)
          field_key = "#{TOP_LEVEL_KEY}.#{key}".to_sym
          state_do_update(owner, {:owner_id => owner.id}, {:'$unset' => {field_key => ""}})
        end
      end
    end
  end
end
