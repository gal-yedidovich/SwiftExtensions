//
//  File.swift
//  
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

public extension Prefs {
	/// The Strategy to write to the prefs file in storage.
	///
	/// There are two Strategies:
	///  - `default`: write every commit immediately to storage, it consumes more resources when when there are a lot of comming in succession.
	///  - `batch`: writes all applied commits after a delay, it will reduce wrtie calls to file system when applying  large number of commits.
	enum WritingStrategy {
		case `default`
		case batch(delay: Double)
		
		static let batch = WritingStrategy.batch(delay: 0.5)
		
		func createStrategy(for prefs: Prefs) -> WriteStrategy {
			switch self {
			case .default:
				return QueueStrategy(prefs: prefs)
			case .batch(let delay):
				return BatchStrategy(prefs: prefs, delay: delay)
			}
		}
	}
}

internal struct QueueStrategy: WriteStrategy {
	unowned let prefs: Prefs
	
	func commit(_ commit: Commit) {
		prefs.queue.sync { //sync changes
			if commit.clearFlag { prefs.dict = [:] }
			
			for (key, value) in commit.changes {
				if value == nil { prefs.dict.removeValue(forKey: key) }
				else { prefs.dict[key] = value }
			}
			
			if prefs.dict.isEmpty {
				delete(prefs)
			} else {
				write(to: prefs)
			}
		}
	}
}

internal class BatchStrategy: WriteStrategy {
	unowned let prefs: Prefs
	private let delay: Double
	private var triggered = false
	
	init(prefs: Prefs, delay: Double) {
		self.prefs = prefs
		self.delay = delay
	}
	
	func commit(_ commit: Commit) {
		prefs.queue.sync {
			if commit.clearFlag { prefs.dict = [:] }
			
			for (key, value) in commit.changes {
				if value == nil { prefs.dict.removeValue(forKey: key) }
				else { prefs.dict[key] = value }
			}
			
			if !triggered {
				triggered = true
				prefs.queue.asyncAfter(deadline: .now() + delay, execute: writeBatch)
			}
		}
	}
	
	private func writeBatch() {
		triggered = false
		
		if prefs.dict.isEmpty {
			delete(prefs)
		} else {
			write(to: prefs)
		}
	}
}

fileprivate func write(to prefs: Prefs) {
	do {
		try FileSystem.write(data: prefs.dict.json(), to: prefs.filename)
	} catch {
		print("could not write to \"prefs\" file.")
		print(error)
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
