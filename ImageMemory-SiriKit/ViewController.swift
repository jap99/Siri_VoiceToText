//
//  ViewController.swift
//  ImageMemory-SiriKit
//
//  Created by Javid Poornasir on 1/24/18.
//  Copyright © 2018 Javid Poornasir. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var helpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: PERMISSIONS
    
    // GET PERMISSIONS FOR FOLLOWING FRAMEWORKS
    // AVFoundation - Microphone
    // Photos - User photos
    // Speech - Transcription
    
    func requestPhotoPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermissions()
                } else {
                    self.helpLabel.text = "Photos permission was declined; please enable it in settings then tap Continue again"
                }
            }
        }
    }
    
    func requestRecordPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermissions()
                } else {
                    self.helpLabel.text = "Recording permission was declined; please enable it in settings then tap Continue again"
                }
            }
        }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcribe permission was declined; please enable it in settings then tap Continue again"
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func requestPermissions(_ sender: Any) {
        requestPhotoPermissions()
    }
    
    
    
}

