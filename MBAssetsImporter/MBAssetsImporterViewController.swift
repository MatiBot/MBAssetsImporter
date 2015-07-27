//
//  ViewController.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/27/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import UIKit
import Photos
import MBCircularProgressBar

class MBAssetsImporterViewController: UIViewController {
    
    // MARK: Default Configuration
    
    let photosExtensions = ["jpg","png"]
    let videosExtensions = ["mp4","mov"]
    let defaultAddress = "/Users/mati/Desktop/photos_folder"
    
    // MARK: IBOutlet properties
    
    @IBOutlet var progressView: UIView!
    @IBOutlet weak var setupView: UIView!
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var circularProgressBar: MBCircularProgressBarView!
    @IBOutlet weak var keepOriginal: UISwitch!
    @IBOutlet weak var importPathTextfield: UITextField!
    
    
    // MARK: Properties
    
    var shouldContinue: Bool = true

    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.importPathTextfield.text = defaultAddress
    }
    
    // MARK: IBActions

    @IBAction func cancelAction(sender: UIButton) {
        self.shouldContinue = false;
    }
    
    @IBAction func `import`(sender: UIButton) {
        
        let path = self.importPathTextfield.text;
        let numAssets = numberOfAssetsInPath(path!)
        
        if (numAssets == 0)
        {
            let alertController = UIAlertController(title: "", message: "There are no assets in the specified path", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion:nil)
            
            updateScreen(false)
        }else{
            self.shouldContinue = true
            self.circularProgressBar.percent = 0.0
            updateScreen(true);
            importAssets(path!, numAssets: numAssets)
        }
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
        let enumerator = NSFileManager.defaultManager().enumeratorAtPath(path)!;
        let file : String = enumerator.nextObject() as! String
        importAssets(file, path: path, enumerator: enumerator, imagesProcessed: 0, numAssets: numAssets)
    }
    
    func importAssets(file : String! ,path : String!, enumerator : NSDirectoryEnumerator, var imagesProcessed : Int, numAssets:Int)
    {
        if(self.shouldContinue == false){
            updateScreen(false)
            return
        }
        
        self.fileLabel.text = file.lastPathComponent
        
        PHPhotoLibrary.requestAuthorization { (status : PHAuthorizationStatus) -> Void in
            let fileURL = path.stringByAppendingPathComponent(file)
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
    
                if(self.isVideo(fileURL)){
                    PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL.fileURLWithPath(fileURL))
                }else if(self.isPhoto(fileURL)){
                    PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(NSURL.fileURLWithPath(fileURL))
                }
                }, completionHandler: { (success : Bool, error : NSError?) -> Void in
                    
                    if(!success && error != nil){
                        
                        let alertController = UIAlertController(title: "", message: error?.localizedDescription, preferredStyle: .Alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(alertController, animated: true, completion:nil)
                        
                    }else if(self.keepOriginal.on == false){
                        do{
                            try NSFileManager.defaultManager().removeItemAtPath(fileURL)
                        }catch _{
                            
                        }
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.circularProgressBar.percent = 100 * CGFloat(imagesProcessed) / CGFloat(numAssets)
                        if let file = enumerator.nextObject() as? String{
                            self.importAssets(file, path: path, enumerator: enumerator, imagesProcessed: ++imagesProcessed, numAssets: numAssets)
                        }else{
                            self.updateScreen(false)
                        }
                    })
            })
        }
    }
    
    func updateScreen(isImporting : Bool)
    {
        if (isImporting)
        {
            self.progressView.hidden = false
            self.setupView.hidden = true
        }
        else
        {
            self.progressView.hidden = true
            self.setupView.hidden = false
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

