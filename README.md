# Chat Roulette iOS

Chat Roulette iOS application for Fora Soft, Ltd.

## Building Requirements

*  [Cocoapods](https://cocoapods.org/) is used to manage dependencies. Please install the latest version.
*  iOS 8.0+
*  Xcode 7.2+

## Building

1. Use Cocoapods to install the dependencies (`pod install`).
2. Open `ChatRoulette.xcworkspace` in Xcode.
3. Select the device you wish to run on, and Build and Run (⌘R).

## Working Requirements

*  Modified version of OpenTokRTC node.js server (https://github.com/opentok/OpenTokRTC)
*  Currently server is running online by URL ``http://m4x13.herokuapp.com/``; you can replace this hardcoded value by your own in ``MainViewController.h`` : ``kServerURL``.

## Publishing

To publish in AppStore, open Info.plist file and remove ``App Transport Security Settings`` and it's childs.
Then server should be accessable by HTTPS.
