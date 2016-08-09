module RealSelf
  module Feed
    module Getable
      FEED_DEFAULT_PAGE_SIZE = 10.freeze # default nubmer feed items to return

      ##
      # retrieve the feed
      #
      # @param [Objekt] owner         the feed owner
      # @param [Integer] count        the maximum number of items to return
      # @param [String] before        a BSON::ObjectId string
      # @param [String] after         a BSON::ObjecxtId string
      # @param [Hash] query           a hash containing a mongo query to use to filter the results
      # @param [bool] include_owner   a flag indicating that the stream item owner should be included in each stream_item returned
      # @param [Int] sort             a flag indicating sort order for stream items
      #
      # @return [Hash]          {:count => [Integer], :before => [String], :after => [String], :stream_items => [Array]}
      def get(owner, count = nil, before = nil, after = nil, query = {}, include_owner = true, sort = Mongo::Index::DESCENDING)
        collection = get_collection(owner.type) # Implemented by including class

        count ||= FEED_DEFAULT_PAGE_SIZE

        id_range                  = get_id_range_query(before, after)

        projection = (include_owner ? {} : {:object => 0})

        feed_query                = query
        feed_query[:'object.id']  = owner.id
        feed_query[:_id]          = id_range if id_range
        feed_query[:redacted]     = {:'$ne' => true}  # omit redacted items

        feed = collection.find(feed_query)
          .sort(:_id => sort)
          .limit(count)
          .projection(projection)
          .to_a

        # return the '_id' field as 'id'
        # NOTE: hashes returned from mongo use string-based keys
        feed.each do |item|
          item['id'] = item['_id'].to_s
          item.delete('_id')
        end

        # construct the standard response package
        {
          :count        => feed.length,
          :before       => before,
          :after        => after,
          :stream_items => feed
        }
      end


      private

      ##
      # get the id range clause for the mongo query
      #
      # @param [String]   A BSON ObjectID string
      # @param [String]   A BSON ObjectID string
      #
      # @returns [Hash]   A hash to use for limiting the feed query
      def get_id_range_query(before, after)
        return nil if before.nil? and after.nil?

        query = {}
        query[:'$lt'] = BSON::ObjectId.from_string(before) if before
        query[:'$gt'] = BSON::ObjectId.from_string(after) if after

        query
      end


      ##
      # check for illegal composition
      def self.included(other)
        raise(
          FeedError,'Capped feeds may not include Getable'
        ) if other.ancestors.include? RealSelf::Feed::Capped
      end
    end
  end
end
