module RealSelf
  module Daemon
    module Worker

      # default worker options
      WORKER_OPTIONS = {
         :ack               => true,
         :durable           => true,
         :prefetch          => 1,
         :threads           => 1
      }.freeze


      def work_with_params message, delivery_info, metadata
        activity        = Stream::Factory.from_json self.class.content_type, message, true
        enclosure       = Handler::Factory.enclosure self.class.queue_name
        handlers        = Handler::Factory.create(
                            activity.prototype,
                            activity.content_type,
                            self.class.handler_params)

        enclosure.handle do
          handlers.each do |h|
            RealSelf.logger.info "#{h.class.name} handling #{activity.prototype}, UUID: #{activity.uuid}, owner: #{activity.owner.type}:#{activity.owner.id}"
            h.handle activity
          end
        end
      end


      module ClassMethods
        attr_reader   :configured, :content_type, :handler_params

        def configure(exchange_name:, queue_name:, enclosure: nil, handler_params: {}, enable_retry: false, worker_options: {})
          @handler_params = handler_params

          Handler::Factory.register_enclosure(queue_name, enclosure)

          worker_options = WORKER_OPTIONS.merge(worker_options)

          worker_options[:exchange]    = exchange_name
          worker_options[:routing_key] = Handler::Factory.registered_routing_keys(self.content_type)

          # warn when no handlers registered for content type
          RealSelf.logger.warn("No registered handlers found for content_type: #{self.content_type}, Worker: #{self.class.name}") if worker_options[:routing_key].empty?

          # enable DLX with default name if requested
          worker_options.merge!(
            :arguments   => {:'x-dead-letter-exchange' => "#{queue_name}-retry"}
          ) if enable_retry

          # sneakers queue configuration
          from_queue queue_name, worker_options

          @configured = true
        end
      end

      def self.included(other)
        other.extend ClassMethods
      end
    end
  end
end
