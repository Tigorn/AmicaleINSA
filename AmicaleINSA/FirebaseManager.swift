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
    // [update]
    var chatVC = ChatViewController.chatViewController
    //var chatVC = ChatViewController.chat
    // [update firebase]
    //private(set) var BASE_REF = Firebase(url: "\(Secret.BASE_URL)")
    private(set) var BASE_REF = FIRDatabase.database().reference()

    // [update firebase]
    /*func createTypingIndicatorRef() -> Firebase {
        return BASE_REF.childByAppendingPath("typingIndicator")
    }*/
    func createTypingIndicatorRef() -> FIRDatabaseReference {
        return BASE_REF.child("typingIndicator")
    }
    
    // [update firebase]
    /*func createActiveUsersRef() -> Firebase {
        return BASE_REF.childByAppendingPath("activeUsers")
    }*/
    func createActiveUsersRef() -> FIRDatabaseReference {
        return BASE_REF.child("activeUsers")
    }

    // [update firebase]
    /*func createMessageRef() -> Firebase {
        return BASE_REF.childByAppendingPath("messages")
    }
     */
    func createMessageRef() -> FIRDatabaseReference {
        return BASE_REF.child("messages")
    }
    
    // [update firebase]
    /*func createPostRef() -> Firebase {
        return BASE_REF.childByAppendingPath("posts")
    }
     */
    func createPostRef() -> FIRDatabaseReference {
        return BASE_REF.child("posts")
    }
    
    func sendMessage(text: String, senderId: String, senderDisplayName: String,
        date: NSDate, image: NSString, isMedia: Bool) {
            let dateTimestamp = date.timeIntervalSince1970
            if (chatVC.shouldUpdateLastTimestamp(dateTimestamp)){
                chatVC.lastTimestamp = dateTimestamp
            }
            let dateString = String(date)
            // [update firebase]
            //let itemRef = BASE_REF.childByAppendingPath("messages").childByAutoId()
        let itemRef = BASE_REF.child("messages").childByAutoId()
            let messageItem = [ // 2
                "text": text,
                "senderId": senderId,
                "senderDisplayName": senderDisplayName,
                "date": dateString,
                "dateTimestamp": dateTimestamp,
                "image": image,
                "isMedia": isMedia,
                "hashValue": "\(senderId)\(dateTimestamp)".md5()
            ]
            itemRef.setValue(messageItem)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            //chatVC.finishSendingMessage()
    }
    
}