//
//  Prefs.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import BasicExtensions
import Combine

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
	
	private let strategy: WriteStrategy
	private let changeSubject = PassthroughSubject<Prefs, Never>()
	
	/// Initialize new Prefs instance link to a given Filename, and loading it`s content
	/// - Parameter file: Target Filename in storage
	/// - Parameter writeStrategy: Strategy for writing to the FileSystem
	public init(file: Filename, writeStrategy: WriteStrategyType = .batch) {
		self.filename = file
		self.strategy = writeStrategy.createStrategy()
		reload()
	}
	
	/// loads the content from the target JSON file, into memory
	public func reload() {
		if let json: [String: String] = try? FileSystem.load(json: filename) {
			dict = json
		}
	}
	
	/// Get a string value from `Prefs` by given key, or nil if its not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: String value of the given key, or nil if its not found
	public func string(key: PrefKey) -> String? { dict[key.value] }
	
	/// Get an int value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: Int value of the given key, or nil if its not found
	public func int(key: PrefKey) -> Int? { codable(key: key) }
	
	/// Gets a boolean value from `Prefs` by given key, or uses the fallback value if not found
	/// - Parameters:
	///   - key: The wanted key, linked to the wanted value
	///   - fallback: The default value in case the key is not found
	/// - Returns: Bool value of the given key, or the fallback if its not found.
	public func bool(key: PrefKey, fallback: Bool = false) -> Bool { codable(key: key) ?? fallback }
	
	/// Get a date value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: Date value of the given key, or nil if not found
	public func date(key: PrefKey) -> Date? { codable(key: key) }
	
	/// Get a Decodable value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: Some Decodable, or nil if key is not found
	public func codable<Type: Decodable>(key: PrefKey) -> Type? {
		guard let str = dict[key.value] else { return nil }
		if Type.self == String.self { return str as? Type }
		
		return try? .from(json: str)
	}
	
	/// check if values exist for given keys.
	/// - Parameter keys: pref keys to check
	/// - Returns: true if all of the keys exist, otherwise false
	public func contains(_ keys: PrefKey...) -> Bool {
		keys.allSatisfy { dict[$0.value] != nil }
	}
	
	/// Create new editor instance, to start editing the Prefs
	/// - Returns: new Editor isntance, referencing to this Prefs instance
	public func edit() -> Editor { Editor(prefs: self) }
	
	/// write commit and alert all subscribers that changes were made.
	internal func apply(_ commit: Commit) {
		strategy.commit(commit, to: self)
		changeSubject.send(self)
	}
	
	/// A Combine publisher that publishes whenever the prefs commit changes.
	public var publisher: AnyPublisher<Prefs, Never> {
		changeSubject.eraseToAnyPublisher()
	}
}

/// String wrapper for representing a key in a `Prefs` instance.
public struct PrefKey {
	let value: String
	
	public init(value: String) {
		self.value = value
	}
}
