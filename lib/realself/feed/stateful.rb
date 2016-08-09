module RealSelf
  module Feed
    module Stateful

      attr_accessor :mongo_db

      MAX_UNREAD_COUNT = 2147483647.freeze
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze
      SESSION_EXPIRE_AFTER_SECONDS = 60 * 30.freeze # 30 minutes

      ##
      # create indexes on the state collection if necessary
      #
      # @param [String] owner_type  The type of object that owns the feed
      # @param [true | false]       Create the index in the background
      def ensure_index(owner_type, background: true)
        super if defined?(super)

        collection = state_collection(owner_type)

        collection.indexes.create_one(
          {:owner_id => Mongo::Index::DESCENDING},
          :unique => true, :background => background)
      end

      ##
      # Retrieve all available states for this user
      #
      # @param [ Objekt ] owner The owner of a state
      def get_state(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id}
          ).limit(1)

          result.first ||  {"owner_id" => owner.id}
      end

      private

      ##
      # Execute the mongo update
      def state_do_update(owner, query, update)
        begin
          state_collection(owner.type)
            .find_one_and_update(query, update, {:upsert => true, :return_document => :after})
        rescue Mongo::Error::OperationFailure => ex
          raise ex unless ex.message =~ /#{self.class::MONGO_ERROR_DUPLICATE_KEY}/
        end
      end


      ##
      # Get the mongo collection object
      def state_collection(owner_type)
        @mongo_db.collection("#{owner_type}.#{self.class::FEED_NAME}.state")
      end


      ##
      # set up consts for containing feed class
      def self.included(other)
        other.const_set('MAX_FEED_SIZE', MAX_UNREAD_COUNT) unless defined? other::MAX_FEED_SIZE
        other.const_set('MONGO_ERROR_DUPLICATE_KEY', MONGO_ERROR_DUPLICATE_KEY) unless defined? other::MONGO_ERROR_DUPLICATE_KEY
        other.const_set('SESSION_EXPIRE_AFTER_SECONDS', SESSION_EXPIRE_AFTER_SECONDS) unless defined? other::SESSION_EXPIRE_AFTER_SECONDS
        other.class_eval do
          include State::UnreadCountable
          include State::Bookmarkable
          include State::Sessioned
        end
      end
    end
  end
end


