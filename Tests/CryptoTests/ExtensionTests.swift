//
//  ExtensionTests.swift
//  
//
//  Created by Gal Yedidovich on 17/04/2021.
//

import XCTest
import CryptoExtensions
import CryptoKit

final class ExtensionTests: XCTestCase {
	
	func testXorData() {
		let data = Data("Bubu is the king".utf8)
		
		let xorred = data ^ 10
		let result = Data([72, 127, 104, 127, 42, 99, 121, 42, 126, 98, 111, 42, 97, 99, 100, 109])
		XCTAssertEqual(result, xorred)
		
		let revert = xorred ^ 10
		XCTAssertEqual(data, revert)
	}
	
	func testXorStr() {
		let str = "Bubu is the king"
		
		let xorred = str ^ 5
		XCTAssertEqual("Gpgp%lv%qm`%nlkb", xorred)
		
		let revert = xorred ^ 5
		XCTAssertEqual(str, revert)
	}
	
	func testKeyDataRepresentation() {
		let data = Data("Bubu is the king".utf8)
		let key = SymmetricKey(data: data)
		
		XCTAssertEqual(data, key.dataRepresentation)
	}
}
