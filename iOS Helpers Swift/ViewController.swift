//
//  ViewController.swift
//  iOS Helpers Swift
//
//  Created by Jota Melo on 14/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AuthenticationAPI.loginWith(username: "test", password: "test") { (response, error, cache) in
            
            if let response = response {
                // request ok, "response" is a User
            } else if let error = error, case let API.RequestError.error(responseObject, urlResponse, originalError) = error {
                if let urlResponse = urlResponse, urlResponse.statusCode == 401 {
                    // logout user
                } else if let responseObject = responseObject as? [String: Any], let errorMessage = responseObject["error_message"] {
                    // show "errorMessage"
                } else {
                    // show originalError.localizedDescription
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

