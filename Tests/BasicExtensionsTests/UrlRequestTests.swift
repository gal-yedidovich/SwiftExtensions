//
//  UrlRequestTests.swift
//  
//
//  Created by Gal Yedidovich on 19/06/2020.
//

import XCTest
@testable import BasicExtensions

final class UrlRequestTests: XCTestCase {
	func testGet() {
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/1")

		send(req, type: Post.self) { result in
			switch result {
				case .success(let post): XCTAssert(post.id == 1)
				default: XCTFail()
			}
		}
	}
	
	func testPost() {
		let localPost = Post(userId: 12, id: -1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts")
			.set(method: .POST)
			.set(contentType: .json)
			.set(body: localPost.json())
		
		send(req, type: Post.self) { result in
			switch result {
				case .success(let newPost): XCTAssert(newPost.title == localPost.title)
				default: XCTFail()
			}
		}
	}
	
	func testPut() {
		let localPost = Post(userId: 1, id: 1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/1")
			.set(method: .PUT)
			.set(contentType: .json)
			.set(body: localPost.json())
		
		send(req, type: Post.self) { result in
			switch result {
				case .success(let newPost): XCTAssert(newPost.title == localPost.title)
				default: XCTFail()
			}
		}
	}
	
	func testPatch() {
		let changes = ["title": "testi"]
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/4")
			.set(method: .PATCH)
			.set(contentType: .json)
			.set(body: changes.json())
		
		send(req, type: Post.self) { result in
			switch result {
				case .success(let patchedPost): XCTAssert(patchedPost.title == changes["title"])
				default: XCTFail()
			}
		}
	}
	
	func testDelete() {
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/1")
			.set(method: .DELETE)
		
		send(req, type: StringDict.self) { result in
			switch result {
				case .success(let dict): XCTAssert(dict.isEmpty)
				default: XCTFail()
			}
		}
	}
	
	private func send<T: Decodable>(_ request: URLRequest, type: T.Type, completion: @escaping (Result<T, StringDict>) -> ()) {
		let expectation = XCTestExpectation(description: "waiting for request")
		
		URLSession.shared.dataTask(with: request) { (result: Result<T, StringDict>) in
			print(" - ", result.debugValue)
			completion(result)
			expectation.fulfill()
		}.resume()
		
		wait(for: [expectation], timeout: 10)
	}
	
	static let allTests = [
		("testGet", testGet),
		("testPost", testPost),
		("testPut", testPut),
		("testPatch", testPatch),
		("testDelete", testDelete),
	]
	
	struct Post: Codable {
		let userId: Int
		let id: Int
		let title: String
		let body: String
	}
	
	private typealias StringDict = [String: String]
}
