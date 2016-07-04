//
//  ViewController.swift
//  MBAssetsImporter
//
//  Created by Mati Bot on 7/27/15.
//  Copyright © 2015 Mati Bot. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class MBAssetsImporterViewController: UIViewController, ImporterDelegate {
    
    // MARK: Default Configuration
    
    let defaultAddress = "/Users/mati/Desktop/photos_folder"
    
    // MARK: IBOutlet properties
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var setupView: UIView!
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var circularProgressBar: MBCircularProgressBarView!
    @IBOutlet weak var keepOriginal: UISwitch!
    @IBOutlet weak var importPathTextfield: UITextField!
    @IBOutlet weak var remoteImportCount: UITextField!
    @IBOutlet weak var background: UIImageView!
    
    // MARK: Properties
    
    var importer: Importer?
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.importPathTextfield.text = defaultAddress
        
        if TARGET_IPHONE_SIMULATOR != 1 {
            self.importPathTextfield.enabled = false
            keepOriginal.enabled = false
        }else{
            let dummyView = UIView(frame: CGRectMake(0, 0, 0, 0))
            importPathTextfield.inputView = dummyView;
            remoteImportCount.inputView = dummyView
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: IBActions

    @IBAction func cancelAction(sender: UIButton) {
        importer?.cancel()
    }
    
    @IBAction func importLocal(sender: UIButton) {
        
        if TARGET_IPHONE_SIMULATOR == 1 {
            let path = self.importPathTextfield.text;
            importer = LocalImporter(path: path!, keepOriginal: keepOriginal.on)
            importer?.delegate = self
            importer?.start()
        }else{
            let alertController = UIAlertController(title: "", message: "Please run the app on the iOS simulator in order to import assets from a local directory", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion:nil)
        }
    }
    
    @IBAction func importFlickr(sender: UIButton) {
        let count = Int(remoteImportCount.text!)
        importer = PanoramioImporter(numberOfPictures: count!)
        importer?.delegate = self
        importer?.start()
    }
    
    // MARK: ImporterDelegate
    
    func onStart(){
        view.endEditing(true)
        self.progressView.hidden = false
        self.setupView.hidden = true
    }
    
    func onFinish(){
        self.circularProgressBar.value = 0;
        self.progressView.hidden = true
        self.setupView.hidden = false
        importer = nil
    }
    
    func onProgress(progress:Float, filename:String, image:UIImage?){
        self.circularProgressBar.value = 100 * CGFloat(progress)
        self.fileLabel.text = filename
        if(image != nil){
            self.background.image = image
        }
    }
    
    func onError(error:NSError){
        print(error.localizedDescription)
    }
    
    //Calls this function when the tap is recognized.
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

