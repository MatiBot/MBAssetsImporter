//
//  LocalImporter.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/28/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import Foundation
import Photos

class LocalImporter : Importer {
    
    let photosExtensions = ["jpg","png"]
    let videosExtensions = ["mp4","mov"]
    
    var path : String
    var keepOriginal: Bool
    
    init(path:String, keepOriginal:Bool) {
        self.path = path
        self.keepOriginal = keepOriginal
        super.init()
    }
    
    // MARK: Import Methods
    
    func numberOfAssetsInPath(path : String) -> Int{
        var num = 0;
        let enumerator = NSFileManager.defaultManager().enumeratorAtPath(path);
        if(enumerator != nil){
            while let file = enumerator!.nextObject() as? String {
                if (isAsset(file)){
                    num++;
                }
            }
        }
        
        return num;
    }
    
    func importAssets(path : String, numAssets:Int){
        let files = NSFileManager.defaultManager().enumeratorAtPath(path)!.allObjects as! Array<String>
        self.importAssets(0, path: path, files: files, imagesProcessed: 0, numAssets: numAssets)
    }
    
    func importAssets(index : Int, path : String!, files : Array<String>, imagesProcessed : Int, numAssets:Int)
    {
        if(self.shouldContinue == false){
            self.delegate?.onFinish()
            return
        }
        
        let file = files[index]
        let fileURL = path.stringByAppendingPathComponent(file)
        
        let image = UIImage(contentsOfFile: fileURL)
        self.delegate?.onProgress(Float(imagesProcessed) / Float(numAssets), filename: file.lastPathComponent, image:image)
        
        PHPhotoLibrary.requestAuthorization { (status : PHAuthorizationStatus) -> Void in
            
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                
                if(self.isVideo(fileURL)){
                    PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL.fileURLWithPath(fileURL))
                }else if(self.isPhoto(fileURL)){
                    PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(NSURL.fileURLWithPath(fileURL))
                }
                }, completionHandler: { (success : Bool, error : NSError?) -> Void in
                    
                    if(!success && error != nil){
                        self.delegate?.onError(error!)
                        
                    }else if(self.keepOriginal == false){
                        do{
                            try NSFileManager.defaultManager().removeItemAtPath(fileURL)
                        }catch _{
                            
                        }
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if index + 1 < files.count{
                            self.importAssets(index + 1, path: path, files: files, imagesProcessed: imagesProcessed + 1, numAssets: numAssets)
                        }else{
                            self.delegate?.onFinish()
                        }
                    })
            })
        }
    }
    
    override func start(){
        let numAssets = numberOfAssetsInPath(path)
        
        if (numAssets == 0)
        {
            delegate?.onError(NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey:"No assets were found in the specified address"]))
        }
        else{
            delegate?.onProgress(0, filename: "Starting", image: nil)
            self.shouldContinue = true
            importAssets(path, numAssets: numAssets)
            self.delegate?.onStart()
        }
    }
    
    // MARK: Convenient Methods
    
    func isAsset(file : String) -> Bool
    {
        return isPhoto(file) || isVideo(file)
    }
    
    func isPhoto(file : String) -> Bool
    {
        return photosExtensions.contains(file.pathExtension.lowercaseString)
    }
    
    func isVideo(file : String) -> Bool
    {
        return videosExtensions.contains(file.pathExtension.lowercaseString)
    }

}