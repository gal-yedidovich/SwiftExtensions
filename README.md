# SwiftExtensions - Robust, Reusable & Secure utilities 

This library provides helpful utilities, like IO operations on the local disk, with encryption layer for security. It also provides a convenice `Prefs` class for storing Key-Value pairs easily and safely with the same encryption layer.

## Installation
SwiftExtensions is a *Swift Package*. 

Use the swift package manager to install SwiftExtensions on your project. [Apple Developer Guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

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
	//do any configuration before presenting "myCTRL", for example: settting instance variables
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

#### URLRequest builder
```swift
let req = URLRequest(url: "https://your.end.point")
	.set(method: .POST) //Or .get, .put, .delete, .patch
	.set(contentType: .json) //OR .xml, .urlEncoded etc.
	.set(body: "some String or Data")
```

Another example:
```swift
let dict = ["title": "Bubu is the king", "message": "I am Groot"]

let req = URLRequest(url: "https://your.end.point")
	.set(method: .PUT)
	.set(contentType: .json)
	.set(body: dict.json()) //allows encodable values
```

#### Localization
```swift
let helloWorld = "helloWorld".localized //provided you have "helloWorld" key in Localizable.strings files"

print(helloWorld) //will automatically use the wanted localization

```

## StorageExtensions

### Convenience Read & Write operations with GCM Encryption 
For easy, safe & scalable storage architecture, the `FileSystem` class gives you the ability to read & write files with GCM encryption, implemented using Apple's [CryptoKit Framework](https://developer.apple.com/documentation/cryptokit). 

- IO (Read/Write) operations are synchronous, for more control over threading.
- You are are required to use the `Filename` or `Folder` structs to state your desired files/folders. best used with `extension` like so:
```swift
extension Filename {
	static let myFile1 = Filename(value: "name1InFileSystem")
	static let myFile2 = Filename(value: "name2InFileSystem")
}

//Usage
let data = "Bubu is the king".data(encoding: .utf8)!
FileSystem.write(data: data, to: .myFile1)
```

#### TIP
> when instantiating `Filename` or `Folder` you can (and probably should) use obfusctated names, for exmaple: use "--" insated of "secret.info".

### Storage Customizations
You are able to change some values in the library.

`FileSystem.rootURL`: defaults to the documents url of the app, it can change for example to an AppGroup url: 

```swift
FileSystem.rootURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "your.app.group")
```

`Encryptor.keyChainQuery`: defaults with basic password class. Here is a customized example:

```swift
Encryptor.keyChainQuery[kSecAttrAccessGroup] = "your.app.group"

//OR - override the whole dictionary
Encryptor.keyChainQuery = [
	key: value
]
```


### Prefs - Secure Key-Value pairs in storage. 
Insapired after iOS's `UserDefaults` & Android's `SharedPreferences`, The `Prefs` class enables you to manage Key-Value pairs easily and securely using the same encryption layer from `Encryptor`, also comes with a caching logic for fast & non blocking read/writes operation in memory.

You can either use the Standard instance, which is also using an obfuscated filename, or create your own instances for multiple files, like so:

```swift
let standardPrefs = Prefs.standard //the built-in standard instance 

//OR
let myPrefs = Prefs(file: .myFile1) //new instance using the Filename struct
```

You can put values: 
```swift
let myPrefs.edit() //start editing
	.put(key: .name, "Bubu") //using the static constant '.name'
	.commit() //save your changes in memory & lcoal storage
	
extension PrefKey {
	static let name = PrefKey(value: "obfuscatedKey") //value should be obfuscated
}
```

And you can read them:
```swift
if let name = myPrefs.string(key: .name) {
	print("\(name), is the king") 
}
```

## License
Apache License 2.0
