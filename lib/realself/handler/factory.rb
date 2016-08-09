module RealSelf
  module Handler
    class Factory

      @@registered_handlers   = {}
      @@registered_enclosures = {}


      def self.create(activity_prototype, content_type, constructor_params = nil)
        klasses = @@registered_handlers[content_type] ? @@registered_handlers[content_type][activity_prototype.to_s] : nil

        raise(
          HandlerFactoryError,
          "no handler registered for content type:activity prototype - #{content_type}:#{activity_prototype}"
        )if klasses.nil?

        klasses.values.map do |klass|
          constructor_params ? klass.new(**constructor_params) : klass.new
        end
      end


      def self.enclosure(queue_name)
        @@registered_enclosures[queue_name.to_s] || Handler::Enclosure
      end


      def self.register_enclosure(queue_name, enclosure)
        @@registered_enclosures[queue_name.to_s] = enclosure
      end


      def self.register_handler(activity_prototype, content_type, klass)
        @@registered_handlers[content_type] ||= {}
        @@registered_handlers[content_type][activity_prototype.to_s] ||= {}
        @@registered_handlers[content_type][activity_prototype.to_s][klass.name] = klass
      end


      def self.registered_handlers()
        names = []
        @@registered_handlers.each do |content_type, prototype_handlers|
          prototype_handlers.each do |prototype, handlers|
            handlers.keys.each do |class_name|
              names << "#{content_type} => #{prototype} => #{class_name}"
            end
          end
        end
        names
      end


      def self.registered_routing_keys(content_type)
        @@registered_handlers[content_type] ||= {}

        @@registered_handlers[content_type].keys
      end
    end


    class HandlerFactoryError < StandardError; end
  end
end
