module RealSelf
  module Stream
    class FollowedActivity
      VERSION    = 2

      attr_reader :title, :published, :actor, :verb, :object, :target, :extensions, :uuid, :prototype, :version

      alias :owner :actor


      def self.from_hash hash
          title       = hash[:title]
          published   = DateTime.parse hash[:published].to_s
          prototype   = hash[:prototype] || nil
          actor       = FollowedObjekt.from_hash hash[:actor]
          verb        = hash[:verb].to_s
          object      = FollowedObjekt.from_hash hash[:object]
          target      = FollowedObjekt.from_hash hash[:target] if hash[:target]
          uuid        = hash[:uuid] || SecureRandom.uuid
          extensions  = {}

          hash[:extensions].each do |key, val|
            extensions[key.to_sym] = FollowedObjekt.from_hash val
          end if hash[:extensions]

          return FollowedActivity.new title, published, actor, verb, object, target, extensions, uuid, prototype
      end


      def self.from_json json, validate = true
        JSON::Validator.validate!(schema, json) if validate

        hash = MultiJson.decode json, { :symbolize_keys => true }

        from_hash hash
      end


      def self.schema
        unless @schema
          schema_file = File.join(File.dirname(__FILE__), 'followed-activity-schema.json')
          @schema     = MultiJson.decode File.open(schema_file)
        end

        @schema
      end


      def initialize title, published, actor, verb, object, target, extensions, uuid, prototype
        raise ArgumentError, "Invalid UUID #{uuid}" unless uuid.match Activity::UUID_REGEX

        @version    = VERSION
        @title      = title.to_s
        @published  = published.to_datetime
        @actor      = actor
        @verb       = verb.to_s
        @object     = object
        @target     = target
        @extensions = extensions.to_hash
        @uuid       = uuid.to_s
        @prototype  = prototype ? prototype.to_s : "#{actor.type.to_s}.#{verb.to_s}.#{object.type.to_s}"
      end


      def == other
        other.kind_of?(FollowedActivity) and to_h == other.to_h
      end

      alias :eql? :==


      def content_type
        ContentType::FOLLOWED_ACTIVITY
      end


      def hash
        to_h.hash
      end


      # yeields follower, reason
      def map_followers

        activity = self.to_activity

        # actor
        actor_objekt = self.actor.to_objekt
        yield actor_objekt, actor_objekt

        # actor followers
        if self.actor.followers
          self.actor.followers.each do |follower|
            yield follower, actor_objekt
          end
        end

        # object
        object_objekt = self.object.to_objekt
        yield object_objekt, object_objekt

        # object followers
        if self.object.followers
          self.object.followers.each do |follower|
            yield follower, object_objekt
          end
        end

        # target
        if self.target
          target_objekt = self.target.to_objekt
          yield target_objekt, target_objekt

          # target followers
          if self.target.followers
            self.target.followers.each do |follower|
              yield follower, target_objekt
            end
          end
        end

        # extensions
        if self.extensions
          self.extensions.each_value do |obj|
            extension_objekt = obj.to_objekt

            yield extension_objekt, extension_objekt

            if obj.followers
              obj.followers.each do |follower|
                yield follower, extension_objekt
              end
            end
          end
        end
      end # map_followers


      def to_activity
        title     = self.title
        published = self.published
        actor     = Objekt.new @actor.type, @actor.id
        verb      = self.verb
        object    = Objekt.new @object.type, @object.id
        target    = Objekt.new @target.type, @target.id if @target
        uuid      = self.uuid
        prototype = self.prototype

        extensions = {}
        @extensions.each do |key, obj|
          extensions[key.to_sym] = obj.to_objekt
        end

        return Activity.new title, published, actor, verb, object, target, extensions, uuid, prototype
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
