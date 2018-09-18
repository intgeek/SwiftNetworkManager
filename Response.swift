//
//  Response.swift
//  Newspoint-UseCases
//
//  Created by Shwetabh Singh on 03/07/18.
//  Copyright © 2018 com.til.newspoint. All rights reserved.
//

import Foundation

let kHTTPRequestDomain = "com.httprequest"

class Response {
	
	// The data received during the request.
	var responseData: Data?
	// The error received during the request.
	var responseError: Error?
	// The dictionary received after parsing the received data.
	var resultDictionary: [String:Any?]?
	// the HTTPURLResponse to check the response status code
	var httpUrlResponse: HTTPURLResponse?
	
	init(_ httpUrlResponse: HTTPURLResponse?, _ response: Data?, _ error: Error?) {
		
		self.httpUrlResponse = httpUrlResponse
		self.responseData = response
		self.responseError = error
		
		// serialize the response data
		do {
			self.resultDictionary = try JSONSerialization.jsonObject(with: self.responseData!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any?]
			if !success {
				self.responseError = self.error()
			}
		} catch let error {
			self.responseError = error
		}
	}
	
	init(_ error: Error) {
		self.responseError = error
	}
	
	//MARK:- getter methods
	/**
	The response status after parsing the received data.
	
	- returns: true if success code return
	*/
	
	var success: Bool {
		get {
			if (self.resultDictionary != nil) {
				return true
			}
			return false
		}
	}
	
	/**
	The responseCode received after parsing the received data.
	
	- returns: get response code from api response data.
	*/
	var statusCode: Int {
		if let httpResponse = self.httpUrlResponse {
			return httpResponse.statusCode
		}
		return -1
	}
	
	/**
	The message received after parsing the received data.
	
	- returns: response message from api response data.
	*/
	func message () -> String {
		return (self.success) ? "Action performed successfully." : "An error occurred while performing this request. Please try again later."
	}
	
	/**
	The responseError received after parsing the received data.
	
	- returns: error if api failed.
	*/
	
	 private func error () -> NSError? {
		
		let mainBundle = Bundle.main.infoDictionary! as NSDictionary
		let errorDict = [NSLocalizedFailureReasonErrorKey: mainBundle["CFBundleName"]! , NSLocalizedDescriptionKey: self.message()]
		let errorReq: NSError = NSError(domain: kHTTPRequestDomain, code: self.statusCode, userInfo: errorDict)
		return errorReq
	}
}
