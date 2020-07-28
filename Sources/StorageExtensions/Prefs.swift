//
//  Prefs.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import BasicExtensions

/// An interface to an encrypted JSON file, where you store key-value pairs persistently and safely.
///
/// The Prefs class provides a programmatic interface to save sensetive information in device's storage.
/// These key-value pairs persists across launches & act as preferences in your app.
/// You can think of `Prefs` like a `UserDefaults` with an encryption layer.
public final class Prefs {
	///Built-in instance for convenience.
	public static let standard = Prefs(file: .prefs)
	internal let queue = DispatchQueue(label: "prefs", qos: .background)
	internal var dict: [String: String] = [:]
	internal var filename: Filename
	
	/// Initialize new Prefs instance link to a given Filename
	/// - Parameter file: Target Filename in storage
	public init(file: Filename) {
		self.filename = file
		
		reload()
	}
	
	/// loads the content from the target JSON file, into memory
	public func reload() {
		if FileSystem.fileExists(filename),
			let data = FileSystem.read(file: filename),
			let json: [String: String] = try? .from(json: data) {
			dict = json
		}
	}
	
	/// Get a string value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: string value of the given key, or nil if not found
	public func string(key: PrefKey) -> String? { dict[key.value] }
	
	/// Get an int value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: int value of the given key, or nil if not found
	public func int(key: PrefKey) -> Int? { codable(key: key) }
	
	/// Gets a boolean value from `Prefs` by given key, or uses the fallback value if not found
	/// - Parameters:
	///   - key: the wanted key, linked to the wanted value
	///   - fallback: the default value in case the key is not found
	/// - Returns: boolean value of the given key, or the fallback if not found.
	public func bool(key: PrefKey, fallback: Bool = false) -> Bool { codable(key: key) ?? fallback }
	
	/// Get a date value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: date value of the given key, or nil if not found
	public func date(key: PrefKey) -> Date? { codable(key: key) }
	
	/// Get a string array from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: string array, or nil if not found
	public func array(key: PrefKey) -> [String]? { codable(key: key) }
	
	/// Get a Decodable value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: some Decodable, or nil if not found
	public func codable<Type: Decodable>(key: PrefKey) -> Type? {
		guard let str = dict[key.value] else { return nil }
		return try? .from(json: str)
	}
	
	/// check if value exists at a given key
	/// - Parameter key: target key to check
	/// - Returns: true is eists, otherwise false
	public func contains(key: PrefKey) -> Bool { dict[key.value] != nil }
	
	/// Create new editor instance, to start editing the Prefs
	/// - Returns: new Editor isntance, referencing to this Prefs instance
	public func edit() -> Editor { Editor(prefs: self) }
}

/// An object that operate changes on a linked Prefs instance.
public class Editor {
	internal let prefs: Prefs
	internal var changes: [String: String?] = [:]
	internal var clearFlag = false
	
	/// initialize new instance with linked Prefs instance.
	/// - Parameter prefs: target Prefs to manipulate, depency injection
	internal init(prefs: Prefs) {
		self.prefs = prefs
	}
	
	/// Insert a string value to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - value: a value to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ value: String) -> Editor { put(key, value) }
	
	/// Insert an integer value to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - value: a value to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ value: Int) -> Editor { put(key: key, value as Encodable) }
	
	/// Insert a boolean value to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - value: a value to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ value: Bool) -> Editor { put(key: key, value as Encodable) }
	
	/// Insert a date value to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - value: a value to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ value: Date) -> Editor { put(key: key, value as Encodable) }
	
	/// Insert a string array of values to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - values: string values to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ values: [String]) -> Editor { put(key: key, values as Encodable) }
	
	/// Insert a date value to uncommited changes under a given key
	/// - Parameters:
	///   - key: target uniqe key to link to the value
	///   - value: a value to keep in Prefs
	/// - Returns: this instance, for method chaining
	public func put(key: PrefKey, _ value: Encodable) -> Editor { put(key, String(json: value)) }
	
	/// insert an uncommited removal to given key
	/// - Parameter key: target key to remove from Prefs
	/// - Returns: this instance, for method chaining
	public func remove(key: PrefKey) -> Editor { put(key, nil) }
	
	/// Reusable method to assign value to key in the changes dictionary.
	/// - Parameters:
	///   - key: key to assign in the changes dctionary
	///   - value: optional string value to link to the given key, nil means to remove
	/// - Returns: this instance, for method chaining
	private func put(_ key: PrefKey, _ value: String?) -> Editor {
		changes[key.value] = value
		return self
	}
	
	/// remove previous uncommited changes by this instance, and raise an uncommited `clearFlag` flag,
	/// - Returns: this instance, for method chaining
	public func clear() -> Editor {
		changes = [:]
		self.clearFlag = true
		return self
	}
	
	/// Commit the all uncommited changes in the `changes` dictionary.
	/// - if the `clearFlag` if true, remove all values in the Prefs dctionary.
	/// - if the `changes` dictionary is not empty, override the Prefs dictionary with the changes, including removals.
	/// - in case there are no changes & `clearFlag` is true, delete the Prefs flie
	/// - in case there are changes, they are written to Prefs file asynchronously
	public func commit() {
		prefs.queue.sync { //sync changes
			if self.clearFlag { prefs.dict = [:] }
			
			if !self.changes.isEmpty {
				for (key, value) in self.changes {
					if value == nil { prefs.dict.removeValue(forKey: key) }
					else { prefs.dict[key] = value }
				}
				
				prefs.queue.async { //write in background
					do {
						try FileSystem.write(data: self.prefs.dict.json(), to: self.prefs.filename)
					} catch {
						print("could not write to \"prefs\" file.")
						print(error)
					}
				}
			} else if self.clearFlag {
				do {
					try FileSystem.delete(file: prefs.filename)
				} catch {
					print("could not delete \"prefs\" file.")
					print(error)
				}
			}
		}
	}
}


/// String wrapper for representing a key in a `Prefs` instance.
public struct PrefKey {
	let value: String
	
	public init(value: String) {
		self.value = value
	}
}
