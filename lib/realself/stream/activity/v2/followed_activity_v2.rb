require 'json-schema'
# require 'realself/stream/activity'
# require 'realself/stream/objekt'
# require 'realself/stream/followed_objekt'
# require 'realself/stream/stream_activity'

module RealSelf
  module Stream
    class FollowedActivityV2 < FollowedActivity
      VERSION = 2

      SCHEMA_FILE = File.join(File.dirname(__FILE__), 'followed-activity-schema-v2.json')

      def self.from_hash(hash)
          title = hash[:title]
          published = DateTime.parse(hash[:published])          
          actor = FollowedObjekt.from_json(MultiJson.encode(hash[:actor])) 
          verb = hash[:verb].to_s
          object = FollowedObjekt.from_json(MultiJson.encode(hash[:object]))
          target = FollowedObjekt.from_json(MultiJson.encode(hash[:target])) if hash[:target]

          extensions = {}
          hash[:extensions].each {|key, val| extensions[key.to_sym] = FollowedObjekt.from_hash(val)} if hash[:extensions]

          uuid = hash[:uuid] || SecureRandom.uuid
          prototype = hash[:prototype] || nil

          return FollowedActivityV2.new(title, published, actor, verb, object, target, extensions, uuid, prototype)        
      end

      attr_reader :title, :published, :actor, :verb, :object, :target, :extensions, :uuid, :prototype, :version

      def initialize(title, published, actor, verb, object, target, extensions, uuid = SecureRandom.uuid, prototype = nil)
        @version = VERSION
        @title = title.to_s
        @published = published.to_datetime
        @actor = actor
        @verb = verb.to_s
        @object = object
        @target = target
        @extensions = (extensions && extensions.to_hash) || {}
        @uuid = uuid.to_s
        @prototype = prototype ? prototype.to_s : "#{actor.type.to_s}.#{verb.to_s}.#{object.type.to_s}"

        self
      end

      def to_activity
        title = self.title
        published = self.published
        actor = Objekt.new(@actor.type, @actor.id)
        verb = self.verb
        object = Objekt.new(@object.type, @object.id)
        target = Objekt.new(@target.type, @target.id) if @target

        extensions = {}
        @extensions.each do |key, obj|                
          extensions[key.to_sym] = obj.to_objekt                 
        end

        uuid = self.uuid
        prototype = self.prototype

        return ActivityV2.new(title, published, actor, verb, object, target, extensions, uuid, prototype)
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

      def to_h
        extensions = {}
        @extensions.each do |key, obj|
          extensions[key.to_sym] = obj.to_h
        end

        hash = {
                :title => @title,
                :published => @published.to_s,
                :actor => @actor.to_h,
                :verb => @verb,
                :object => @object.to_h,
                :extensions => extensions,
                :uuid => @uuid.to_s,
                :prototype => @prototype.to_s,
                :version => VERSION
              }

        hash[:target] = @target.to_h unless @target.nil?
        
        hash
      end

      alias :to_hash :to_h

      def to_version(version)
        case version.to_i
        when VERSION
          return self
        when 1
          relatives = @extensions.values
          FollowedActivityV1.new(@title, @published, @actor, @verb, @object, @target, relatives, @uuid, @prototype)
        else
          raise ArgumentError, "usupported followed-activity version:  #{version.to_s}"
        end
      end
    end # FollowedActivityV1
  end # Stream
end # RealSelf