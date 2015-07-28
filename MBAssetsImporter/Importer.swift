//
//  Importer.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/28/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import Foundation

protocol ImporterDelegate : NSObjectProtocol{
    func onError(error:NSError)
    func onStart()
    func onFinish()
    func onProgress(progress:Float, filename:String)
}

class Importer {
    
    init() {
        delegate = nil
    }
    
    func start(){
        preconditionFailure("This method must be overridden")
    }
    
    func cancel(){
        shouldContinue = false
    }
    
    weak var delegate:ImporterDelegate?
    
    // MARK: Properties
    
    var shouldContinue: Bool = true
}