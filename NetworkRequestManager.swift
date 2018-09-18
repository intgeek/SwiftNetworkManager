//
//  NetworkRequestManager.swift
//  Newspoint-UseCases
//
//  Created by Shwetabh Singh on 02/07/18.
//  Copyright © 2018 com.til.newspoint. All rights reserved.
//

import Foundation
import Reachability

enum HTTPRequestErrorCode: Int {
	case httpConnectionError = 40 // Trouble connecting to Server.
}

final class NetworkRequestManager {
	
	//MARK:- shared instance
	private static let sharedInstance = NetworkRequestManager()
	
	class func sharedManager() -> NetworkRequestManager {
		return sharedInstance
	}
	
	private init(){}

	//MARK:- class variables
	private var urlSession: URLSession?
	private var runningUrlRequests: NSSet?
	static var networkFetchingCount: Int = 0
	
	//MARK:- network activity methods
	static func beginNetworkActivity() {
		networkFetchingCount = networkFetchingCount + 1
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}
	
	static func endNetworkActivity() {
		if networkFetchingCount > 0 {
			networkFetchingCount = networkFetchingCount - 1
		} else if networkFetchingCount == 0 {
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
		}
	}
	
	//MARK:- URLSession and perform request methods
	private func createUrlSession() -> URLSession {
		if urlSession == nil {
			urlSession = URLSession.init(configuration: URLSessionConfiguration.default)
		}
		return urlSession!
	}
	
	func performRequest(_ method: HTTPMethod, _ urlString: String?, withCompletion handler: @escaping (_ response:Response) -> Void) {
		if method == HTTPMethod.GET {
			if (urlString != nil) {
				
				let request = URLRequest.requestWithUrl(URL.init(string: urlString!)!, httpMethod: method, andBody: nil)
				
				guard isNetworkReachable() else {
					let resError = errorForNoNetwork()
					let res = Response.init(resError)
					handler(res)
					return
					
				}
				self.performNetworkRequest(request, handler)
			} else {
				
				let resError: Error = errorForInvalidURL()
				let res = Response.init(resError)
				handler(res)
				
			}
		}
	}
	
	func performNetworkRequest(_ request: URLRequest, _ handler: @escaping (_ response: Response) -> Void) {
		NetworkRequestManager.beginNetworkActivity()
		self.addRequestedUrl(request.url!)
		let session = self.createUrlSession()
		
		session.dataTask(with: request) { (data, urlResponse, error) in
			
			NetworkRequestManager.endNetworkActivity()
			
			var responseError = error
			let httpResponse = urlResponse as? HTTPURLResponse
			
			// handle http response status
			if let httpResponse = urlResponse as? HTTPURLResponse {
				if httpResponse.statusCode > 200 {
					responseError = self.errorForStatus(httpResponse.statusCode)
				}
			}
			
			var apiResponse: Response?
			if let _ = responseError {
				// case of our response code was error
				apiResponse = Response.init(responseError!)
			} else {
				// successful response
				apiResponse = Response.init(httpResponse, data, error)
				
				// case check if serialization failed
				if !(apiResponse!.success) {
					apiResponse = Response.init(apiResponse!.responseError!)
				}
			}
			
			self.removeRequestedURL(request.url!)
			
			DispatchQueue.global().async (execute: { () -> Void in
				handler(apiResponse!)
			})
			
			}.resume()
		}
}

//MARK:- UrlRequest handing methods
extension NetworkRequestManager {
	private func addRequestedUrl(_ url: URL) {
		objc_sync_enter(self)
		let requests: NSMutableSet = self.runningRequests() as! NSMutableSet
		requests.add(url)
		runningUrlRequests = requests
		objc_sync_exit(self)
	}
	
	private func removeRequestedURL (_ url: URL) {
		objc_sync_enter(self)
		let requests: NSMutableSet = self.runningRequests() as! NSMutableSet
			if(requests.contains(url) == true) {
				requests.remove(url)
				runningUrlRequests = requests
		}
		objc_sync_exit(self)
	}
	
	private func runningRequests() -> NSSet {
		if runningUrlRequests == nil {
			runningUrlRequests = NSSet.init()
		}
		return runningUrlRequests!
	}
	
	private func isProcessingURL (_ url: URL) -> Bool {
		return self.runningRequests().contains(url)
	}
	
	func cancelAllRequests () {
		self.urlSession?.invalidateAndCancel()
		urlSession = nil
		runningUrlRequests = nil
	}
}


//MARK:- Error handling methods

extension NetworkRequestManager {
	
	private func errorForInvalidURL () -> Error {
		return NSError(domain: NSURLErrorDomain , code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "URL must not be nil"])
	}
	
	private func errorForNoNetwork () -> Error {
		return NSError(domain: NSURLErrorDomain, code: HTTPRequestErrorCode.httpConnectionError.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Network not available"])
	}
	
	/**
	Create an error for response you probably don't want (400-500 HTTP responses for example).
	
	- parameter code: Code for error.
	
	- returns: An NSError.
	*/
	private func errorForStatus(_ code: Int) -> NSError {
		let text = HTTPStatusCode(statusCode: code).statusDescription
		return NSError(domain: "HTTP", code: code, userInfo: [NSLocalizedDescriptionKey: text])
	}
}

//MARK:- Network reachability extension
extension NetworkRequestManager {
	
	/**
	returns wheather internet connection is available
	
	- returns: boolean
	*/
	private func isNetworkReachable() -> Bool {
		let reachable: Reachability = Reachability.forInternetConnection()
		return reachable.currentReachabilityStatus() != .NotReachable
	}
}

