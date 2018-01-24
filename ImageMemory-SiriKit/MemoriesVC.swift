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

// NOTES: A MEMORY HAS A THUMBNAIL, IMAGE, AUDIO, & TEXT and are linked by having the same file name with different extensions

class MemoriesVC: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate, AVAudioRecorderDelegate {

    var memories = [URL]()
    var activeMemoryURL: URL!
    var recordingURL: URL!
    var audioRecorder: AVAudioRecorder?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recordingURL = getDocumentDirectory().appendingPathComponent("recording.m4a")
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
            FileManager.default.contentsOfDirectory(at: getDocumentDirectory(), includingPropertiesForKeys: nil, options: [])
            else {
                return
                
        }
        
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
    
    
    // MARK: COLLECTION VIEW
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Dequeue and setup with thumbnail
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        
        let memory = memories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage.init(contentsOfFile: imageName)
        
        cell.imageView.image = image
        
        // Long press
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(imageLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 3
            cell.layer.cornerRadius = 10
        }
        
        return cell
    }
    
    @objc func imageLongPress(sender: UILongPressGestureRecognizer) {
    
    if sender.state == .began {
        let cell = sender.view as! MemoryCell
    
        if let index = collectionView?.indexPath(for:cell) {
                activeMemoryURL = memories[index.row]
                performMicRecordMemory()
        }
    
    } else if sender.state == .ended {
            finishRecording(success: true)
        }
    
}
    
    func performMicRecordMemory() {
        
        // background changes when pressed
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // configure the session for recording and playback
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            
                // set up high quality recording session
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 44100,
                            AVNumberOfChannelsKey: 2,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                            ]
            
            // create the audio recording & assign ourselves as the delegate
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            print("SUCCESSFULLY FINISHED RECORDING 1/2")
            
        } catch let error {
            print("FAILED TO RECORD - ERROR: \(error)")
            finishRecording(success: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        // Link recording & image
        
        // 1
        collectionView?.backgroundColor = UIColor.darkGray
        
        // 2
        audioRecorder?.stop()
        
        if success {
            
            // MOVE THE RECORDING TO THE CORRECT FILE NAME
            do {
                // 3 Create a file url out of the active memory url
                let memoryAudioURL = activeMemoryURL.appendingPathComponent("m4a")
                let fm = FileManager.default
                
                // 4 If the file already exists then delete it because we can't move a file over one that already exists
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                
                // 5 Move recorded file into memories audio url
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                
                //6 Kick off transcription process
                transcribeAudio(memory: activeMemoryURL)
                 print("SUCCESSFULLY FINISHED RECORDING 2/2")
            } catch let error {
                print("FAILURE FINISHING RECORDING - ERROR: \(error)")
            }
        }
        
    }
    
    func transcribeAudio(memory: URL) {
        // Handles transcribing narration into text and linking it to the memory
        
        
    }
    
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }

}


