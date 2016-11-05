//
//  PanoramioImporter.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/28/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import UIKit
import Photos
import Foundation
import CoreLocation

class PixabayImporter: Importer {
    
    var numberOfPictures : Int
    var task : URLSessionDataTask?
    
    init(numberOfPictures : Int) {
        self.numberOfPictures = numberOfPictures
        super.init()
    }
    
    override func start() {
        if (numberOfPictures == 0)
        {
            delegate?.onError(NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey:"Please s"]))
        }
        else{
            delegate?.onProgress(0, filename: "Starting", image: nil)
            self.shouldContinue = true
            importPhotos()
            self.delegate?.onStart()
        }
    }
    
    override func cancel() {
        super.cancel()
        if task?.state == .running {
            task?.cancel()
        }
    }
    
    func importPhotos(){
        let url = String(format:"https://pixabay.com/api/?key=3693221-0fc116c37dd34558929eed174&per_page=\(numberOfPictures)&image_type=photo")
        
        task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) -> Void in

            print("Task completed")
            if let data = data {
                do {
                    var ret : Dictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! Dictionary<String, AnyObject>
                    
                    let photos = ret["hits"] as! Array<Dictionary<String,AnyObject>>
                    
                    OperationQueue.main.addOperation({ () -> Void in
                        self.importPhotos(photos, index: 0)
                    })
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                self.delegate?.onFinish()
            }
        })
        
        task?.resume()
    }
    
    func importPhotos(_ photos:Array<Dictionary<String,AnyObject>>, index:Int){
        if(self.shouldContinue == false || index >= photos.count){
            self.delegate?.onFinish()
            return
        }
        
        let photo = photos[index]
        let photoUrl = photo["userImageURL"] as! String
        let url = URL(string: photoUrl, relativeTo: nil)
        
        if let url = url {
            let data = try! Data(contentsOf: url)
            let image = UIImage(data: data)!
            let title = "Image \(index)" //photo["photo_title"] as! String
            let lat = 1.0//photo["latitude"] as! Double
            let long = 1.0//photo["longitude"] as! Double
            let date = Date.init();//photo["upload_date"] as! String
            
            //update delegate with progress
            self.delegate?.onProgress(Float(index+1) / Float(photos.count), filename: title, image:image)
            
            PHPhotoLibrary.requestAuthorization { (status : PHAuthorizationStatus) -> Void in
                PHPhotoLibrary.shared().performChanges({ () -> Void in
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    creationRequest.location = CLLocation(latitude: lat, longitude: long)
                    
                    creationRequest.creationDate = date
                    
                }, completionHandler: { (success : Bool, error : Error?) -> Void in
                    
                    if(!success && error != nil){
                        self.delegate?.onError(error!)
                    }
                    
                    OperationQueue.main.addOperation({ () -> Void in
                        if index + 1 < photos.count {
                            self.importPhotos(photos, index: index + 1)
                        }else{
                            self.delegate?.onFinish()
                        }
                    })
                })
            }
        } else {
            if index + 1 < photos.count {
                self.importPhotos(photos, index: index + 1)
            }else{
                self.delegate?.onFinish()
            }
        }
    }
}
