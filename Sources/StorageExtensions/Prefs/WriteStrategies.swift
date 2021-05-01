//
//  WriteStrategies.swift
//  Storage
//
//  Created by Gal Yedidovich on 03/02/2021.
//

import Foundation

internal protocol WriteStrategy {
	func commit(_ commit: Commit)
}

internal struct Commit {
	let changes: [String: String?]
	let clearFlag: Bool
}

internal let DEFAULT_BATCH_DELAY = 0.1

public extension Prefs {
	/// The Strategy of writing the prefs to storage.
	///
	/// There are two Strategies:
	///  - `immediate`: writes every commit immediately to storage, it will consume more resources when when applying large number of commits.
	///  - `batch`: writes all applied commits after a delay, it will reduce 'write' calls to the file-system when applying large number of commits.
	enum WriteStrategyType {
		/// Write every commit immediately to storage
		case immediate
		/// Batch commits together after a defined delay
		case batch(delay: Double)
		
		/// default batch strategy with delay of 0.1 seconds
		public static let batch = Self.batch(delay: DEFAULT_BATCH_DELAY)
		
		internal func createStrategy(for prefs: Prefs) -> WriteStrategy {
			switch self {
			case .immediate:
				return ImmediateWriteStrategy(prefs: prefs)
			case .batch(let delay):
				return BatchWriteStrategy(prefs: prefs, delay: delay)
			}
		}
	}
}

fileprivate struct ImmediateWriteStrategy: WriteStrategy {
	fileprivate unowned let prefs: Prefs
	
	func commit(_ commit: Commit) {
		prefs.queue.sync { //sync changes
			apply(commit, on: prefs)
			
			prefs.queue.async {
				writeOrDelete(prefs)
			}
		}
	}
}

fileprivate class BatchWriteStrategy: WriteStrategy {
	private unowned let prefs: Prefs
	private let delay: Double
	private var triggered = false
	
	init(prefs: Prefs, delay: Double) {
		self.prefs = prefs
		self.delay = delay
	}
	
	func commit(_ commit: Commit) {
		prefs.queue.sync {
			apply(commit, on: prefs)
			
			if !triggered {
				triggered = true
				prefs.queue.asyncAfter(deadline: .now() + delay) { [weak self] in
					self?.writeBatch()
				}
			}
		}
	}
	
	private func writeBatch() {
		triggered = false
		writeOrDelete(prefs)
	}
}

//MARK: - Helper functions

/// Applies commit changes on the prefs inner dictionary.
///
/// This method does not write the changes to the disk.
/// - Parameters:
///   - commit: The changes to apply
///   - prefs: Target `prefs` instance
fileprivate func apply(_ commit: Commit, on prefs: Prefs) {
	if commit.clearFlag { prefs.dict = [:] }
	
	for (key, value) in commit.changes {
		if value == nil { prefs.dict.removeValue(forKey: key) }
		else { prefs.dict[key] = value }
	}
}

fileprivate func writeOrDelete(_ prefs: Prefs) {
	if prefs.dict.isEmpty {
		delete(prefs)
	} else {
		write(prefs)
	}
}

fileprivate func write(_ prefs: Prefs) {
	do {
		try FileSystem.write(data: prefs.dict.json(), to: prefs.filename)
	} catch {
		print("could not write to \"prefs\" file.")
		print(error.localizedDescription)
	}
}

fileprivate func delete(_ prefs: Prefs) {
	do {
		try FileSystem.delete(file: prefs.filename)
	} catch {
		print("could not delete \"prefs\" file.")
		print(error)
	}
}
