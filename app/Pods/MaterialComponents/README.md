# Material Components for iOS

<img align="right" src="mdc_hero.png" width="300px">

[![Build Status](https://travis-ci.org/material-components/material-components-ios.svg?branch=develop)](https://travis-ci.org/material-components/material-components-ios)
[![Code coverage](https://img.shields.io/codecov/c/github/material-components/material-components-ios/develop.svg)](https://codecov.io/gh/material-components/material-components-ios/branch/develop)
[![Chat](https://img.shields.io/discord/259087343246508035.svg)](https://discord.gg/material-components)

Material Components for iOS (MDC-iOS) helps developers execute [Material Design](https://material.io). Developed by a core team of engineers and UX designers at Google, these components enable a reliable development workflow to build beautiful and functional iOS apps. Learn more about how Material Components for iOS supports design and usability best practices across platforms in the  [Material Design Platform Adaptation guidelines](https://material.io/guidelines/platforms/platform-adaptation.html).

Material Components for iOS are written in Objective-C and support Swift and Interface Builder.

## Useful Links

- [Documentation](https://material.io/components/ios/) (external site)
- [How To Use MDC-iOS](docs/)
- [All Components](components/)
- [Demo Apps](demos/)
- [Contributing](contributing/)
- [MDC-iOS on Stack Overflow](https://www.stackoverflow.com/questions/tagged/material-components+ios) (external site)
- [Material.io](https://material.io) (external site)
- [Material Design Guidelines](https://material.io/guidelines) (external site)
- [Checklist status spreadsheet](https://docs.google.com/spreadsheets/d/e/2PACX-1vRQLFMuo0Q3xsJp1_TdWvImtfdc8dU0lqX2DTct5pOPAEUIrN9OsuPquvv4aKRAwKK_KItpGs7c4Fok/pubhtml)
- [Discord Chat Room](https://discord.gg/material-components)

## Trying out Material Components

[CocoaPods](https://cocoapods.org/) is the easiest way to get started (if you're new to CocoaPods,
check out their [getting started documentation](https://guides.cocoapods.org/using/getting-started.html).)

To install CocoaPods, run the following commands:

```bash
sudo gem install cocoapods
```

Our [catalog](catalog/) showcases Material Components. You can use the `pod try` command from anywhere on your machine to try the components, even if you haven't checked out the repo yet:

``` bash
pod try MaterialComponents
```

In case you have already checked out the repo, run the following command:

``` bash
pod install --project-directory=catalog/
```

The component implementations can be found in Xcode within `Pods > Development Pods > MaterialComponents`.

## Requirements

- Xcode 9 or higher
- Minimum iOS deployment target of 8.0 or higher
- CocoaPods 1.5 or higher

## Attributions

Material Components for iOS uses
[Material Design icons](https://github.com/google/material-design-icons),
copyright Google Inc. and licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Several components use
[MDFTextAccessibility](https://github.com/material-foundation/material-text-accessibility-ios),
copyright Google Inc. and licensed under
[Apache 2.0](https://github.com/material-foundation/material-text-accessibility-ios/blob/master/LICENSE)
without a NOTICE file.

MDCCatalog uses the
[Roboto font](https://github.com/google/fonts/tree/master/apache/roboto),
copyright 2011 Google Inc. and licensed under
[Apache 2.0](https://github.com/google/fonts/blob/master/apache/roboto/LICENSE.txt)
without a NOTICE file.
