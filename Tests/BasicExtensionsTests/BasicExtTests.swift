//
//  BasicExtTests.swift
//  
//
//  Created by Gal Yedidovich on 19/12/2020.
//

import XCTest
import CryptoKit
@testable import BasicExtensions

final class BasicExtTests: XCTestCase {
	static let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("hashTest.txt")
	static let content = "Bubu is the king"
	
	override class func setUp() {
		try! Data(content.utf8).write(to: Self.url)
	}
	
	override class func tearDown() {
		try? FileManager.default.removeItem(at: url)
	}
	
	func testHashingFile() throws {
		guard let digest = SHA256.hash(file: Self.url) else { XCTFail("no digest"); return }
		XCTAssertEqual(digest.description, "SHA256 digest: d42254b4047044e74c45083fe483bf6708057d5b4579aae0bca9b30e7376e553")
	}
	
	func testHashingDirectory() throws {
		let dirUrl = Self.url.deletingLastPathComponent().appendingPathComponent("hashDir", isDirectory: true)
		try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: dirUrl) }
		
		let digest = SHA256.hash(file: dirUrl)
		XCTAssertNil(digest)
	}
	
	func testFileSize() {
		guard let fileSize = Self.url.fileSize else { XCTFail("no file size"); return }
		XCTAssertEqual(fileSize, UInt64(Self.content.count))
	}
	
	func testIsDirectory() {
		XCTAssert(!Self.url.isDirectory)
	}
	
	static var allTests = [
		("testHashingFile", testHashingFile),
	]
}
