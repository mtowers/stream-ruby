module RealSelf
  module Feed
    class Ttl < Permanent

      attr_accessor :mongo_db


      ##
      # create indexes on the feed if necessary
      #
      # @param [String] owner_type  The type of object that owns the feed
      # @param [true | false]       Create the index in the background
      def ensure_index(owner_type, background: true)
        super if defined?(super)

        collection = get_collection(owner_type)

        collection.indexes.create_many([
          {
            :key          => {:'activity.published' => Mongo::Index::DESCENDING},
            :background   => background,
            :expire_after => self.class::FEED_TTL_SECONDS
          }
        ])
      end
    end
  end
end
