// Project: LingoChatBE
//
// Created on Sunday, June 02, 2019.
// 

import Vapor

extension Future where T: Content {
	
	func withStatus(_ status: HTTPStatus, using request: Request) -> Future<Response> {
		
		return self.map { value in
			let response = request.response(http: .init(status: status))
			try response.content.encode(value)
			return response
		}
	}
}
