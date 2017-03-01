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
                // request ok, "response" is an User
            } else if let error = error {
                if let urlResponse = error.urlResponse, urlResponse.statusCode == 401 {
                    // logout user
                } else if let responseObject = error.responseObject as? [String: Any], let errorMessage = responseObject["error_message"] {
                    // show errorMessage
                } else {
                    // show error.originalError.localizedDescription
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

