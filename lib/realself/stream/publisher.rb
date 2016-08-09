require 'bunny'
require 'connection_pool'

module RealSelf
  module Stream

    class PublisherError < StandardError; end

    class Publisher
      MAX_CONNECTION_RETRY = 3

      def initialize(config, exchange_name, channel_pool_size=16)
        @channel_pool_size  = channel_pool_size
        @exchange_name      = exchange_name
        @mutex              = Mutex.new
        @rmq_config         = config

        # This publisher is designed to support threading.
        # Running with this set to true is the RMQ default.
        # Using this flag in a non-threaded environment is
        # benign.  But it MUST be set to true in threaded
        # environments.  Just be safe and set it to true
        # in all cases.
        RealSelf::logger.warn 'Overriding :threaded config for Bunny' unless @rmq_config[:threaded] = true
        @rmq_config[:threaded] = true
      end


      def publish items, content_type = 'application/json'
        items = [*items]

        tries ||= 1

        @mutex.synchronize do
          ensure_connection! unless connected?
        end

        # scoped at this level to allow access
        # from rescue block
        activity = nil

        # get a channel from the pool (threadsafe)
        @channel_pool.with do |channel|
          # put channel in publish confirm mode
          channel.confirm_select

          # get the exchange to use with this channel
          # note - this method does not initiate network traffic
          exchange  = channel.topic(@exchange_name, :durable => true)

          # publish the items
          items.each do |item|
            activity = item

            exchange.publish(
              item.to_s,
              :content_type => content_type.to_s,
              :message_id   => item.hash,
              :persistent   => true,
              :routing_key  => item.prototype.to_s)
          end

          # block until all confirms are returned
          channel.wait_for_confirms

          # check for nacks
          # nacked_set returns Set containg the hash code of
          # any messages that failed to publish. Go find
          # the original item based on the hash code and
          # log it as an error.
          nacks = channel.nacked_set

          nacks.each do |nack|
            failed_item = items.find { |item| item.hash == nack }
            RealSelf::logger.error("Failed to confirm publish for item.  activity=#{failed_item.to_s}")
          end

          # raise an error if anything failed
          unless nacks.empty?
            raise PublisherError, "Failed to confirm #{nacks.count} published items."
          end
        end

      rescue ::Bunny::NetworkFailure, ::Bunny::NetworkErrorWrapper => nfe

        # invalidate the connection and channels
        @publisher_session = nil

        if tries <= MAX_CONNECTION_RETRY

          RealSelf::logger.warn "#{nfe.class.name} error detected.  Attempting reconnection #{tries}/#{MAX_CONNECTION_RETRY}"

          sleep tries # wait a little longer between each attempt

          tries += 1

          retry

        else

          RealSelf::logger.error "#{nfe.class.name} detected.  Exhausted #{MAX_CONNECTION_RETRY} attempts.\n#{nfe.message}\n#{nfe.backtrace}"

          raise nfe
        end

      rescue Timeout::Error => te

        RealSelf::logger.error "Timeout encountered while publishing #{items.length} items.  activity=#{activity}"

        # invalidate the connection and channels before allowing
        # the error to bubble up
        @publisher_session = nil

        raise te
      end


      private


      def ensure_connection!
        # start a new connection
        @publisher_session  ||= Bunny.new(symbolize_keys(@rmq_config))
        @publisher_session.start

        @channel_pool = ConnectionPool.new(size: @channel_pool_size) do
          @publisher_session.create_channel
        end
      end


      def connected?
        @publisher_session && @publisher_session.connected?
      end


      def symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        }
      end
    end
  end
end
