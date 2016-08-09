module RealSelf
  module Feed
    module State
      module Sessioned

        ##
        # Check if a user's session is still alive
        #
        # @param [ Objekt ] the owner of the feed
        def is_session_alive?(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :last_active => 1}}
          ).limit(1)

          !result.nil? and !result.first.nil? and BSON::ObjectId.from_time(Time.now - self.class::SESSION_EXPIRE_AFTER_SECONDS) < result.first[:last_active]
        end

        ##
        # Expires a user's session
        def expire_session(owner)
          state_do_update(owner, {:owner_id => owner.id}, {:'$unset' => {:last_active => ''}})
        end

        ##
        # Refreshes a user's session
        def touch_session(owner)
          set_action_time(owner)
        end

        private
        
        def set_action_time(owner, time: BSON::ObjectId.from_time(Time.now))
          raise(
            FeedError,
            "Illegal time: #{time}. time must be a legal BSON::ObjectId"
          ) unless BSON::ObjectId.legal?(time)

          state_do_update(
            owner,
            {
            :owner_id => owner.id
          },
            {
            :'$set' => {:last_active => time}
          })
        end
      end
    end
  end
end
