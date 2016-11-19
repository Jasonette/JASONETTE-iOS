# Microsoft Azure Mobile Apps: iOS SDK

[![Build Status](https://travis-ci.org/Azure/azure-mobile-apps-ios-client.svg?branch=master)](https://travis-ci.org/Azure/azure-mobile-apps-ios-client)

With Microsoft Azure Mobile Apps you can add a scalable backend to your connected client applications in minutes. To learn more, visit our [Developer Center](http://azure.microsoft.com/en-us/develop/mobile).

## Getting Started

If you are new to Mobile Apps, you can get started by following our tutorials for connecting your Mobile
Apps cloud backend to [iOS apps](https://azure.microsoft.com/en-us/documentation/articles/app-service-mobile-ios-get-started/).

## Download Source Code

To get the source code of our SDKs and samples via **git** just type:

    git clone https://github.com/Azure/azure-mobile-apps-iOS-client.git
    cd ./azure-mobile-apps-iOS-client/

## Reference Documentation

* [Client SDK](http://azure.github.io/azure-mobile-services/iOS/v3)

* [Change log](CHANGELOG.md)

## iOS Client SDK
Add a cloud backend to your iOS application in minutes with our iOS client SDK. You can [download the iOS SDK](https://go.microsoft.com/fwLink/?LinkID=529823&clcid=0x409) directly or you can download the source code using the instructions above.  

### Prerequisites

The SDK requires XCode 7.0 or greater.

###Building and Referencing the SDK

1. Open the ```sdk\WindowsAzureMobileServices.xcodeproj``` file in XCode.
2. Set the active scheme option to ```Framework\iOS Device```.
3. Build the project using Command-B. The ```WindowsAzureMobileServices.framework``` folder should be found in the build output folder under ```Products\<build configuration>-iphoneos```.
4. Drag and drop the ```WindowsAzureMobileServices.framework``` from a Finder window into the Frameworks folder of the Project Navigator panel of your iOS application XCode project.

### Running the Unit Tests

1. Open the ```sdk\WindowsAzureMobileServices.xcodeproj``` file in XCode.
2. Set the active scheme option to ```WindowsAzureMobileServices\* Simulator```.
3. Open the ```Test\WindowsAzureMobileServicesFunctionalTests.m``` file in the Project Navigator panel of XCode.
4. In the ```settings.plist``` file, set ```TestAppUrl``` and ```TestAppApplicationKey``` to a valid URL and Application Key for a working Mobile Service.
5. Run the tests using Command-U.

### Running the E2E Tests

1. Create a [test server](https://github.com/Azure/azure-mobile-apps-net-server/tree/master/e2etest) to test against, see: [E2E Test Suite](e2etest)
2. Open the ```ZumoE2ETestApp\ZumoE2ETestApp.xcodeproj``` file in XCode.
3. Drag a copy of the ```WindowsAzureMobileServices.framework``` into the project
4. Pick the device to test and run the project

## Useful Resources

* [Quickstarts](https://github.com/Azure/azure-mobile-apps-quickstarts)
* [E2E Test Suite](e2etest)
* [Samples](https://github.com/Azure/mobile-services-samples)
* Tutorials and product overview are available at [Microsoft Azure Mobile Services Developer Center](http://azure.microsoft.com/en-us/develop/mobile).
* Our product team actively monitors the [Mobile Services Developer Forum](http://social.msdn.microsoft.com/Forums/en-US/azuremobile/) to assist you with any troubles.

## Contribute Code or Provide Feedback
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

If you would like to become an active contributor to this project please follow the instructions provided in [Microsoft Azure Projects Contribution Guidelines](http://azure.github.com/guidelines.html).

If you encounter any bugs with the library please file an issue in the [Issues](https://github.com/Azure/azure-mobile-apps-ios-client/issues) section of the project.
