//
//  WriteStrategies.swift
//  Storage
//
//  Created by Gal Yedidovich on 03/02/2021.
//

import Foundation

internal protocol WriteStrategy {
	func commit(_ commit: Commit, to prefs: Prefs)
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
		
		internal func createStrategy() -> WriteStrategy {
			switch self {
			case .immediate:
				return ImmediateWriteStrategy()
			case .batch(let delay):
				return BatchWriteStrategy(delay: delay)
			}
		}
	}
}

fileprivate struct ImmediateWriteStrategy: WriteStrategy {
	func commit(_ commit: Commit, to prefs: Prefs) {
		prefs.queue.sync {
			prefs.assign(commit)
			prefs.queue.async(execute: prefs.writeOrDelete)
		}
	}
}

fileprivate class BatchWriteStrategy: WriteStrategy {
	private let delay: Double
	private var triggered = false
	
	init(delay: Double) {
		self.delay = delay
	}
	
	func commit(_ commit: Commit, to prefs: Prefs) {
		prefs.queue.sync {
			prefs.assign(commit)
			if triggered { return }
			
			triggered = true
			prefs.queue.asyncAfter(deadline: .now() + delay) { [weak self, weak prefs] in
				guard let self = self, let prefs = prefs else { return }
				
				self.triggered = false
				prefs.writeOrDelete()
			}
		}
	}
}

//MARK: - Helper functions
fileprivate extension Prefs {
	/// Assigns commit changes on the prefs inner dictionary.
	///
	/// This method does not write the changes to the disk.
	/// - Parameters:
	///   - commit: The changes to apply
	///   - prefs: Target `prefs` instance
	func assign(_ commit: Commit) {
		if commit.clearFlag { dict = [:] }
		
		for (key, value) in commit.changes {
			if value == nil { dict.removeValue(forKey: key) }
			else { dict[key] = value }
		}
	}
	
	func writeOrDelete() {
		if dict.isEmpty { delete() }
		else { write() }
	}
	
	func write() {
		do {
			try Filer.write(data: dict.json(), to: filename)
			logger.debug("Updated file: '\(self.filename, privacy: .private(mask: .hash))'")
		} catch {
			logger.error("Failed to write commit into Prefs file '\(self.filename, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
	
	func delete() {
		do {
			try Filer.delete(file: filename)
			logger.debug("Deleted file: '\(self.filename, privacy: .private(mask: .hash))'")
		} catch {
			logger.error("Failed to delete file '\(self.filename, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
}
