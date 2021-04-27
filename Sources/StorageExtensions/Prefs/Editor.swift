//
//  Editor.swift
//  
//
//  Created by Gal Yedidovich on 15/02/2021.
//

import Foundation
/// An object that operate changes on a linked Prefs instance.
public class Editor {
	private unowned let prefs: Prefs
	private var changes: [String: String?] = [:]
	private var clearFlag = false
	
	/// initialize new instance with linked Prefs instance.
	/// - Parameter prefs: target Prefs to manipulate, depency injection
	internal init(prefs: Prefs) {
		self.prefs = prefs
	}
	
	/// Insert an `Encodable` value to uncommited changes under a given key
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
	
	/// Removes previous uncommited changes by this instance, and raise a `clearFlag` flag,
	/// - Returns: this instance, for method chaining
	public func clear() -> Editor {
		changes = [:]
		self.clearFlag = true
		return self
	}
	
	/// Commit the all uncommited changes in the `changes` dictionary.
	/// This method will notify all observers on the `prefs` instance (unless there were no changes).
	///
	/// - if the `clearFlag` if true, remove all values in the Prefs dctionary.
	/// - if the `changes` dictionary is not empty, override the Prefs dictionary with the changes, including removals.
	/// - in case there are no changes & `clearFlag` is true, delete the Prefs flie
	/// - in case there are changes, they are written to Prefs file asynchronously
	public func commit() {
		guard !changes.isEmpty || clearFlag else { return }
		
		let commit = Commit(changes: changes, clearFlag: clearFlag)
		prefs.strategy.commit(commit)
		prefs.publishChange()
	}
}
