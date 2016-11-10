module AndroidUtils
  require 'open3'

  APPIUM_PATH ||= '/usr/local/lib/node_modules/appium'

  #
  # Starts the Appium server locally.
  # The standard default Appium path on a Mac machine is set in APPIUM_PATH
  # If you need to start Appium from another path, provide it as parameter
  #
  # TODO Fix this so it does not crash after the first scenario (sockets are closed or smnthn like this)
  def self.start_appium(appium_path = APPIUM_PATH)
    Open3.popen2("node #{appium_path}")
    sleep(10)
  end

  #
  # Stops the local Appium server by killing the node process
  #
  def self.stop_appium
    `killall node`
  end

  #
  # Create logger with the default log level of Debug
  #
  def self.create_logger
    $logger = Logger.new(STDOUT)
    $logger.level = Logger::DEBUG
  end

  #
  # Logs device's properties like brand and apilevel
  #
  def self.log_device_info
    $logger.debug("Device brand: #{Entities::Device.brand}")
    $logger.debug("Api level: #{Entities::Device.apilevel}")
    $logger.debug("Device Codename: #{Entities::Device.codename}")
  end

  #
  # DEPRECATED - No need to use it anymore
  # ApiLevel24 needs to uninstall appium settings as a preparation for the tests to work
  #
  def self.prepare_apilevel24
    $logger.debug 'Preparing Api Level 24 device'
    `adb uninstall io.appium.settings`
    `adb uninstall io.appium.unlock`
  end

  #
  # Creation of appium driver and starting session
  #
  def self.create_appium_driver(path)
    $logger.debug('Creating Appium driver')

    caps = Appium.load_appium_txt file: File.expand_path(path), verbose: true
    Appium::Driver.new(caps)
    Appium.promote_appium_methods Object

    #World do
    #  AppiumWorld.new
    #end

    AndroidUtils.start_appium_session
  end

  #
  # Start appium driver
  #
  def self.start_appium_session
    $driver.start_driver
  end

  #
  # Uses the device's "Powen Manager" to check if the device has the BatterySaver setting enables/active
  # and regularizes the status to normal power (BatterySaver off) if that is the case
  #
  def self.regularise_power_status
    battery_saver_setting = `adb shell dumpsys power | grep "mLowPowerModeSetting"`.strip

    if battery_saver_setting == 'mLowPowerModeSetting=true'
      $logger.debug("Regularising Power settings")

      self.set_battery_status(2)
      self.set_battery_manager_usb(1)
    end

  end

  #
  # Turns on the BatterySaver mode
  # Uses the appium driver
  #
  def self.set_battery_saver_on
    case Entities::Device.brand
    when 'google', 'samsung'
      wait { id("com.android.settings:id/switch_widget").click }
    when 'oneplus'
      wait { text("Battery mode").click }
      wait { xpath("//android.widget.CheckedTextView[@text='Power save']").click }
    end
  end

  #
  # Prepares the device for the battery saver mode
  #
  def self.prepare_for_battery_saver
    self.set_battery_manager_unplug
    self.set_battery_status(3)
  end

  #
  # Sets the "battery manager" to unplug
  # With this the device will not charge even if the cable is plugged
  #
  def self.set_battery_manager_unplug
    if Entities::Device.brand == 'oneplus'
      `adb shell dumpsys batterymanager unplug`
    else
      `adb shell dumpsys battery unplug`
    end
  end

  #
  # Sets the "battery manager" usb charging to 0 or 1
  #
  def self.set_battery_manager_usb(number)
    raise StandardError unless [0,1].include?(number.to_i)
    if Entities::Device.brand == 'oneplus'
      `adb shell dumpsys batterymanager set usb #{number}`
    else
      `adb shell dumpsys battery set usb #{number}`
    end

  end

  #
  # Sets the "battery manager" battery status to the passed parameter
  # Useful statuses:
  # 2: charging
  # 3: discharging
  # 4: not charging
  #
  def self.set_battery_status(status)
    raise StandardError unless [1,2,3,4,5].include?(status.to_i)

    case Entities::Device.brand
    when 'oneplus'
      `adb shell dumpsys batterymanager set status #{status.to_i}`
    else
      `adb shell dumpsys battery set status #{status.to_i}`
    end
  end

  #
  # Resets the "battery manager" status to normal
  #
  def self.reset_battery_manager
    if Entities::Device.brand == 'oneplus'
      `adb shell dumpsys batterymanager reset`
    else
      `adb shell dumpsys battery reset`
    end
  end

  #
  # Access to VPN settings
  #
  def self.access_vpn_settings
    `adb shell am force-stop com.android.settings`
    sleep(2)
    `adb shell am start -n 'com.android.settings/.Settings\\$VpnSettingsActivity'`
    sleep(7)
  end

  #
  # Access to Battery Saver settings
  #
  def self.access_battery_saver_settings
    `adb shell am force-stop com.android.settings`

    case Entities::Device.brand
    when 'oneplus', 'google'
      `adb shell am start -n 'com.android.settings/.Settings\\$BatterySaverSettingsActivity'`
    when 'samsung'
      `adb shell am start -n 'com.android.settings/.Settings\\$GenericPowerSavingModeActivity'`
    end
  end

end
