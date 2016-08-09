module RealSelf
  module Stream
    class FollowedObjekt < Objekt

      def self.from_json json
        hash = MultiJson.decode(json, {:symbolize_keys => true})
        from_hash(hash)
      end


      def self.from_hash hash
        followers = []
        followers = hash[:followers].map do|obj|
          Objekt.new obj[:type], obj[:id]
        end if hash[:followers]

        FollowedObjekt.new hash[:type], hash[:id], followers
      end

      attr_accessor :followers


      def initialize type, id, followers = []
        super type, id
        @followers = followers.to_ary
      end


      def to_h
        hash = super

        hash[:followers] = @followers.map do |follower|
         follower.to_h
        end if @followers

        return hash
      end

      alias :to_hash :to_h


      def hash
        to_h.hash
      end


      def to_objekt
        Objekt.new @type, @id
      end
    end
  end
end
