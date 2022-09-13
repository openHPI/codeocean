# frozen_string_literal: true

# Define an application-wide HTTP permissions policy. For further
# information see https://developers.google.com/web/updates/2018/06/feature-policy
# TODO: Feature-Policy has been renamed to Permissions-Policy. The Permissions-Policy is
#       not yet supported by Rails (even though the new name is already used for the method)
Rails.application.config.permissions_policy do |policy|
  policy.accelerometer        :none
  policy.ambient_light_sensor :none
  policy.autoplay             :none
  policy.camera               :none
  policy.encrypted_media      :none
  policy.fullscreen           :none
  policy.geolocation          :none
  policy.gyroscope            :none
  policy.magnetometer         :none
  policy.microphone           :none
  policy.midi                 :none
  policy.payment              :none
  policy.picture_in_picture   :none
  # The `speaker` directive is used for selection of non-default audio output devices
  policy.speaker              :none
  policy.usb                  :none
  policy.vibrate              :none
  policy.vr                   :none
end
