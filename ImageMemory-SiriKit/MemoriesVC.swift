//
//  MemoriesVC.swift
//  ImageMemory-SiriKit
//
//  Created by Javid Poornasir on 1/24/18.
//  Copyright © 2018 Javid Poornasir. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesVC: UICollectionViewController {

    var memories = [URL]()
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadMemories()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkPermissions()
    }

   
    func checkPermissions() {
        
        // Check status for all 3 permissions
        
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordinAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        // Make a single Boolean out of all three
        
        let authorized = photosAuthorized && recordinAuthorized && transcribeAuthorized
        
        // If one were missing, show the first run screen
        
        if authorized == false {
            
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun-NCID") {
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    // Loading memories into an array
    // Remove exisiting memories
    // Pull out list of all files in our document directory
    // Iterate over found files, add thumbnails to the memory array
    // Work with URLs
    
    func getDocumentDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func loadMemories() {
        memories.removeAll()
        
        // Attempt to load all the memories in our documents directory
        guard let files = try? // because it may fail if we have missing permissions
            FileManager.default.contentsOfDirectory(at: getDocumentDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        // Loop over every file found
        for file in files {
            let fileName = file.lastPathComponent
            
            // Check it ends with .thumb so we don't count each memory more than once
            if fileName.hasSuffix(".thumb") {
                
                // Get the root name of the memory (ie. without its path extension)
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                // Create a full path from memory
                let memoryPath = getDocumentDirectory().appendingPathComponent(noExtension)
                
                memories.append(memoryPath)
            }
        }
        // Reload our list of memories
            // Section 0 is the search box; 1 is the pictures
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    
    
}
