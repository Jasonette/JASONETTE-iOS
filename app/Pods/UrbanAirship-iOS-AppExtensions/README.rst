**Deprecated** ua-ios-pod
=========================

The UrbanAirship-iOS-SDK and UrbanAirship-iOS-AppExtensions podspecs have been moved to the `ios-library repo <https://github.com/urbanairship/ios-library>`_


ua-ios-pod does the following things:

- Provides a staging area for the UrbanAirship-iOS-SDK podspec (which lives in the Cocoapods Specs repo).
- Provides a pod sample app PodSample with accompanying podfile.

How to use PodSample:
^^^^^^^^^^^^^^^^^^^^^

- Navigate to PodSample's podfile and run 'pod install'
- Open the PodSample.workspace created during install once the installation is complete

Sample podfile contents:
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: json

    use_frameworks!

    # Urban Airship SDK
    target "PodSample" do
      pod 'UrbanAirship-iOS-SDK', '~> 8.0.5'
    end

    # Urban Airship Extension
    target "SampleServiceExtension" do
      pod 'UrbanAirship-iOS-AppExtensions', '~> 8.0.5'
    end

Bitcode Support:
^^^^^^^^^^^^^^^^

As of version 6.4.0, ua-ios-pod supports bitcode by default.
