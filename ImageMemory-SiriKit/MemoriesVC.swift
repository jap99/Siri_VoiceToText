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

class MemoriesVC: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var memories = [URL]()
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
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
    
    @objc func addTapped() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    func saveNewMemory(image: UIImage) {
        
        // Create unique name for the memory by time to load in order
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        // Use the unique name to create file names for the full size image and the thumbnail
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        do {
            // Create a URL where we can write the JPEG to
            let imagePath = getDocumentDirectory().appendingPathComponent(imageName)
            
            // Convert UIImage into a JPEG data object
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                
                // Write that data to the URL we've already created
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            // Create thumbnail here
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentDirectory().appendingPathComponent(thumbnailName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
        } catch {
            print("FAILED TO SAVE TO DISK")
        }
        
        
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        
        // Calculate how much we need to bring the width down to match our target size
        let scale = width / image.size.width
        
        // Bring height down by the same amount so aspect ratio's preserved
        let height = image.size.height * scale
        
        // Create a new image context we can draw into with a size we specify
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        // Draw the original image into the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context so UIKit can clean up
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    
    
}
