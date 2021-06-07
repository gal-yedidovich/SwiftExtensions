# SwiftExtensions - Robust, Reusable & Secure utilities 

This library provides helpful utilities, like IO operations on the local disk, with encryption layer for security. It also provides a convenice `Prefs` class for storing Key-Value pairs easily and safely with the same encryption layer.

## Installation
SwiftExtensions is a *Swift Package*. 

Use the swift package manager to install SwiftExtensions on your project. [Apple Developer Guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

## StorageExtensions
### Convenience Read & Write operations with an encryption layer from `CryptoExtensions`. 
For easy, safe & scalable storage architecture, the `Filer` class gives you the ability to read & write files while keeping them extra secure in the file system.

* IO (Read/Write) operations are *synchronous*, for more control and easier error handling.
* You are are required to use the `Filename` or `Folder` structs to state your desired files/folders. best used with `extension` like so:
```swift
extension Filename {
	static let myFile1 = Filename(value: "name1InFiler")
	static let myFile2 = Filename(value: "name2InFiler")
}

//Usage
let data = Data("Bubu is the king".utf8)
do {
	try Filer.write(data: data, to: .myFile1) //encrypts & write to file
	let sameData = try Filer.read(file: .myFile1) //reads & decrypts

	print(String(decoding: sameData, as: UTF8.self)) //"Bubu is the king"

	try Filer.delete(file: .myFile1)
} catch {
	//Handle errors
}
```

#### TIP
> when instantiating `Filename` or `Folder` you can (and probably should) use obfusctated names, for exmaple: use "--" insated of "secret.info".

### Storage Customizations
You are able to change some values in the library.

`Filer.rootURL`: defaults to the documents url of the app, it can change for example to an AppGroup url: 

```swift
Filer.rootURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "your.app.group")
```

`Filer.encryptor`: controls the underlining SimpleEncryptor that handles cryptographics: (requires `CryptoExtensions`)

```swift
Filer.encryptor = SimpleEncryptor(strategy: .gcm)
```

### Prefs - Secure Key-Value pairs in storage. 
Insapired after iOS's `UserDefaults` & Android's `SharedPreferences`, The `Prefs` class enables you to manage Key-Value pairs easily and securely using the encryption layer from `CryptoExtensions`, also comes with a caching logic for fast & non blocking read/writes operation in memory.

You can either use the Standard instance, which is also using an obfuscated filename, or create your own instances for multiple files, like so:

```swift
let standardPrefs = Prefs.standard //the built-in standard instance 

//OR
let myPrefs = Prefs(file: .myFile1) //new instance using the Filename struct
```

You can put values: 
```swift	
extension PrefKey {
	static let name = PrefKey(value: "obfuscatedKey") //value should be obfuscated
}

let myPrefs.edit() //start editing
	.put(key: .name, "Bubu") //using the static constant '.name'
	.commit() //save your changes in memory & lcoal storage
```

And you can read them:
```swift
if let name = myPrefs.string(key: .name) {
	print("\(name), is the king")
}
```

Observing changes with `Combine` Framework
```swift
let cancelable1 = myPrefs.publisher
	.sink { prefs in print("prefs changed") } //prints "prefs changed" whenever we commit changes.


//Detecting changes on a key 
let cancelable2 = prefs.publisher
	.compactMap { $0.string(key: .name) }
	.removeDuplicates()
	.sink { print("name changed to: \($0)") }
```

> `Prefs.publisher` will fire events when the prefs instance has committed non-empty commits.

#### PrefsValue - Wrapped property for SwfitUI.
Wrapping a variable with `@PrefsValue` allows to manage a single value transparently in the prefs

```swift
extension PrefKey {
	static let displayName = PrefKey(value: "someObfuscatedKey")
}

struct ContentView: View {
	@PrefsValue(key: .displayName) var displayName: String = ""

	var body: some View {...}
}
```
Views will re-render when a `@PrefsValue` changes

## CryptoExtensions
### awesome encryption & decryption APIs, including:
* `SimpleEncryptor` class, great for convenience crypto operations (data and/or big files), using keychain to store keys.
* `AES/CBC` implementation in Swift, on top of "Common Crypto" implementation.
* useful "crypto" extension methods.

#### SimpleEncryptor example (with CBC)
```swift
let data = Data("I am Groot!".utf8)
let encryptor = SimpleEncryptor(strategy: .cbc(iv: Data(...)))

do {
	let encrypted = try encryptor.encrypt(data) 
	let decrypted = try encryptor.decrypt(encrypted)

	print(String(decoding: decrypted, as: UTF8.self)) //"I am Groot!"
} catch {
	//handle cryptographic errors
}
```

#### Basic CBC cryptographic example:
```swift
let data: Data = ... //some data to encrypt
let iv: Data = ... //an initial verctor
let key: SymmetricKey = ... //encryption key

do {
	let encrypted = try AES.CBC.encrypt(data, using: key, iv: iv)
	let decrypted = try AES.CBC.decrypt(encrypted, using: key, iv: iv)
} catch {
	//handle cryptographic errors
}
```

## BasicExtensions 

### lots of convenince utility functions

#### JSON Encoding & Decoding with Codable protocol
```swift
struct MyType: Codable { 
	//values
}

let data = MyType(...).json() //convert to JSON encoded data

do {
	let instance: MyType = try .from(json: data) //convert back to your type
} catch { ... }
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
	.set(method: .POST) //OR .GET, .PUT, .DELETE, .PATCH
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

#### UIKit Navigation
```swift
//Navigation:
extension ControllerID {
	static let myCtrl = ControllerID(value: "myCTRL") //make sure to have "myCTRL" identifier in Storyboard
}

viewController.push(to: .myCtrl)

//OR with `config` block
viewController.present(.myCtrl) { (vc: MyViewController) in 
	//do any configuration before presenting "myCTRL", for example: settting instance variables
}
```

### JsonObject & JsonArray - dynamic JSON structs
Conveniece structs for working with dynamic JSON.


```swift

//new JSON example
let json = JsonObject()
	.with(key: "name", value: "Bubu")
	.with(key: "age", value: 10)
	
do {
	let data: Data = try json.data()
} catch {
	//handle encoding error
}
```


```swift
//receiving JSON as `Data` from an API

do {
	let json = try JsonObject(data: dataFromApi) //given data from API

	if let name = json.string(key: "name"), 
		let age = json.int(key: "age") {
		print("name: \(name), age: \(age)")
	}
} catch {
	//handle decoding error
}

```


## License
Apache License 2.0
