//
//  ChatViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import SVPullToRefresh
import MobileCoreServices
import MediaPlayer
import NYTPhotoViewer
import ALCameraViewController
import ImagePicker
import SWRevealViewController
import MBProgressHUD
import Kingfisher
import Popover
import FirebaseStorage


class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MenuControllerDelegate, ImagePickerDelegate,JSQMessagesViewControllerScrollingDelegate {
    
    private var popover: Popover!
    private var connectedUsers = [String]()
    private var popoverOptions: [PopoverOption] = [
        .Type(.Down),
        .BlackOverlayColor(UIColor(white: 0.0, alpha: 0.6))
    ]
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var myActivityIndicatorHUD = MBProgressHUD()
    
    var messages = [JSQMessage]()
    var messagesHashValue = [String]()
    
    var delegate : ChatViewController?
    
    static let chatViewController : ChatViewController = {
        return ChatViewController()
    }()
    
    let LOG = false
    let shouldDisplayAvatar = true
    var uuidHash: String!
    var isAdminChat = false
    var listMastersChat = [MasterChat]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var messageRef: FIRDatabaseReference!
    var firebaseRef = FIRDatabase.database().reference()
    
    var lastTimestamp: NSTimeInterval!
    let LOAD_MORE_MESSAGE_LIMIT  = UInt(60)
    let INITIAL_MESSAGE_LIMIT = UInt(60)
    var userIsTypingRef: FIRDatabaseReference!
    private var localTyping = false
    
    let timeIntervalBetweenMessages = 20*60
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    struct MasterChat {
        var username = ""
        var id = ""
        var type = "iOS"
    }
    
    var timer = NSTimer()
    
    let imagePicker = UIImagePickerController()
    var usersTypingQuery: FIRDatabaseQuery!
    
    private func observeTyping() {
        let typingIndicatorRef = FirebaseManager.firebaseManager.createTypingIndicatorRef()
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        usersTypingQuery.observeEventType(.Value) { (data: FIRDataSnapshot!) in
            _log_Title("User Typing", location: "ChatVC.observeTyping()", shouldLog: false)
            _log_Element("Number Users Typing: \(data.childrenCount)", shouldLog: false)
            _log_FullLineStars(false)
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
            if self.showTypingIndicator && self.isLastCellVisible {
                //print("Je scroll tout bottom car last cell visible and showTypingIndicator")
                self.scrollToBottomAnimated(true)
            }
        }
    }
    
    private func setMasterChatiOSHashUUID() {
        let chatMasterRef = FirebaseManager.firebaseManager.createMasterChatRef()
        let UsersiOSMasterChatRef = chatMasterRef.child("users")
        let aMasteriOSMasterChatRef = UsersiOSMasterChatRef.childByAutoId()
        let IDpapay0iOSMasterChatRef = aMasteriOSMasterChatRef.child("id")
        let usernamePapay0iOSMasterChatRef = aMasteriOSMasterChatRef.child("username")
        let typeRef = aMasteriOSMasterChatRef.child("type")
        IDpapay0iOSMasterChatRef.setValue(uuidHash)
        usernamePapay0iOSMasterChatRef.setValue("papay0")
        typeRef.setValue("iOS")
        print("Je set tout tout tout")
    }
    
