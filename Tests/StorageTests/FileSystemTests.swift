//
//  FileSystemTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class FileSystemTests: XCTestCase {
	func testWrite() {
		let str = "Bubu is the king"
		FileSystem.write(data: Data(str.utf8), to: .file)
		
		XCTAssert(FileSystem.fileExists(.file))
		
		let data = FileSystem.read(file: .file)!
		XCTAssert(String(data: data, encoding: .utf8) == str)
		
		FileSystem.delete(file: .file)
	}
	
	func testOverwrite() {
		FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		let newText = "I am Groot"
		FileSystem.write(data: Data(newText.utf8), to: .file)
		
		let fileData = FileSystem.read(file: .file)!
		XCTAssert(String(data: fileData, encoding: .utf8) == newText)
		
		FileSystem.delete(file: .file)
	}
	
	func testDelete() {
		FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		FileSystem.delete(file: .file)
		XCTAssert(!FileSystem.fileExists(.file))
		XCTAssert(!FileManager.default.fileExists(atPath: FileSystem.url(of: .file).path))
	}
	
	static var allTests = [
		("testWrite", testWrite),
		("testOverwrite", testOverwrite),
		("testDelete", testDelete),
	]
}

fileprivate extension Filename {
	static let file = Filename(name: "file1")
}
