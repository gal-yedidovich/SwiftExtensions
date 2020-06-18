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

		send(req) { response in
			let post: Post = .from(json: response!)
			XCTAssert(post.id == 1)
		}
	}
	
	func testPost() {
		let localPost = Post(userId: 12, id: -1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts")
			.set(method: .POST)
			.set(contentType: .json)
			.set(body: localPost.json())

		send(req) { response in
			let newPost: Post = .from(json: response!)
			XCTAssert(newPost.title == localPost.title)
		}
	}
	
	func testPut() {
		let localPost = Post(userId: 1, id: 1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/1")
			.set(method: .PUT)
			.set(contentType: .json)
			.set(body: localPost.json())

		send(req) { response in
			let newPost: Post = .from(json: response!)
			XCTAssert(newPost.title == localPost.title)
		}
	}
	
	func testPatch() {
		let changes = ["title": "testi"]
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/4")
			.set(method: .PATCH)
			.set(contentType: .json)
			.set(body: changes.json())

		send(req) { response in
			let patchedPost: Post = .from(json: response!)
			XCTAssert(patchedPost.title == changes["title"])
		}
	}
	
	func testDelete() {
		let req = URLRequest(url: "https://jsonplaceholder.typicode.com/posts/1")
			.set(method: .DELETE)
		
		send(req) { response in
			XCTAssert(response == "{}".data(using: .utf8)!)
		}
	}
	
	private func send(_ request: URLRequest, comletion: @escaping (Data?)->()) {
		let expectation = XCTestExpectation(description: "waiting for request")

		URLSession.shared.dataTask(with: request) { d, r, e in
			print(String(data: d!, encoding: .utf8)!)
			comletion(d)
			expectation.fulfill()
		}.resume()
		
		wait(for: [expectation], timeout: 10)
	}
	
	struct Post: Codable {
		let userId: Int
		let id: Int
		let title: String
		let body: String
	}
}
