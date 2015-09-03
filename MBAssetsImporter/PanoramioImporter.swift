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

class PanoramioImporter: Importer {
    
    var numberOfPictures : Int
    var task : NSURLSessionDataTask?
    
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
        if task?.state == .Running {
            task?.cancel()
        }
    }
    
    func importPhotos(){
        let url = String(format:"http://www.panoramio.com/map/get_panoramas.php?set=public&from=0&to=%d&minx=-180&miny=-90&maxx=180&maxy=90&size=medium&mapfilter=true",numberOfPictures)
        
        task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: url)!) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
        
            if(data != nil){
                var ret : Dictionary = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0), error:nil) as! Dictionary<String, AnyObject>
                    
                    let photos = ret["photos"] as! Array<Dictionary<String,AnyObject>>
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.importPhotos(photos, index: 0)
                    })

            }else{
                self.delegate?.onFinish()
            }
        }
        
        task?.resume()
    }
    
    func importPhotos(photos:Array<Dictionary<String,AnyObject>>, index:Int){
        if(self.shouldContinue == false || index >= photos.count){
            self.delegate?.onFinish()
            return
        }
        
        let photo = photos[index]
        let photoUrl = photo["photo_file_url"] as! String
        let url = NSURL(string: photoUrl, relativeToURL: nil)
        let data = NSData(contentsOfURL: url!)!
        let image = UIImage(data: data)!
        let title = photo["photo_title"] as! String
        let lat = photo["latitude"] as! Double
        let long = photo["longitude"] as! Double
        let dateStr = photo["upload_date"] as! String
        
        //update delegate with progress
        self.delegate?.onProgress(Float(index+1) / Float(photos.count), filename: title, image:image)
        
        PHPhotoLibrary.requestAuthorization { (status : PHAuthorizationStatus) -> Void in
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                creationRequest.location = CLLocation(latitude: lat, longitude: long)
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "d MMMM yyyy"
                let date = dateFormatter.dateFromString(dateStr)
                creationRequest.creationDate = date
                
                }, completionHandler: { (success : Bool, error : NSError?) -> Void in
                    
                    if(!success && error != nil){
                        self.delegate?.onError(error!)
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if index + 1 < photos.count {
                            self.importPhotos(photos, index: index + 1)
                        }else{
                            self.delegate?.onFinish()
                        }
                    })
            })
        }

    }

}