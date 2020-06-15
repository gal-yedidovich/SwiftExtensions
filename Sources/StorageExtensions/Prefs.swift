//
//  Prefs.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import BasicExtensions

public final class Prefs {
	///Built-in instance for convenience.
	public static let standard = Prefs(file: .prefs)
	internal var dict: [String: String] = [:]
	internal var filename: Filename
	
	/// Initialize new Prefs instance link to a given Filename
	/// - Parameter file: Target Filename in storage
	public init(file: Filename) {
		self.filename = file
		
		if FileSystem.fileExists(filename),
			let data = FileSystem.read(file: filename) {
			dict = .from(json: data)
		}
	}
	
	/// Get a string value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: string value of the given key, or nil if not found
	public func string(key: String) -> String? { dict[key] }
	
	/// Get an int value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: int value of the given key, or nil if not found
	public func int(key: String) -> Int? { Int(dict[key] ?? "") }
	
	/// Gets a boolean value from `Prefs` by given key, or uses the fallback value if not found
	/// - Parameters:
	///   - key: the wanted key, linked to the wanted value
	///   - fallback: the default value in case the key is not found
	/// - Returns: boolean value of the given key, or the fallback if not found.
	public func bool(key: String, fallback: Bool = false) -> Bool { Bool(dict[key] ?? "") ?? fallback }
	
	/// Get a date value from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: date value of the given key, or nil if not found
	public func date(key: String) -> Date? {
		if let val = dict[key] {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "dd-MM-yyyy HH-mm-ss"
			
			let date = dateFormatter.date(from: val)!
			return date
		}
		else { return nil }
	}
	
	/// Get a string array from `Prefs` by given key, or nil if not found
	/// - Parameter key: the wanted key, linked to the wanted value
	/// - Returns: string array, or nil if not found
	public func array(key: String, fallback: [String]? = nil) -> [String]? {
		if let val = dict[key] {
			var arr =  val.components(separatedBy: "\n")
			arr.removeLast()
			return arr
		}
		else { return fallback }
	}
	
	/// check if value exists at a given key
	/// - Parameter key: target key to check
	/// - Returns: true is eists, otherwise false
	public func contains(key: String) -> Bool { dict[key] != nil }
	
	/// Create new editor instance, to start editing the Prefs
	/// - Returns: new Editor isntance, referencing to this Prefs instance
	public func edit() -> Editor { Editor(prefs: self) }
	
	
	/// Editor calss, does CRUD operations on a linked Prefs instance.
	public class Editor {
		internal static let queue = DispatchQueue(label: "prefs", qos: .background)
		internal let prefs: Prefs
		internal var changes: [String: String?] = [:]
		internal var clearFlag = false
		
		/// initialize new instance with linked Prefs instance.
		/// - Parameter prefs: target Prefs to manipulate, depency injection
		public init(prefs: Prefs) {
			self.prefs = prefs
		}
		
		/// Insert a string value to uncommited changes under a given key
		/// - Parameters:
		///   - key: target uniqe key to link to the value
		///   - value: a value to keep in Prefs
		/// - Returns: this instance, for method chaining
		public func put(key: String, _ value: String) -> Editor { put(key, value) }
		
		/// Insert an integer value to uncommited changes under a given key
		/// - Parameters:
		///   - key: target uniqe key to link to the value
		///   - value: a value to keep in Prefs
		/// - Returns: this instance, for method chaining
		public func put(key: String, _ value: Int) -> Editor { put(key, "\(value)") }
		
		/// Insert a boolean value to uncommited changes under a given key
		/// - Parameters:
		///   - key: target uniqe key to link to the value
		///   - value: a value to keep in Prefs
		/// - Returns: this instance, for method chaining
		public func put(key: String, _ value: Bool) -> Editor { put(key, "\(value)") }
		
		/// Insert a date value to uncommited changes under a given key
		/// - Parameters:
		///   - key: target uniqe key to link to the value
		///   - value: a value to keep in Prefs
		/// - Returns: this instance, for method chaining
		public func put(key: String, _ value: Date) -> Editor {
			let date = DateFormatter()
			date.dateFormat = "dd-MM-yyyy HH-mm-ss"
			
			return put(key: key, date.string(from: value))
		}
		
		/// Insert a string array of values to uncommited changes under a given key
		/// - Parameters:
		///   - key: target uniqe key to link to the value
		///   - values: string values to keep in Prefs
		/// - Returns: this instance, for method chaining
		public func put(key: String, _ values: [String]) -> Editor {
			var str = ""
			for v in values { str += v + "\n" }
			return put(key, str)
		}
		
		/// insert an uncommited removal to given key
		/// - Parameter key: target key to remove from Prefs
		/// - Returns: this instance, for method chaining
		public func remove(key: String) -> Editor { put(key, nil) }
		
		/// Reusable method to assign value to key in the changes dictionary.
		/// - Parameters:
		///   - key: key to assign in the changes dctionary
		///   - value: optional string value to link to the given key, nil means to remove
		/// - Returns: this instance, for method chaining
		private func put(_ key: String, _ value: String?) -> Editor {
			changes[key] = value
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
			Self.queue.sync { //sync changes
				if self.clearFlag { prefs.dict = [:] }
				
				if !self.changes.isEmpty {
					for (key, value) in self.changes {
						if value == nil { prefs.dict.removeValue(forKey: key) }
						else { prefs.dict[key] = value }
					}
					
					Self.queue.async { //write in background
						FileSystem.write(data: self.prefs.dict.json(), to: self.prefs.filename)
					}
				} else if self.clearFlag {
					FileSystem.delete(file: prefs.filename)
				}
			}
		}
	}
}