    private func downloadMasterChatiOSHashUUID() {
        let chatMasterRef = FirebaseManager.firebaseManager.createMasterChatRef()
        chatMasterRef.child("users").observeSingleEventOfType(.Value, withBlock: { (snapshots) in
            let users = snapshots.children
            for user in users {
                guard let usernameMaster = user.value!["username"] as? String else {return}
                guard let idMaster = user.value!["id"] as? String else {return}
                let masterChat = MasterChat(username: usernameMaster, id: idMaster, type: "iOS")
                self.listMastersChat.append(masterChat)
                if !self.isAdminChat && self.isMasterOfChatiOS(masterChat, currentUsername: self.senderDisplayName, currentHashUUID: self.uuidHash) {
                    self.isAdminChat = true
                    print("I am the Master of the iOS Chat App")
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func isMasterOfChatiOS(masterChat: MasterChat, currentUsername: String, currentHashUUID: String) -> Bool {
        return masterChat.username == currentUsername && masterChat.id == currentHashUUID
    }
    
    func isAMasterOfChatApp(listMasters: [MasterChat], senderIdMessage: String, senderDisplayNameMessage: String) -> Bool {
        for master in listMasters {
            if master.username == senderDisplayNameMessage && master.id == senderIdMessage {
                return true
            }
        }
        return false
    }
    
    func initActivityIndicatorMessages() {
        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = "Loading messages..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.tapToCancel)))
    }
    
    func initActivityIndicatorPictures() {
        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = "Loading pictures..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.tapToCancel)))
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
    }
    
    func initObservers() {
        observeMessages()
        observeTyping()
        observeActiveUsers()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        initChat()
        initActivityIndicatorMessages()
        collectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 24, 24))
        /*[JSQMessage, scroll to bottom]*/
        self.scrollingDelegate = self
        
        title = "Chat"
        setupBubbles()
        
        if shouldDisplayAvatar {
            // collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
            collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        } else {
            collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
            collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        }
        
        messageRef = FirebaseManager.firebaseManager.createMessageRef()
        
        automaticallyAdjustsScrollViewInsets = true
        
        collectionView!.addInfiniteScrollingWithActionHandler( { () -> Void in
            self.loadMoreMessages()
            }, direction: UInt(SVInfiniteScrollingDirectionTop) )
        
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Normal)
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Highlighted)
        self.inputToolbar?.contentView?.leftBarButtonItem?.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.inputToolbar?.contentView?.leftBarButtonItemWidth = 30
        
        // test pour voir si ça résout le bug d'appeler plusieurs fois observeMessages() quand j'envoie une image
        initObservers()
        
        uuidHash = (UIDevice.currentDevice().identifierForVendor!.UUIDString).md5()
        // setMasterChatiOSHashUUID()
        downloadMasterChatiOSHashUUID()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: self, action: #selector(emojiTitleRightTapped))
    }
    
    
    func initChat(){}
    
    func emojiTitleRightTapped() {
        let width = self.view.frame.width
        let x_startintPoint = width - (width * 0.084)
        let y_startintPoint = CGFloat(55)
        let startPoint = CGPoint(x: x_startintPoint, y: y_startintPoint)
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: getHeightPopoverTableView()))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.scrollEnabled = true
        self.popover = Popover(options: self.popoverOptions, showHandler: nil, dismissHandler: nil)
        self.popover.show(tableView, point: startPoint)
    }
    
    func getHeightPopoverTableView() -> CGFloat {
        /*
         size header = 28
         height of 1 cell = 44
         */
        return CGFloat(28) + ((connectedUsers.count < 5) ? CGFloat(connectedUsers.count * 44) : CGFloat(175))
    }
    
    
    private func observeActiveUsers() {
        let activeUsersRef = FirebaseManager.firebaseManager.createActiveUsersRef()
        let singleUserRef = activeUsersRef.child(self.senderId)
        var value = "\(self.senderDisplayName)"
        singleUserRef.onDisconnectRemoveValue()
        activeUsersRef.observeEventType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in
            value = getUsernameChat()
            singleUserRef.setValue(value)
            var count = 0
            self.connectedUsers = []
            for user in snapshot.children {
                self.connectedUsers.append(user.value)
            }
            self.connectedUsers.sortInPlace()
            if snapshot.exists() {
                count = Int(snapshot.childrenCount)
                let titleChat = "Chat (\(count)) "
                var emoTitleChat = ""
                if count == 1 {
                    emoTitleChat = "👶"
                } else if  count == 2 {
                    emoTitleChat = "👦"
                } else if  count == 3 {
                    emoTitleChat = "👧"
                } else if  count == 4 {
                    emoTitleChat = "🤗"
                } else if  count == 5 {
                    emoTitleChat = "🚶"
                } else if  count == 6 {
                    emoTitleChat = "🍻"
                } else if count <= 7 {
                    emoTitleChat = "😎"
                } else if count <= 10 {
                    emoTitleChat = "🤓"
                } else if count <= 15 {
                    emoTitleChat = "😱"
                } else if count <= 20 {
                    emoTitleChat = "😍"
                } else if count <= 25 {
                    emoTitleChat = "🍷"
                } else if count <= 30 {
                    emoTitleChat = "🐤"
                } else if count <= 35 {
                    emoTitleChat = "🐙"
                } else if count <= 40 {
                    emoTitleChat = "🐸"
                } else if count <= 45 {
                    emoTitleChat = "🐔"
                } else if count <= 50 {
                    emoTitleChat = "🐌"
                } else if count <= 60 {
                    emoTitleChat = "🐨"
                } else if count <= 70 {
                    emoTitleChat = "🐢"
                } else if count <= 80 {
                    emoTitleChat = "🐳"
                } else if count <= 90 {
                    emoTitleChat = "🐲"
                } else if count <= 100 {
                    emoTitleChat = "💥"
                } else if count <= 110 {
                    emoTitleChat = "🌨"
                } else if count <= 120 {
                    emoTitleChat = "🌩"
                } else if count <= 130 {
                    emoTitleChat = "⛈"
                } else if count <= 140 {
                    emoTitleChat = "🌧"
                } else if count <= 150 {
                    emoTitleChat = "🌦"
                } else if count <= 160 {
                    emoTitleChat = "🌬"
                } else if count <= 170 {
                    emoTitleChat = "☁️"
                } else if count <= 180 {
                    emoTitleChat = "⛅️"
                } else if count <= 190 {
                    emoTitleChat = "🌤"
                } else if count <= 195 {
                    emoTitleChat = "☀️"
                } else if count <= 200 {
                    emoTitleChat = "🔥"
                } else {
                    emoTitleChat = "👁"
                }
                self.title = titleChat
                self.navigationItem.rightBarButtonItem?.title = emoTitleChat
            }
        })
    }
    
    func dismissKeyboard(){
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func dismissKeyboardFromMenu(ViewController:MenuController) {
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func shouldAddInArray(hashValue: String) -> Bool {
        return !messagesHashValue.contains(hashValue)
    }
    
    
    func messageAlreadyPresent(id: String, senderDisplayName: String, text: String, date: NSDate) -> Bool {
        let msg = "\(id)\(senderDisplayName)\(text)\(date)"
        var msgToCompare = ""
        for message in messages {
            if message.isMediaMessage == false {
                msgToCompare = "\(message.senderId)\(message.senderDisplayName)\(message.text)\(message.date)"
                if msgToCompare == msg {
                    return true
                }
            }
        }
        return false
    }
    
    
    //    private func observeMessages() {
    //        _log_Title("Count Messages", location: "ChatVC.observeMessages", shouldLog: LOG)
    //        var SwiftSpinnerAlreadyHidden = false
    //        var index = 0;
    //        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
    //        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
    //            if !SwiftSpinnerAlreadyHidden {
    //                SwiftSpinnerAlreadyHidden = true
    //                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
    //                self.initActivityIndicatorPictures()
    //            }
    //
    //            guard let idString = snapshot.value!["senderId"] as? String else {return}
    //            guard let textString = snapshot.value!["text"] as? String else {return}
    //            guard let senderDisplayNameString = snapshot.value!["senderDisplayName"] as? String else {return}
    //            guard let dateTimestampInterval = snapshot.value!["dateTimestamp"] as? NSTimeInterval else {return}
    //
    //            var imageURLString = ""
    //            if let imageURL = snapshot.value!["imageURL"] as? String {
    //                imageURLString = imageURL
    //            }
    //
    //            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                self.lastTimestamp = dateTimestampInterval
    //            }
    //
    //            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
    //            let hashValue = "\(idString)\(date)\(senderDisplayNameString)\(dateTimestampInterval)".md5()
    //            let canAdd = self.shouldAddInArray(hashValue)
    //            if canAdd {
    //                if imageURLString != "" {
    //                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
    //                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
    //                        if (error != nil) {
    //                            print("Error downloading image from httpsReferenceImage firebase")
    //                        } else {
    //                            //print("I download image from firebase reference")
    //                            let image = UIImage(data: data!)?.resizedImageClosestTo1000
    //                            let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: image)
    //                            self.addMessage(idString, media: mediaMessageData, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
    //                            index = self.finishReceivingAsyncMessage(index, isInitialLoading: true, isLoadMoreLoading: false)
    //                            _log_Element("Should have \(self.INITIAL_MESSAGE_LIMIT) messages, have: \(index)", shouldLog: self.LOG)
    //                        }
    //                    }
    //                } else {
    //                    self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
    //                    index = self.finishReceivingAsyncMessage(index, isInitialLoading: true, isLoadMoreLoading: false)
    //                }
    //                self.messagesHashValue += [hashValue]
    //            } else {
    //                print("I cannot add the message, PROBLEM!")
    //                print("Timestamp qui cause problème est: \(dateTimestampInterval), data: \(date)")
    //            }
    //        }
    //    }
    
    
    //    private func observeMessages() { // working with cache but not for loop...
    //        _log_Title("Count Messages", location: "ChatVC.observeMessages", shouldLog: LOG)
    //        var SwiftSpinnerAlreadyHidden = false
    //        var index = 0;
    //        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
    //        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
    //            if !SwiftSpinnerAlreadyHidden {
    //                SwiftSpinnerAlreadyHidden = true
    //                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
    //                self.initActivityIndicatorPictures()
    //            }
    //
    //            guard let idString = snapshot.value!["senderId"] as? String else {return}
    //            guard let textString = snapshot.value!["text"] as? String else {return}
    //            guard let senderDisplayNameString = snapshot.value!["senderDisplayName"] as? String else {return}
    //            guard let dateTimestampInterval = snapshot.value!["dateTimestamp"] as? NSTimeInterval else {return}
    //
    //            var imageURLString = ""
    //            if let imageURL = snapshot.value!["imageURL"] as? String {
    //                imageURLString = imageURL
    //            }
    //
    //            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                self.lastTimestamp = dateTimestampInterval
    //            }
    //
    //            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
    //            let hashValue = "\(idString)\(date)\(senderDisplayNameString)\(dateTimestampInterval)".md5()
    //            let canAdd = self.shouldAddInArray(hashValue)
    //            if canAdd {
    //                if imageURLString != "" {
    //                    let url = NSURL(string: imageURLString)!
    //                    let imageMedia = AsyncPhotoMediaItem(withURL: url)
    //                    self.addMessage(idString, media: imageMedia, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
    //                    index = self.finishReceivingAsyncMessage(index, isInitialLoading: true, isLoadMoreLoading: false)
    //                } else {
    //                    self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
    //                    index = self.finishReceivingAsyncMessage(index, isInitialLoading: true, isLoadMoreLoading: false)
    //                }
    //                self.messagesHashValue += [hashValue]
    //            } else {
    //                print("I cannot add the message, PROBLEM!")
    //                print("Timestamp qui cause problème est: \(dateTimestampInterval), data: \(date)")
    //            }
    //        }
    //    }
    
    private func observeMessages() {
        _log_Title("Count Messages", location: "ChatVC.observeMessages", shouldLog: LOG)
        var SwiftSpinnerAlreadyHidden = false
        var index = 0
        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
        messagesQuery.observeEventType(.Value) { (snapshots: FIRDataSnapshot!) in
            let limiteLoadMessages = snapshots.childrenCount
            for message in snapshots.children {
                index += 1
                print("index: \(index), limiteLoadMessages: \(limiteLoadMessages)")
                if !SwiftSpinnerAlreadyHidden {
                    SwiftSpinnerAlreadyHidden = true
                    MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
                }
                
                guard let idString = message.value!["senderId"] as? String else {return}
                guard let textString = message.value!["text"] as? String else {return}
                guard let senderDisplayNameString = message.value!["senderDisplayName"] as? String else {return}
                guard let dateTimestampInterval = message.value!["dateTimestamp"] as? NSTimeInterval else {return}
                print(textString)
                var imageURLString = ""
                if let imageURL = message.value!["imageURL"] as? String {
                    imageURLString = imageURL
                }
                
                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                    self.lastTimestamp = dateTimestampInterval
                }
                
                let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
                let hashValue = "\(idString)\(date)\(senderDisplayNameString)\(dateTimestampInterval)".md5()
                let canAdd = self.shouldAddInArray(hashValue)
                if canAdd {
                    if imageURLString != "" {
                        let url = NSURL(string: imageURLString)!
                        let imageMedia = AsyncPhotoMediaItem(withURL: url)
                        self.addMessage(idString, media: imageMedia, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
                    } else {
                        self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: false)
                    }
                    self.messagesHashValue += [hashValue]
                } else {
                    //print("I cannot add the message, PROBLEM!")
                    //print("Timestamp qui cause problème est: \(dateTimestampInterval), data: \(date)")
                }
                self.finishReceivingMessage()
                if UInt(index) == limiteLoadMessages {
                    self.scrollToBottomAnimated(true)
                }
            }
            
        }
    }
    
    
    func loadMoreMessages(){
        let oldBottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y
        let messagesQuery = messageRef.queryOrderedByChild("dateTimestamp").queryEndingAtValue(lastTimestamp).queryLimitedToLast(LOAD_MORE_MESSAGE_LIMIT)
        var index = 0
        print("loadMoreMessages ==> 1")
        messagesQuery.observeEventType(.Value) { (snapshots: FIRDataSnapshot!) in
            let limiteLoadMore = snapshots.childrenCount
            print("loadMoreMessages ==> 2")
            for message in snapshots.children {
                index += 1
                print("blocage UI ? \(index)")
                guard let id = message.value!["senderId"] as? String else {return}
                guard let text = message.value!["text"] as? String else {return}
                guard let senderDisplayName = message.value!["senderDisplayName"] as? String else {return}
                guard let dateTimestampInterval = message.value!["dateTimestamp"] as? NSTimeInterval else {return}
                var imageURLString = ""
                if let imageURL = message.value!["imageURL"] as? String {
                    imageURLString = imageURL
                }
                
                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                    self.lastTimestamp = dateTimestampInterval
                }
                
                let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
                
                if imageURLString != "" {
                    let url = NSURL(string: imageURLString)!
                    let imageMedia = AsyncPhotoMediaItem(withURL: url)
                    self.addMessage(id, media: imageMedia, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
                }
                else {
                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
                }
                if UInt(index) == limiteLoadMore {
                    self.finishReceivingMessageAnimated(false)
                    self.collectionView!.infiniteScrollingView.stopAnimating()
                }
                self.collectionView!.layoutIfNeeded()
                self.collectionView!.contentOffset = CGPointMake(0, self.collectionView!.contentSize.height - oldBottomOffset)
            }
        }
        self.resetTimer()
    }
    
    
    //    func loadMoreMessages(){ // cache: OK, but without for ... loop
    //        let oldBottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y
    //        let messagesQuery = messageRef.queryOrderedByChild("dateTimestamp").queryEndingAtValue(lastTimestamp).queryLimitedToLast(LOAD_MORE_MESSAGE_LIMIT)
    //        var index = 0
    //        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
    //
    //            guard let id = snapshot.value!["senderId"] as? String else {return}
    //            guard let text = snapshot.value!["text"] as? String else {return}
    //            guard let senderDisplayName = snapshot.value!["senderDisplayName"] as? String else {return}
    //            guard let dateTimestampInterval = snapshot.value!["dateTimestamp"] as? NSTimeInterval else {return}
    //            var imageURLString = ""
    //            if let imageURL = snapshot.value!["imageURL"] as? String {
    //                imageURLString = imageURL
    //            }
    //
    //            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                self.lastTimestamp = dateTimestampInterval
    //            }
    //
    //            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
    //
    //            if index < Int(self.LOAD_MORE_MESSAGE_LIMIT) {
    //                if imageURLString != "" {
    //                    let url = NSURL(string: imageURLString)!
    //                    let imageMedia = AsyncPhotoMediaItem(withURL: url)
    //                    self.addMessage(id, media: imageMedia, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
    //                    index = self.finishReceivingAsyncMessage(index, isInitialLoading: false, isLoadMoreLoading: true)
    //                }
    //                else {
    //                    index += 1
    //                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
    //                }
    //            } else {
    //                print("I stop animating the loading indicator")
    //                self.collectionView!.infiniteScrollingView.stopAnimating()
    //            }
    //            self.finishReceivingMessageAnimated(false)
    //            self.collectionView!.layoutIfNeeded()
    //            self.collectionView!.contentOffset = CGPointMake(0, self.collectionView!.contentSize.height - oldBottomOffset)
    //        }
    //        self.resetTimer()
    //    }
    
    
    
    func finishReceivingAsyncMessage(index: Int, isInitialLoading: Bool, isLoadMoreLoading: Bool, limiteLoadMore: UInt) -> Int {
        self.finishReceivingMessage()
        if UInt(index+1) == self.INITIAL_MESSAGE_LIMIT && isInitialLoading {
            self.scrollToBottomAnimated(true)
            MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
        } else if UInt(index+1) == limiteLoadMore && isLoadMoreLoading {
            //self.collectionView!.infiniteScrollingView.stopAnimating()
        }
        return index+1
    }
    
    func shouldUpdateLastTimestamp(timestamp: NSTimeInterval) -> Bool {
        return (lastTimestamp == nil) || timestamp < lastTimestamp
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: NSDate!) {
        FirebaseManager.firebaseManager.sendMessageFirebase2(text, senderId: senderId, senderDisplayName: senderDisplayName, date: date, isMedia: false, imageURL: "")
        finishSendingMessage()
        isTyping = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
    
    func shouldDisplayDate (index: Int) -> Bool{
        
        let message = messages[index]
        
        if index > 0 {
            if let _ = message.date {
                let previousMessage = messages[index-1]
                if let _ = previousMessage.date {
                    let timeInterval = Int(message.date.timeIntervalSinceDate(previousMessage.date))
                    let shouldDisplay: Bool = timeInterval >= timeIntervalBetweenMessages
                    return shouldDisplay
                }
            }
        }
        return false
    }
    
    
    
    
    
    //    func loadMoreMessages(){
    //        let oldBottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y
    //        let messagesQuery = messageRef.queryOrderedByChild("dateTimestamp").queryEndingAtValue(lastTimestamp).queryLimitedToLast(LOAD_MORE_MESSAGE_LIMIT)
    //        var index = 0
    //        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
    //
    //            guard let id = snapshot.value!["senderId"] as? String else {return}
    //            guard let text = snapshot.value!["text"] as? String else {return}
    //            guard let senderDisplayName = snapshot.value!["senderDisplayName"] as? String else {return}
    //            guard let dateTimestampInterval = snapshot.value!["dateTimestamp"] as? NSTimeInterval else {return}
    //            var imageURLString = ""
    //            if let imageURL = snapshot.value!["imageURL"] as? String {
    //                imageURLString = imageURL
    //            }
    //
    //            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                self.lastTimestamp = dateTimestampInterval
    //            }
    //
    //            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
    //
    //            if index < Int(self.LOAD_MORE_MESSAGE_LIMIT) {
    //                if imageURLString != "" {
    //                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
    //                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
    //                        if (error != nil) {
    //                            print("Error downloading image from httpsReferenceImage firebase")
    //                        } else {
    //                            let image = UIImage(data: data!)?.resizedImageClosestTo1000
    //                            let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: image)
    //                            self.addMessage(id, media: mediaMessageData, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
    //                            index = self.finishReceivingAsyncMessage(index, isInitialLoading: false, isLoadMoreLoading: true)
    //                            print("index: \(index), load_more_message_limit: \(Int(self.LOAD_MORE_MESSAGE_LIMIT))")
    //                        }
    //                    }
    //                }
    //                else {
    //                    index += 1
    //                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date, isLoadMoreLoading: true)
    //                }
    //            } else {
    //                print("I stop animating the loading indicator")
    //                self.collectionView!.infiniteScrollingView.stopAnimating()
    //            }
    //            self.finishReceivingMessageAnimated(false)
    //            self.collectionView!.layoutIfNeeded()
    //            self.collectionView!.contentOffset = CGPointMake(0, self.collectionView!.contentSize.height - oldBottomOffset)
    //        }
    //        self.resetTimer()
    //    }
    
    func resetTimer() {
        timer.invalidate()
        let nextTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(ChatViewController.handleIdleEvent(_:)), userInfo: nil, repeats: false)
        print("TIMERRRR 1")
        timer = nextTimer
    }
    
    func handleIdleEvent(timer: NSTimer) {
        print("TIMERRRR 2")
        self.collectionView!.infiniteScrollingView.stopAnimating()
    }
    
    func customSortJSQMessage(msg1: JSQMessage, msg2 : JSQMessage) -> Bool {
        return (msg1.date.compare(msg2.date) == NSComparisonResult.OrderedAscending)
    }
    
    func addMessageAtFirstPosition(id: String, text: String, senderDisplayName: String, date: NSDate) {
        let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(msg)
        messages.sortInPlace({
            return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
        })
    }
    
    func addMessage(id: String, text: String, senderDisplayName: String, date: NSDate, isLoadMoreLoading: Bool) {
        if messageAlreadyPresent(id, senderDisplayName:senderDisplayName, text: text, date: date) == false {
            let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
            if isLoadMoreLoading {
                messages.insert(msg, atIndex: 0)
            } else {
                messages.append(msg)
            }
            messages.sortInPlace({
                return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
            })
        }
    }
    
    func addMessage(id: String, media: JSQPhotoMediaItem, senderDisplayName: String, date: NSDate, isLoadMoreLoading: Bool) {
        if messageAlreadyPresent(id, senderDisplayName: senderDisplayName, media: media, date: date) == false {
            let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, media: media)
            if isLoadMoreLoading {
                messages.insert(msg, atIndex: 0)
            } else {
                messages.append(msg)
            }
            messages.sortInPlace({
                return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
            })
        }
    }
    
    func messageAlreadyPresent(id: String, senderDisplayName: String, media: JSQPhotoMediaItem, date: NSDate) -> Bool {
        let msg = "\(id)\(senderDisplayName)\(date)"
        var msgToCompare = ""
        for message in messages {
            if message.isMediaMessage == true {
                msgToCompare = "\(message.senderId)\(message.senderDisplayName)\(message.date)"
                if msgToCompare == msg {
                    return true
                }
            }
        }
        return false
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("didTapLoadEarlierMessagesButton")
        headerView.loadButton?.hidden = false
        loadMoreMessages()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat
    {
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        if shouldDisplayDate(indexPath.item) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    
    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.isMediaMessage == false {
            if message.senderId == senderId {
                cell.textView!.textColor = UIColor.whiteColor()
            } else {
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.blueColor(), NSUnderlineColorAttributeName: UIColor.blueColor(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
                cell.textView!.textColor = UIColor.blackColor()
            }
        }
        return cell
    }
    
    /*
     Display an Avatar
     */
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        if shouldDisplayAvatar {
            let currentMessage = messages[indexPath.item]
            //let initial = String(currentMessage.senderDisplayName.characters.first!)
            let senderDisplayNameCurrentMessage = currentMessage.senderDisplayName
            let senderIDCurrentMessage = currentMessage.senderId
            var initial = String(senderDisplayNameCurrentMessage[senderDisplayNameCurrentMessage.startIndex])
            if senderDisplayNameCurrentMessage.characters.count >= 2 {
                initial = senderDisplayNameCurrentMessage[senderDisplayNameCurrentMessage.startIndex...senderDisplayNameCurrentMessage.startIndex.advancedBy(1)]
            }
            let avatarLightGray = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initial, backgroundColor: UIColor.jsq_messageBubbleLightGrayColor(), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            let avatarTransparent = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("", backgroundColor: UIColor.whiteColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            let avatarAdmin = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initial, backgroundColor: UIColor(red: 0.90, green: 0.1, blue: 0.15, alpha: 0.5), textColor: UIColor.blackColor(), font: UIFont.systemFontOfSize(14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            // si c'est le dernier de la liste, j'affiche l'avatar
            if indexPath.item == messages.count-1 {
                if isAMasterOfChatApp(listMastersChat, senderIdMessage: senderIDCurrentMessage, senderDisplayNameMessage: senderDisplayNameCurrentMessage) {
                    return avatarAdmin
                } else {
                    return avatarLightGray
                }
            }
            let nextMessage = messages[indexPath.item+1]
            if currentMessage.senderId == nextMessage.senderId && currentMessage.senderDisplayName == nextMessage.senderDisplayName {
                return avatarTransparent
            } else {
                if isAMasterOfChatApp(listMastersChat, senderIdMessage: senderIDCurrentMessage, senderDisplayNameMessage: senderDisplayNameCurrentMessage) {
                    return avatarAdmin
                } else {
                    return avatarLightGray
                }
            }
        } else {
            return nil
        }
    }
    
    func getInitials(name: String) -> String {
        return name.characters.split { token in
            return token == " "
            }
            .map { String($0) }
            .map { word in
                return word[word.startIndex]
            }
            .reduce("") { accIn, firstCharacter in
                return "\(accIn)\(firstCharacter)"
        }
    }
    
    /*
     Si le message que j'ai envoyé est signé d'un senderDisplayName différent, alors que renvoit true, sinon je renvoie false
     True: senderDisplayName différent du current, donc je dois mettre un espace et afficher le nom
     False: senderDisplayName égale au current, je mets pas d'espace et j'affiche pas le nom
     */
    func lastMessageFromSenderDisplayNameAndOutComming(senderDisplayName: String) -> Bool {
        var i = 0;
        for message in messages {
            /* ce qui veut dire que j'ai envoyé le message */
            if message.senderId == senderId {
                i += 1
                if i == 2 { /* <=> C'est le message juste avant*/
                    if message.senderDisplayName == senderDisplayName {
                        return false
                    }
                } else {
                    return true
                }
            }
        }
        return false
    }
    
    
    /*
     ça c'est pour savoir si on affiche le nom (senderDisplayName) avant le message ou pas
     */
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString!
    {
        let LOG = false
        _log_Title("Should display name sender", location: "ChatVC.attributedTextForMessageBubbleTopLabelAtIndexPath()", shouldLog: LOG)
        let message = messages[indexPath.item];
        /*Ceci est pour savoir si je dois afficher le pseudo si c'est moi qui envoi
         Commenter si je veux que oui */
        if(message.senderId == self.senderId){
            return nil;
        }
        if(indexPath.row - 1 > 0){
            let prevMessage = messages[indexPath.row-1];
            let timeInterval = Int(message.date.timeIntervalSinceDate(prevMessage.date))
            let shouldDisplayNameSender: Bool = timeInterval < timeIntervalBetweenMessages
            _log_Element("message content: \(message.text)", shouldLog: LOG)
            _log_Element("timeInterval: \(timeInterval)", shouldLog: LOG)
            _log_Element("shouldDisplay name sender: \(shouldDisplayNameSender)", shouldLog: LOG)
            if prevMessage.senderDisplayName == message.senderDisplayName && prevMessage.senderId == message.senderId && shouldDisplayNameSender {
                //print("message.senderId \(message.senderId), message.DN: \(message.senderDisplayName)")
                return nil;
            }
        }
        return NSAttributedString(string: message.senderDisplayName);
    }
    
    /*
     ça c'est pour savoir si on affiche un espace avant le message ou pas, pour laisser une place
     */
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        //print("isLastCellVisible: \(self.isLastCellVisible)")
        let LOG = false
        let currentMessage = self.messages[indexPath.item]
        
        /*Ceci est pour savoir si je dois afficher le pseudo si c'est moi qui envoi
         Commenter si je veux que oui
         */
        if(currentMessage.senderId == self.senderId){
            return 0.0
        }
        if(indexPath.item - 1 >= 0){
            let previousMessage = self.messages[indexPath.item - 1]
            let timeInterval = Int(currentMessage.date.timeIntervalSinceDate(previousMessage.date))
            let shouldLetSpaceToDisplaySomething: Bool = timeInterval < 20*60
            _log_Element("message content: \(currentMessage.text)", shouldLog: LOG)
            _log_Element("timeInterval: \(timeInterval)", shouldLog: LOG)
            _log_Element("shouldDisplay name sender: \(shouldLetSpaceToDisplaySomething)", shouldLog: LOG)
            if(previousMessage.senderDisplayName == currentMessage.senderDisplayName && previousMessage.senderId == currentMessage.senderId && shouldLetSpaceToDisplaySomething){
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString!
    {
        let message = messages[indexPath.item]
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        } else if shouldDisplayDate(indexPath.item) {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func wrapperDidPress(imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(imagePicker: ImagePickerController, images: [UIImage]) {
        print("done button did press")
        let pickedImage = images[0].resizedImageClosestTo1000
        let imageData = pickedImage.lowQualityJPEGNSData
        let imageName = "\(self.senderDisplayName)-\(NSDate())"
        let imageChatRef = FirebaseManager().createStorageRefChat(imageName)
        self.finishSendingMessage()
        dismissViewControllerAnimated(true, completion: nil)
        
        let _ = imageChatRef.putData(imageData, metadata: nil) { metadata, error in
            if (error != nil) {
                print("Error with imageData uploadTask [send image in Chat]")
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                let imageURL = downloadURL()!.absoluteString
                print("imageURL = \(imageURL)")
                FirebaseManager.firebaseManager.sendMessageFirebase2("", senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: NSDate(), isMedia: true, imageURL: imageURL)
            }
        }
    }
    
    func cancelButtonDidPress(imagePicker: ImagePickerController) {
        print("cancel button pressed")
    }
    
    //    func createPhotoArray(image: UIImage) -> ([Photo], Int) {
    //        var arrayPhoto = [Photo]()
    //        var index = 0
    //        var tag = -1
    //        for message in messages {
    //
    //            if message.isMediaMessage {
    //                if let imageItem = message.media as? JSQPhotoMediaItem {
    //                    arrayPhoto.append(Photo(photo: imageItem.image))
    //                    if imageItem.image == image {
    //                        tag = index
    //                    }
    //                    index += 1
    //                }
    //            }
    //        }
    //        return (arrayPhoto, tag)
    //    }
    
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
    //        let message = self.messages[indexPath.row]
    //        if let imageItem = message.media as? JSQPhotoMediaItem {
    //            let image = imageItem.image
    //            let photo = Photo(photo: image!)
    //            let photos = createPhotoArray(image!)
    //            let tagIndexPhotoInArray = photos.1
    //            if tagIndexPhotoInArray != -1 {
    //                print("Tag calc = \(tagIndexPhotoInArray)")
    //                let viewer = NYTPhotosViewController(photos: photos.0, initialPhoto: photos.0[tagIndexPhotoInArray])
    //                presentViewController(viewer, animated: true, completion: nil)
    //            } else {
    //                let viewer = NYTPhotosViewController(photos: [photo])
    //                presentViewController(viewer, animated: true, completion: nil)
    //            }
    //        } else {
    //            print("Problem with the image JSQMediaItem when I click on an image on chat")
    //        }
    //    }
    
    func createPhotoArray(image: UIImage) -> ([Photo], Int) {
        var arrayPhoto = [Photo]()
        var index = 0
        var tag = -1
        for message in messages {
            
            if message.isMediaMessage {
                if let imageItem = message.media as? AsyncPhotoMediaItem {
                    guard let imageAsync = imageItem.asyncImageView.image else {continue}
                    arrayPhoto.append(Photo(photo: imageAsync))
                    if imageAsync == image {
                        tag = index
                    }
                    index += 1
                }
            }
        }
        return (arrayPhoto, tag)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = self.messages[indexPath.row]
        if let imageItem = message.media as? AsyncPhotoMediaItem {
            guard let image = imageItem.asyncImageView.image else {return}
            //            for message in messages {
            //                if message.isMediaMessage {
            //                    guard let imageMedia = message.media as? AsyncPhotoMediaItem else {return}
            //                    guard let _ = imageMedia.asyncImageView.image else {return}
            //                }
            //            }
            let photo = Photo(photo: image)
            let photos = createPhotoArray(image)
            let tagIndexPhotoInArray = photos.1
            if tagIndexPhotoInArray != -1 {
                print("Tag calc = \(tagIndexPhotoInArray)")
                let viewer = NYTPhotosViewController(photos: photos.0, initialPhoto: photos.0[tagIndexPhotoInArray])
                presentViewController(viewer, animated: true, completion: nil)
            } else {
                let viewer = NYTPhotosViewController(photos: [photo])
                presentViewController(viewer, animated: true, completion: nil)
            }
        } else {
            print("Problem with the image JSQMediaItem when I click on an image on chat")
        }
    }
    
    /*[JSQMessage, scroll to bottom]*/
    /*
     Delegate JSQMessage
     */
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func shouldScrollToNewlyReceivedMessageAtIndexPath(indexPath: NSIndexPath!) -> Bool {
        //print("should scroll to botom: \(self.isLastCellVisible)")
        return self.isLastCellVisible
    }
    
    func shouldScrollToLastMessageAtStartup() -> Bool {
        return true
    }
    
}

extension ChatViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.popover.dismiss()
    }
}

extension ChatViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.connectedUsers.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        cell.textLabel?.text = self.connectedUsers[indexPath.row]
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Users"
    }
    
    //    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //        let header = UIView()
    //        header.backgroundColor = UIColor.whiteColor()
    //        header.tex
    //        return vw
    //    }
    
}

class AsyncPhotoMediaItem2: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: NSURL) {
        super.init()
        print("url: \(url)")
        asyncImageView = UIImageView()
        print("asyncImageView: \(asyncImageView)")
        asyncImageView.kf_setImageWithURL(url)
        let placeholderImage = UIImage(named: "Amicaloading")
        asyncImageView.kf_setImageWithURL(url,
                                          placeholderImage: placeholderImage,
                                          optionsInfo: nil,
                                          progressBlock: { (receivedSize, totalSize) -> () in
                                            //print("Download Progress: \(receivedSize)/\(totalSize)")
            },
                                          completionHandler: { (image, error, cacheType, imageURL) -> () in
                                            print("Downloaded and set!")
            }
        )
        
        
    }
    
    override func mediaView() -> UIView! {
        let view = UIView()
        view.addSubview(asyncImageView)
        asyncImageView.frame.origin.x = self.appliesMediaViewMaskAsOutgoing ? -6 : 6
        return view
    }
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: NSURL) {
        super.init()
        
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRectMake(0, 0, 170, 130)
        asyncImageView.contentMode = .ScaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 20
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGrayColor()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.viewWithActivityIndicator()
        activityIndicator.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator)
        
        KingfisherManager.sharedManager.cache.retrieveImageForKey(url.absoluteString, options: nil) { (image, cacheType) -> () in
            
            if let image = image {
                self.asyncImageView.image = image
                activityIndicator.removeFromSuperview()
            } else {
                KingfisherManager.sharedManager.downloader.downloadImageWithURL(url, progressBlock: nil) { (image, error, imageURL, originalData) -> () in
                    
                    if let image = image {
                        self.asyncImageView.image = image
                        activityIndicator.removeFromSuperview()
                        
                        KingfisherManager.sharedManager.cache.storeImage(image, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
                    }
                }
            }
        }
    }
    
    override func mediaView() -> UIView! {
        return asyncImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}