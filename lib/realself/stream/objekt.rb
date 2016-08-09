module RealSelf
  module Stream
    class Objekt

      attr_accessor :type, :id


      def self.from_json json
        hash = MultiJson.decode json, { :symbolize_keys => true }
        from_hash hash
      end


      def self.from_hash hash
        unless hash[:type].nil?
          Objekt.new hash[:type].downcase, hash[:id]

        else
          Objekt.new hash[:_type].downcase, hash[:_id]
        end
      end


      def initialize type, id
        @type = type.to_s
        @id = id.to_s
      end


      def == other
        other.kind_of?(self.class) and self.to_h == other.to_h
      end

      alias :eql? :==


      def hash
        to_h.hash
      end


      def to_h
        {:type => @type,:id => @id}
      end

      alias :to_hash :to_h


      def to_s
        MultiJson::encode to_h
      end

      alias :to_string :to_s
    end
  end
end
