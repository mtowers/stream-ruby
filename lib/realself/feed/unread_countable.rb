module RealSelf
  module Feed
    module UnreadCountable

      attr_accessor :mongo_db

      MAX_UNREAD_COUNT = 2147483647.freeze
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze


      ##
      # Decrement the unread count by 1 for the feed owner in the containing feed
      # Decrement will not cause the unread count to go below zero
      #
      # @param [Objekt] The user whose unread count is being changed
      def decrement_unread_count(owner)
        result = unread_count_do_update(
          owner,
          {
            :owner_id => owner.id,
            :count => { :'$gt' => 0 }
          },
          {
            :'$inc' => { :count => -1 }
          })

        # if the update failed, assume the unread count is already at
        # zero, so return that.
        result ? result : {:owner_id => owner.id, :count => 0}
      end


      ##
      # create indexes on the unread count collection if necessary
      #
      # @param [String] owner_type  The type of object that owns the feed
      # @param [true | false]       Create the index in the background
      def ensure_index(owner_type, background: true)
        super if defined?(super)

        collection = unread_count_collection(owner_type)

        collection.indexes.create_one(
          {:owner_id => Mongo::Index::DESCENDING},
          :unique => true, :background => background)
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
          :count => {
            :'$gte' => min_unread_count
          }
        }

        result = unread_count_collection(owner_type).find(query)
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
      # @return [Hash] {:owner_id => [owner.id], :count => 0}
      def get_unread_count(owner)
        result = unread_count_collection(owner.type).find(
          {:owner_id => owner.id},
          {:fields => {:_id => 0}}
        ).limit(1)

        result.first ||  {:owner_id => owner.id, :count => 0}
      end


      ##
      # Increment the unread count by 1 for the feed owner in the containing feed
      # up to MAX_FEED_SIZE if specified or 2147483647
      #
      # @param [Objekt] The user whose unread count is being changed
      def increment_unread_count(owner)
        result = unread_count_do_update(
          owner,
          {
            :owner_id => owner.id,
            :count => { :'$lt' => self.class::MAX_FEED_SIZE }
          },
          {:'$inc' => {:count => 1}})

        # if the update failed, assume the unread count is already at
        # the max value so return that.
        result ? result : {:owner_id => owner.id, :count => self.class::MAX_FEED_SIZE}
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
        result = unread_count_do_update(
          owner,
          {:owner_id => owner.id},
          {
            # keep the unread count between 0 and max feed size
            :'$set' => { :count => [[0, count].max, self.class::MAX_FEED_SIZE].min }
          })

        # if the update failed, assume the unread count is already at the passed value
        result ? result : {:owner_id => owner.id, :count => count}
      end


      private


      ##
      # Execute the mongo update
      def unread_count_do_update(owner, query, update)
        begin
          unread_count_collection(owner.type)
            .find_one_and_update(query, update, {:upsert => true, :return_document => :after})
        rescue Mongo::Error::OperationFailure => ex
          raise ex unless ex.message =~ /#{self.class::MONGO_ERROR_DUPLICATE_KEY}/
        end
      end


      ##
      # Get the mongo collection object
      def unread_count_collection(owner_type)
        @mongo_db.collection("#{owner_type}.#{self.class::FEED_NAME}.unread_count")
      end


      ##
      # set up consts for containing feed class
      def self.included(other)
        other.const_set('MAX_FEED_SIZE', MAX_UNREAD_COUNT) unless defined? other::MAX_FEED_SIZE
        other.const_set('MONGO_ERROR_DUPLICATE_KEY', MONGO_ERROR_DUPLICATE_KEY) unless defined? other::MONGO_ERROR_DUPLICATE_KEY
      end
    end
  end
end
