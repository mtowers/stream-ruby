module RealSelf
  module Stream
    class StreamActivity

      attr_accessor :object, :activity, :reasons

      alias :owner :object


      def self.from_hash hash
        object = Objekt.from_hash(hash[:object])
        activity = Activity.from_hash(hash[:activity])
        reasons = hash[:reasons].map { |reason| Objekt.from_hash(reason) }

        StreamActivity.new(object, activity, reasons)
      end


      def self.from_json json
        hash = MultiJson::decode json, { :symbolize_keys => true }
        from_hash hash
      end


      def initialize object, activity, reasons = []
        @object = object
        @activity = activity
        @reasons = Set.new reasons
      end


      def == other
        other.kind_of?(self.class) and self.to_h == other.to_h
      end

      alias :eql? :==


      def content_type
        ContentType::STREAM_ACTIVITY
      end


      def hash
        to_h.hash
      end


      def prototype
        @activity.prototype
      end

      def to_h
        {
          :object => @object.to_h,
          :activity => @activity.to_h,
          :reasons => @reasons.map { |reason| reason.to_h }
        }
      end

      alias :to_hash :to_h


      def to_s
        MultiJson.encode(self.to_h)
      end

      alias :to_string :to_s


      def uuid
        @activity.uuid
      end

    end
  end
end
