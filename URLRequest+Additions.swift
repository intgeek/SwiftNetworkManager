//
//  MutableURLRequest+Additions.swift
//  Newspoint-UseCases
//
//  Created by Shwetabh Singh on 02/07/18.
//  Copyright © 2018 com.til.newspoint. All rights reserved.
//

import Foundation

enum HTTPMethod : String {
	case GET = "GET"
	case POST = "POST"
}

extension URLRequest {
	
	/**
	Defaut url request timeout
	
	- returns timeout interval
	*/
	static func requestTimeoutInterval() -> Double {
		return 30.0
	}
	
	/**
	Create a URLRequestobject
	
	- parameter URL: URL
	- parameter httpmethod: HTTPMethod
	- parameter jsonDictionary: dictionary for request body
	- returns NSMutableURLRequest object
	*/
	static func requestWithUrl(_ url: URL, httpMethod: HTTPMethod, andBody dictionary:[String:Any?]?) -> URLRequest {
		
		var urlRequest: URLRequest = URLRequest.init(url: url)
		urlRequest.timeoutInterval = URLRequest.requestTimeoutInterval()
		urlRequest.httpMethod = httpMethod.rawValue
		
		urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
		
		return urlRequest;
	}
}
