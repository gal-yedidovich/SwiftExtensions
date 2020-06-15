# SwiftExtensions - Reusable & Secure utilities 

This library is handle IO operations on the local disk, with encryption layer for security. it also provides a convenice `Prefs` class for storing Key-Value easily and safely with the same encryption layer.

## Installation
SwiftExtensions is a *Swift Package*. 

Use the swift package manager to intall SwiftExtensions on your project. [Apple Developer Guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

## BasicExtensions 

### lots of convenince utility functions

#### Navigation
```swift
//Navigation:
extension ControllerID {
	static let myCtrl = ControllerID(value: "myCTRL") //make sure you have added "myCTRL" in the Storyboard
}

viewController.push(to: .myCtrl)

//OR with `config` block
viewController.present(.myCtrl) { (vc: MyViewController) in 
	//do any configuration before presenting "myCTRL", like: set instance variables
}
```

#### JSON Encoding with Codable protocol
```swift
struct MyType: Codable { 
	//values
}

let data = MyType(...).json() //convert to JSON encoded data

let instance: MyType = .from(json: data) //convert back to your type
```

#### Asynchronous block  
```swift
post {
	//run in the main thread
}

async {
	//run in a background thread
}
```

#### Localization
```swift
let helloWorld = "helloWorld".localized //provided you have "helloWorld" key in Localizable.string files"

print(helloWorld) //will automatically use the wanted localization

```

## StorageExtensions

### Convenience Read Write with GCM Encryption 
For easy Safe & scalable Storage Architecture, the FileSystem class gives you the ability to read & write files with GCM encryption, implemented using Apple's [CryptoKit Framework](https://developer.apple.com/documentation/cryptokit). 

- IO (Read/Write) operations are synchronous, for more control over threading.
- You are are required to use the `Filename` and/or `Folder` structs to state your desired files/folders. best used with `extension` like so:
```swift
extension Filename {
	static let myFile1 = Filename(value: "name1InFileSystem")
  static let myFile2 = Filename(value: "name2InFileSystem")
}

//usage
let data = ...
FileSystem.write(data: data, to: .myFile1)
```

#### TIP
> when implementing `Filename` or `Folder` you can (and probably should) use obfusctated names, for exmaple: use "--" insated of "secret.info".

### Prefs - Secure Key-Value pairs in storage. 
Insapired after iOS's `UserDefaults` & Android's `SharedPreferences`, The `Prefs` class enables you to manages Key-Value pairs easily and securely using the same encryption layer, also comes with a caching logic for fast & non blocking read/writes operation in memory.

You can either use the Standard instance, which is also using an obfuscated filename, or create your own instances for multiple files, like so:

```swift
let standardPrefs = Prefs.standard //the built-in standard instance 

//OR
let myPrefs = Prefs(file: .myFile1) //new instance using the Filename struct
```

## License
Apache License 2.0
