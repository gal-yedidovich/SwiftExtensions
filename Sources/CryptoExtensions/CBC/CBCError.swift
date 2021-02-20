//
//  CBCError.swift
//  
//
//  Created by Gal Yedidovich on 20/02/2021.
//

import Foundation

internal struct CBCError: LocalizedError {
	let message: String
	let status: Int32
	
	var errorDescription: String? {
		return "CBC Error: \"\(message)\", status: \(status)"
	}
}
