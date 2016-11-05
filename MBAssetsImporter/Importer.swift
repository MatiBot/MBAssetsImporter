//
//  Importer.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/28/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import UIKit
import Foundation

protocol ImporterDelegate : NSObjectProtocol{
    func onError(_ error:Error)
    func onStart()
    func onFinish()
    func onProgress(_ progress:Float, filename:String, image:UIImage?)
}

class Importer {
    
    // MARK: Properties
    
    weak var delegate:ImporterDelegate?
    var shouldContinue: Bool = true
    
    init() {
        delegate = nil
    }
    
    func start(){
        preconditionFailure("This method must be overridden")
    }
    
    func cancel(){
        shouldContinue = false
    }
}
