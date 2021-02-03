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
	private var pendingCommits: [Commit] = []
	private let delay: Double
	
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
			
			
			pendingCommits.append(commit)
			if pendingCommits.count == 1 {
				prefs.queue.asyncAfter(deadline: .now() + delay, execute: writeBatch)
			}
		}
	}
	
	private func writeBatch() {
		pendingCommits = []
		
		if prefs.dict.isEmpty {
			delete(prefs)
		} else {
			write(to: prefs)
		}
	}
}
