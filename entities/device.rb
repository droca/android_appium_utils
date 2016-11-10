module Entities

  class Device
    class << self

      def initialize
        self.apilevel
        self.brand
        self.codename
      end

      #
      # Retrieves device api level
      #
      def apilevel
        @apilevel ||= `adb shell getprop ro.build.version.sdk`.strip
      end

      #
      # Retrieves device brand
      #
      def brand
        @brand ||= `adb shell getprop ro.product.brand`.strip
      end

      #
      # Retrieves device codename
      #
      def codename
        @codename ||= `adb shell getprop ro.build.version.codename`.strip
      end

    end
  end

end