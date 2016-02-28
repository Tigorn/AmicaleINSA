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
    var chatVC = ChatViewController.chatViewController
    private(set) var BASE_REF = Firebase(url: "\(Secret.BASE_URL)")
    
    func createTypingIndicatorRef() -> Firebase {
        return BASE_REF.childByAppendingPath("typingIndicator")
    }
    
    func createMessageRef() -> Firebase {
        return BASE_REF.childByAppendingPath("messages")
    }
    
    func sendMessage(text: String, senderId: String, senderDisplayName: String,
        date: NSDate, image: NSString, isMedia: Bool) {
            let dateTimestamp = date.timeIntervalSince1970
            if (chatVC.shouldUpdateLastTimestamp(dateTimestamp)){
                chatVC.lastTimestamp = dateTimestamp
            }
            let dateString = String(date)
            let itemRef = BASE_REF.childByAppendingPath("messages").childByAutoId()
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