//
//  File.swift
//  Extensions
//
//  Created by Gal Yedidovich on 14/06/2020.
//

import Foundation
extension String {
	/// get the localized version of a given string, using the string value as key.
	var localized: String {
		NSLocalizedString(self, comment: self)
	}
}

/// Run a block of code in the main thread, with a delay if exists
/// - Parameters:
///   - delay: time to wait before running the task
///   - block: a completion handler to run in the main thread
public func post(delay: TimeInterval? = nil, block: @escaping ()->()) {
	if let delay = delay {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
	} else {
		DispatchQueue.main.async(execute: block)
	}
}

/// Run a block of code in a backgorund thread, the thread is controlled by iOS's GCD
/// - Parameter block: a completion handler to run in the background
public func async(quality: DispatchQoS.QoSClass = .background, block: @escaping ()->()) {
	DispatchQueue.global(qos: quality).async(execute: block)
}
