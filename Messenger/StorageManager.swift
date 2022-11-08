//
//  StorageManager.swift
//  Messenger
//
//  Created by Ayush Bhatt on 25/10/22.
//

import Foundation
import FirebaseStorage
import AVFoundation

final class StorageManager{
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil){metadata, error in
            guard error == nil else{
                print("Failed to upload image to firebase")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("Failed to get download URL")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    public func uploadPicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil){metadata, error in
            guard error == nil else{
                print("Failed to upload image to firebase")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("Failed to get download URL")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    public func uploadVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion){
        let dispatchgroup = DispatchGroup()
        
        dispatchgroup.enter()
        let path = NSTemporaryDirectory() + fileName
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputurl = documentsURL.appendingPathComponent(fileName)
        var ur = outputurl
        self.convertVideo(toMPEG4FormatForVideo: fileUrl as URL, outputURL: outputurl) { (session) in
            
            ur = session.outputURL!
            dispatchgroup.leave()
            
        }
        dispatchgroup.wait()
        
        let data = NSData(contentsOf: ur as URL)
        
        do {
            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)
            
        } catch {
            print(error)
        }
        
        guard let uploadData = data as? Data else{return}
        storage.child("message_videos/\(fileName)").putData(uploadData, metadata: nil){metadata, error in
            guard error == nil else{
                print("Failed to upload video to firebase")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("Failed to get download URL")
                    completion(.failure(StorageError.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    func convertVideo(toMPEG4FormatForVideo inputURL: URL, outputURL: URL, handler: @escaping (AVAssetExportSession) -> Void) {
        let asset = AVURLAsset(url: inputURL as URL, options: nil)
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously(completionHandler: {
            handler(exportSession)
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        reference.downloadURL { url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageError.failedToGetDownloadURL))
                return
            }
            
            completion(.success(url))
        }
    }
    
    public enum StorageError: Error{
        case failedToUpload
        case failedToGetDownloadURL
    }
}
