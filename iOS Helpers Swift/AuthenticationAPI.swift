//
//  UserAPI.swift
//  iOS Helpers Swift
//
//  Created by Jota Melo on 15/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

struct User: Mappable {
    init(mapper: Mapper) { }
}

class AuthenticationAPI: APIRequest {

    override init(method: API.HTTPMethod, path: String, parameters: [String : Any]?, urlParameters: [String : Any]?, cacheOption: API.CacheOption, completion: ResponseBlock<Any>?) {
        super.init(method: method, path: path, parameters: parameters, urlParameters: urlParameters, cacheOption: cacheOption, completion: completion)
        
        self.baseURL = URL(string: "https://mansaothugstronda.com/api/v1")!
    }
    
    @discardableResult
    static func loginWith(username: String, password: String, callback: ResponseBlock<User>?) -> AuthenticationAPI {
        
        let request = AuthenticationAPI(method: .post, path: "login", parameters: ["username": username, "password": password], urlParameters: nil, cacheOption: .networkOnly) { (response, error, cache) in
            
            if let error = error {
                print(error.responseObject ?? "nil")
            } else if let response = response as? [String: Any] {
                let user = User(dictionary: response)
                callback?(user, nil, cache)
            }
        }
        request.shouldSaveInCache = false
        
        request.makeRequest()
        return request
    }
}
