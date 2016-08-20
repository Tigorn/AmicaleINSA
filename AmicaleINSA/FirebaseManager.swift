//
//  FirebaseManager.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Foundation
import Firebase
import JSQMessagesViewController
import CryptoSwift

class FirebaseManager {
    
    static let firebaseManager = FirebaseManager()
    
    private let PATH_CHAT_IMAGE = "chat/"
    var chatVC = ChatViewController.chatViewController
    private(set) var BASE_REF = FIRDatabase.database().reference()
    
    // Storage
    let storageRef = FIRStorage.storage().referenceForURL(Secret.FIREBASE_STORAGE_BUCKET)

    func createTypingIndicatorRef() -> FIRDatabaseReference {
        return BASE_REF.child("typingIndicator")
    }
    
    func createActiveUsersRef() -> FIRDatabaseReference {
        return BASE_REF.child("activeUsers")
    }

    func createMessageRef() -> FIRDatabaseReference {
        return BASE_REF.child("messages")
    }
    
    func createPostRef() -> FIRDatabaseReference {
        return BASE_REF.child("posts")
    }
    
    // Storage reference
    func createStorageRef() -> FIRStorageReference {
        return storageRef
    }
    
    func createStorageRefChat(nameImage: String) -> FIRStorageReference {
        return storageRef.child(PATH_CHAT_IMAGE+nameImage+".jpg")
    }
    
    func sendMessageFirebase2(text: String, senderId: String, senderDisplayName: String,
                              date: NSDate, isMedia: Bool, imageURL: String) {
        let dateTimestamp = date.timeIntervalSince1970
        if (chatVC.shouldUpdateLastTimestamp(dateTimestamp)){
            chatVC.lastTimestamp = dateTimestamp
        }
        let imageData = UIImagePNGRepresentation(UIImage(named: "Update_your_app")!)
        var base64StringImageUpdateYourApp = ""
        if isMedia {
            base64StringImageUpdateYourApp = imageData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        }
        let dateString = String(date)
        let itemRef = BASE_REF.child("messages").childByAutoId()
        let messageItem = [ // 2
            "text": text,
            "senderId": senderId,
            "senderDisplayName": senderDisplayName,
            "date": dateString,
            "dateTimestamp": dateTimestamp,
            "isMedia": isMedia,
            "hashValue": "\(senderId)\(dateTimestamp)".md5(),
            "imageURL": imageURL,
            "image": base64StringImageUpdateYourApp
        ]
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
    }
    
    func sendMessage(text: String, senderId: String, senderDisplayName: String,
        date: NSDate, isMedia: Bool) {
            let dateTimestamp = date.timeIntervalSince1970
            if (chatVC.shouldUpdateLastTimestamp(dateTimestamp)){
                chatVC.lastTimestamp = dateTimestamp
            }
            let dateString = String(date)
        let itemRef = BASE_REF.child("messages").childByAutoId()
            let messageItem = [ // 2
                "text": text,
                "senderId": senderId,
                "senderDisplayName": senderDisplayName,
                "date": dateString,
                "dateTimestamp": dateTimestamp,
                "isMedia": isMedia,
                "hashValue": "\(senderId)\(dateTimestamp)".md5(),
                "imageURL": "",
                "image": ""
            ]
            itemRef.setValue(messageItem)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
    }
    
}