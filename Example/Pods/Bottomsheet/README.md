# BottomSheet

Component which presents a dismissible view from the bottom of the screen

[![CocoaPods Compatible](http://img.shields.io/cocoapods/v/Bottomsheet.svg?style=flat)](http://cocoadocs.org/docsets/Bottomsheet)
[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

<img src="https://github.com/hryk224/Bottomsheet/wiki/images/sample1.gif" width="320" > <img src="https://github.com/hryk224/Bottomsheet/wiki/images/sample2.gif" width="320" > <img src="https://github.com/hryk224/Bottomsheet/wiki/images/sample3.gif" width="320" > <img src="https://github.com/hryk224/Bottomsheet/wiki/images/sample4.gif" width="320" >

## Requirements
- iOS 9.0+
- Swift 3.0+
- ARC

## install

#### CocoaPods

Adding the following to your `Podfile` and running `pod install`:

```Ruby
use_frameworks!
pod "Bottomsheet"
```

### import

```Swift
import Bottomsheet
```

## Usage

```Swift
let controller = Bottomsheet.Controller()

// Adds View
let view = UIView
controller.addContentsView(view)

// Adds NavigationBar
controller.addNavigationbar { [weak self] navigationBar in
    // navigationBar
}

// Adds CollectionView
controller.addCollectionView { [weak self] collectionView in
    // collectionView
}

// Adds TableView
controller.addTableView { [weak self] tableView in
    // tableView
}

// customize
controller.overlayBackgroundColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.3)
controller.viewActionType = .tappedDismiss
controller.initializeHeight = 200
```

## Acknowledgements

* Inspired by [Flipboard/bottomsheet](https://github.com/Flipboard/bottomsheet) in [Flipboard](https://github.com/Flipboard).

##License

This project is made available under the MIT license. See LICENSE file for details.
