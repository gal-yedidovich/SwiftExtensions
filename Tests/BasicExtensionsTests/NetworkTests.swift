//
//  UrlRequestTests.swift
//  
//
//  Created by Gal Yedidovich on 19/06/2020.
//

import XCTest
@testable import BasicExtensions

final class UrlRequestTests: XCTestCase {
	let baseURL = "https://jsonplaceholder.typicode.com/posts"
	
	func testGet() {
		let req = URLRequest(url: baseURL + "/1")

		send(req, type: Post.self) { post in
			XCTAssertEqual(post.id, 1)
		}
	}
	
	func testPost() {
		let localPost = Post(userId: 12, id: -1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: baseURL)
			.set(method: .POST)
			.set(contentType: .json)
			.set(body: localPost.json())
		
		send(req, type: Post.self) { newPost in
			XCTAssertEqual(newPost.title, localPost.title)
		}
	}
	
	func testPut() {
		let localPost = Post(userId: 1, id: 1, title: "Bubu is the king", body: "I am Groot!")
		let req = URLRequest(url: baseURL + "/1")
			.set(method: .PUT)
			.set(contentType: .json)
			.set(body: localPost.json())
		
		send(req, type: Post.self) { newPost in
			XCTAssertEqual(newPost.title, localPost.title)
		}
	}
	
	func testPatch() {
		let changes = ["title": "testi"]
		let req = URLRequest(url: baseURL + "/4")
			.set(method: .PATCH)
			.set(contentType: .json)
			.set(body: changes.json())
		
		send(req, type: Post.self) { patchedPost in
			XCTAssertEqual(patchedPost.title, changes["title"])
		}
	}
	
	func testDelete() {
		let req = URLRequest(url: baseURL + "/1").set(method: .DELETE)
		
		send(req, type: StringDict.self) { dict in
			XCTAssert(dict.isEmpty)
		}
	}
	
	private func send<Value: Decodable>(_ request: URLRequest, type: Value.Type, test: @escaping (Value) -> Void) {
		let expectation = XCTestExpectation(description: "waiting for request")
		
		let token = URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response in
				guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode / 100 == 2 else {
					throw URLError(.badServerResponse)
				}
				return data
			}
			.decode(type: Value.self, decoder: JSONDecoder())
			.sink { completion in
				if case .failure(let error) = completion {
					XCTFail("error: \(error)")
				}
				expectation.fulfill()
			} receiveValue: { value in
				test(value)
			}
		
		wait(for: [expectation], timeout: 10)
		token.cancel()
	}
	
	struct Post: Codable {
		let userId: Int
		let id: Int
		let title: String
		let body: String
	}
	
	private typealias StringDict = [String: String]
}
