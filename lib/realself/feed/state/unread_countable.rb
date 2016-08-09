module RealSelf
  module Feed
    module State
      module UnreadCountable

        ##
        # Decrement the unread count by 1 for the feed owner in the containing feed
        # Decrement will not cause the unread count to go below zero
        #
        # @param [Objekt] The user whose unread count is being changed
        def decrement_unread_count(owner)
          result = state_do_update(
            owner,
            {
            :owner_id => owner.id,
            :unread_count => { :'$gt' => 0 }
          },
            {
            :'$inc' => { :unread_count => -1 }
          })

          # if the update failed, assume the unread count is already at
          # zero, so return that.
          result ? result : {:owner_id => owner.id, :unread_count => 0}
        end


        ##
        # Find objects with greater than a specified number of unread items in the feed
        #
        # @param [String] owner_type    The type of object that owns the feed (e.g. 'user')
        # @param [int] min_unread_count (optional) The minimum number of unread items the object must have.  default = 1
        # @param [int] limit            (optional) The maximum number of records to return
        # @param [String] last_id       (optional) The document ID of the last item in the previous page. default = nil
        #
        # @return [Array] An array of hashes [{'id' : [document id], 'owner_id': [id], 'count': [count]}]
        def find_with_unread(owner_type, min_unread_count = 1, limit = 100, last_id = nil)
          object_id = last_id || '000000000000000000000000'

          query = {
            :_id => {
            :'$gt' => BSON::ObjectId.from_string(object_id)
          },
            :unread_count => {
            :'$gte' => min_unread_count
          }
          }

          result = state_collection(owner_type).find(query)
          .limit(limit)
          .to_a

          # return the '_id' field as 'id'
          # NOTE: hashes returned from mongo use string-based keys
          result.each do |item|
            item['id'] = item['_id'].to_s
            item.delete('_id')
          end

          result
        end


        ##
        # Retrieve the number of unread items for the current feed and owner
        #
        # @param [Objekt] The feed owner
        #
        # @return [Hash] {:owner_id => [owner.id], :unread_count => 0}
        def get_unread_count(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :unread_count => 1}}
          ).limit(1)

          result.first ||  {:owner_id => owner.id, :unread_count => 0}
        end


        ##
        # Increment the unread count by 1 for the feed owner in the containing feed
        # up to MAX_FEED_SIZE if specified or 2147483647
        #
        # @param [Objekt] The user whose unread count is being changed
        def increment_unread_count(owner)
          result = state_do_update(
            owner,
            {:'$or' => [
              {:owner_id => owner.id,
              :unread_count => { :'$lt' => self.class::MAX_FEED_SIZE }
            },
              {:owner_id => owner.id,
               :unread_count => { :'$exists' => false }
            }]},
            {:'$inc' => {:unread_count => 1},
             :'$setOnInsert' => {:owner_id => owner.id}}
          )

          # if the update failed, assume the unread count is already at
          # the max value so return that.
          result ? result : {:owner_id => owner.id, :unread_count => self.class::MAX_FEED_SIZE}
        end


        ##
        # Resets the unread count to 0 for the feed owner in the containing feed
        #
        # @param [Objekt] The user whose unread count is being changed
        def reset_unread_count(owner)
          set_unread_count(owner, 0)
        end


        ##
        # Set the unread count to a specific value for the feed owner in the containig feed
        # Specifying values < 0 will cause the unread count to get set to 0.
        # Specifying values greater than MAX_FEED_SIZE will cause the unread count
        # to get set to MAX_FEED_SIZE
        #
        # @param [Objekt] The user whose unread count is being changed
        def set_unread_count(owner, count)
          result = state_do_update(
            owner,
            {:owner_id => owner.id},
            {
            # keep the unread count between 0 and max feed size
            :'$set' => { :unread_count => [[0, count].max, self.class::MAX_FEED_SIZE].min }
          })

          # if the update failed, assume the unread count is already at the passed value
          result ? result : {:owner_id => owner.id, :unread_count => count}
        end
      end
    end
  end
end
