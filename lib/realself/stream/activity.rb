module RealSelf
  module Stream
    class Activity

      UUID_REGEX = /^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/
      VERSION    = 2

      attr_reader :title, :published, :actor, :verb, :object, :target, :extensions, :uuid, :prototype, :version

      alias :owner :actor


      def self.from_hash hash
        title       = hash[:title]
        published   = DateTime.parse hash[:published].to_s
        prototype   = hash[:prototype] || nil
        actor       = Objekt.from_hash hash[:actor]
        verb        = hash[:verb].to_s
        object      = Objekt.from_hash hash[:object]
        target      = Objekt.from_hash hash[:target] if hash[:target]
        uuid        = hash[:uuid] || SecureRandom.uuid
        extensions  = {}

        hash[:extensions].each do |key, val|
          extensions[key.to_sym] = Objekt.from_hash val
        end if hash[:extensions]

        Activity.new title, published, actor, verb, object, target, extensions, uuid, prototype
      end


      def self.from_json json, validate = true
        JSON::Validator.validate!(schema, json) if validate

        hash = MultiJson.decode json, { :symbolize_keys => true }

        from_hash hash
      end


      def self.schema
        unless @schema
          schema_file = File.join(File.dirname(__FILE__), 'activity-schema.json')
          @schema     = MultiJson.decode File.open(schema_file)
        end

        @schema
      end


      def initialize title, published, actor, verb, object, target = nil, extensions = {}, uuid = SecureRandom.uuid, prototype = nil
        raise ArgumentError, "Invalid UUID #{uuid}" unless uuid.match UUID_REGEX

        @version    = VERSION
        @title      = title.to_s
        @published  = published.to_datetime
        @actor      = actor
        @verb       = verb.to_s
        @object     = object
        @target     = target
        @extensions = extensions ? extensions.to_hash : {}
        @uuid       = uuid.to_s
        @prototype  = prototype ? prototype.to_s : "#{actor.type.to_s}.#{verb.to_s}.#{object.type.to_s}"
      end


      def == other
        other.kind_of?(Activity) and to_h == other.to_h
      end

      alias :eql? :==


      def content_type
        ContentType::ACTIVITY
      end


      def hash
        to_h.hash
      end


      def to_h
        extensions = {}
        @extensions.each do |key, obj|
          extensions[key.to_sym] = obj.to_h
        end

        hash = {
          :title      => @title,
          :published  => @published,
          :actor      => @actor.to_h,
          :verb       => @verb,
          :object     => @object.to_h,
          :extensions => extensions,
          :uuid       => @uuid.to_s,
          :prototype  => @prototype.to_s,
          :version    => VERSION
        }

        # target is optional
        hash[:target] = @target.to_h if @target

        hash
      end

      alias :to_hash :to_h


      def to_s
        MultiJson.encode to_h
      end

      alias :to_string :to_s

    end
  end
end
