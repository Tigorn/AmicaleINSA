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
    
    fileprivate var popover: Popover!
    fileprivate var connectedUsers = [String]()
    fileprivate var connectedUsersTmp = [String]()
    fileprivate var popoverOptions: [PopoverOption] = [
        .type(.down),
        .blackOverlayColor(UIColor(white: 0.0, alpha: 0.6))
    ]
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var titleButton: UIButton!
    
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
    
    var lastTimestamp: TimeInterval!
    let LOAD_MORE_MESSAGE_LIMIT  = UInt(60)
    let INITIAL_MESSAGE_LIMIT = UInt(60)
    var userIsTypingRef: FIRDatabaseReference!
    fileprivate var localTyping = false
    
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
    
    var timer = Timer()
    
    let imagePicker = UIImagePickerController()
    var usersTypingQuery: FIRDatabaseQuery!
    
    fileprivate func observeTyping() {
        let typingIndicatorRef = FirebaseManager.firebaseManager.createTypingIndicatorRef()
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot!) in
            _log_Title("User Typing", location: "ChatVC.observeTyping()", shouldLog: false)
            _log_Element("Number Users Typing: \(data.childrenCount)", shouldLog: false)
            _log_FullLineStars(false)
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
            if self.showTypingIndicator && self.isLastCellVisible {
                //print("Je scroll tout bottom car last cell visible and showTypingIndicator")
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    fileprivate func setMasterChatiOSHashUUID() {
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
    
    fileprivate func downloadMasterChatiOSHashUUID() {
        let chatMasterRef = FirebaseManager.firebaseManager.createMasterChatRef()
        chatMasterRef.child("users").observeSingleEvent(of: .value, with: { (snapshots) in
        
            for user in snapshots.children {
                let snap = user as! FIRDataSnapshot
                let dict = snap.value as! [String: Any]
                guard let usernameMaster = dict["username"] as? String else {return}
                guard let idMaster = dict["id"] as? String else {return}
                let masterChat = MasterChat(username: usernameMaster, id: idMaster, type: "iOS")
                print("Master chat: ", masterChat)
                self.listMastersChat.append(masterChat)
//                if !self.isAdminChat && self.isMasterOfChatiOS(masterChat, currentUsername: self.senderDisplayName, currentHashUUID: self.uuidHash) {
//                    self.isAdminChat = true
//                    print("I am the Master of the iOS Chat App")
//                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        // print("senderIdScore: ", Public.senderIdScore)
    }
    
    func isMasterOfChatiOS(_ masterChat: MasterChat, currentUsername: String, currentHashUUID: String) -> Bool {
        return (masterChat.username == currentUsername && masterChat.id == currentHashUUID)
    }
    
    func isAMasterOfChatApp(_ listMasters: [MasterChat], senderIdMessage: String, senderDisplayNameMessage: String) -> Bool {
        for master in listMasters {
            if (master.username == senderDisplayNameMessage && master.id == senderIdMessage) {
                return true
            }
        }
        return false
    }
    
    func initActivityIndicatorMessages() {
        let myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        myActivityIndicatorHUD?.mode = MBProgressHUDMode.indeterminate
        myActivityIndicatorHUD?.labelText = "Loading messages..."
        myActivityIndicatorHUD?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.tapToCancel)))
    }
    
    func initActivityIndicatorPictures() {
        let myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        myActivityIndicatorHUD?.mode = MBProgressHUDMode.indeterminate
        myActivityIndicatorHUD?.labelText = "Loading pictures..."
        myActivityIndicatorHUD?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.tapToCancel)))
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDs(for: self.navigationController?.view, animated: true)
    }
    
    func initObservers() {
        observeMessagesInit()
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
        collectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        /*[JSQMessage, scroll to bottom]*/
        self.scrollingDelegate = self
        
        title = "Chat"
        titleButton.setTitle("Chat", for: .normal)
        setupBubbles()
        
        if shouldDisplayAvatar {
            // collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
            collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        } else {
            collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
            collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        }
        
        messageRef = FirebaseManager.firebaseManager.createMessageRef()
        
        automaticallyAdjustsScrollViewInsets = true
        
        collectionView!.addInfiniteScrolling( actionHandler: { () -> Void in
            self.loadMoreMessages()
            }, direction: UInt(SVInfiniteScrollingDirectionTop) )
        
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), for: UIControlState())
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), for: .highlighted)
        self.inputToolbar?.contentView?.leftBarButtonItem?.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        
        self.inputToolbar?.contentView?.leftBarButtonItemWidth = 30
        
        // test pour voir si ça résout le bug d'appeler plusieurs fois observeMessages() quand j'envoie une image
        initObservers()
        
        uuidHash = (UIDevice.current.identifierForVendor!.uuidString).md5()
        // setMasterChatiOSHashUUID()
        downloadMasterChatiOSHashUUID()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(emojiTitleRightTapped))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.titleTappedGestureRecognizer))
        tap.numberOfTapsRequired = 10
        navigationItem.titleView?.addGestureRecognizer(tap)
        
    }
    
    
    func initChat(){
        print("iniChat")
    }
    
    func titleTappedGestureRecognizer() {
        print("button title tapped")
//        let imageRecognizerVC = self.storyboard?.instantiateViewController(withIdentifier: "imageRecognition") as! MetalImageRecognitionViewController
//        self.navigationController?.pushViewController(imageRecognizerVC, animated: true)
        let flappyVC = self.storyboard?.instantiateViewController(withIdentifier: "flappyBird") as!
        GameViewController
        flappyVC.senderId = senderId
        flappyVC.senderDisplayName = senderDisplayName
        
        self.navigationController?.pushViewController(flappyVC, animated: true)
    }
    
    func emojiTitleRightTapped() {
        connectedUsersTmp = connectedUsers
        let width = self.view.frame.width
        let x_startintPoint = width - (width * 0.084)
        let y_startintPoint = CGFloat(55)
        let startPoint = CGPoint(x: x_startintPoint, y: y_startintPoint)
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: getHeightPopoverTableView()))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
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
    
    
    fileprivate func observeActiveUsers() {
        let activeUsersRef = FirebaseManager.firebaseManager.createActiveUsersRef()
        let singleUserRef = activeUsersRef.child(self.senderId)
        var value = "\(self.senderDisplayName)"
        singleUserRef.onDisconnectRemoveValue()
        activeUsersRef.observe(.value, with: { (snapshot: FIRDataSnapshot!) in
            value = getUsernameChat()
            singleUserRef.setValue(value)
            var count = 0
            self.connectedUsers = []
            for user in snapshot.children {
                self.connectedUsers.append((user as AnyObject).value)
            }
            self.connectedUsers.sort()
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
                self.titleButton.setTitle(titleChat, for: .normal)
                self.navigationItem.rightBarButtonItem?.title = emoTitleChat
            }
        })
    }
    
    func dismissKeyboard(){
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func dismissKeyboardFromMenu(_ ViewController:MenuController) {
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func shouldAddInArray(_ hashValue: String) -> Bool {
        return !messagesHashValue.contains(hashValue)
    }
 
    fileprivate func computeSnapshot(_ snapshot: FIRDataSnapshot, isLoadMoreMessages: Bool, isObserveMessages: Bool ) {
        let snapshotValue = snapshot.value as? NSDictionary
        guard let idString = snapshotValue?["senderId"] as? String else {return}
        guard let textString = snapshotValue?["text"] as? String else {return}
        guard let senderDisplayNameString = snapshotValue?["senderDisplayName"] as? String else {return}
        guard let dateTimestampInterval = snapshotValue?["dateTimestamp"] as? TimeInterval else {return}
        var imageURLString = ""
        if let imageURL = snapshotValue?["imageURL"] as? String {
            imageURLString = imageURL
        }
        
        if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
            self.lastTimestamp = dateTimestampInterval
        }
        
        let date = Date(timeIntervalSince1970: dateTimestampInterval)
        let hashValue = "\(idString)\(date)\(senderDisplayNameString)\(dateTimestampInterval)".md5()
        let canAdd = self.shouldAddInArray(hashValue)
        if canAdd {
            if imageURLString != "" {
                let url = URL(string: imageURLString)!
                let imageMedia = AsyncPhotoMediaItem(withURL: url)
                self.addMessage(idString, text: nil, media: imageMedia, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: isLoadMoreMessages)
            } else {
                self.addMessage(idString, text: textString, media: nil, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: isLoadMoreMessages)
                //self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date, isLoadMoreLoading: isLoadMoreMessages)
            }
            self.messagesHashValue += [hashValue]
        }
        if isObserveMessages {
            self.finishReceivingMessage()
        }
    }
    
    fileprivate func observeMessages() {
        let messagesQuery = messageRef.queryLimited(toLast: 1)
        messagesQuery.observe(.childAdded, with: { (snapshot: FIRDataSnapshot!) in
            self.computeSnapshot(snapshot, isLoadMoreMessages: false, isObserveMessages: true)
        })
    }
    
    fileprivate func observeMessagesInit() {
        _log_Title("Count Messages", location: "ChatVC.observeMessages", shouldLog: LOG)
        var SwiftSpinnerAlreadyHidden = false
        var index = 0
        let messagesQuery = messageRef.queryLimited(toLast: INITIAL_MESSAGE_LIMIT)
        messagesQuery.observeSingleEvent(of: .value) { (snapshots: FIRDataSnapshot!) in
            let limiteLoadMessages = snapshots.childrenCount
            for message in snapshots.children {
                index += 1
                if !SwiftSpinnerAlreadyHidden {
                    SwiftSpinnerAlreadyHidden = true
                    MBProgressHUD.hideAllHUDs(for: self.navigationController?.view, animated: true)
                }
                self.computeSnapshot(message as! FIRDataSnapshot, isLoadMoreMessages: false, isObserveMessages: false)
                if UInt(index) == limiteLoadMessages {
                    self.finishReceivingMessage()
                    self.scrollToBottom(animated: true)
                }
            }
            
        }
    }
    
    
    func loadMoreMessages(){
        let oldBottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y
        let messagesQuery = messageRef.queryOrdered(byChild: "dateTimestamp").queryEnding(atValue: lastTimestamp).queryLimited(toLast: LOAD_MORE_MESSAGE_LIMIT)
        var index = 0
        messagesQuery.observe(.value) { (snapshots: FIRDataSnapshot!) in
            let limiteLoadMore = snapshots.childrenCount
            for message in snapshots.children {
                index += 1
                self.computeSnapshot(message as! FIRDataSnapshot, isLoadMoreMessages: true, isObserveMessages: false)
                if UInt(index) == limiteLoadMore {
                    self.finishReceivingMessage(animated: false)
                    self.collectionView!.infiniteScrollingView.stopAnimating()
                }
                self.collectionView!.layoutIfNeeded()
                self.collectionView!.contentOffset = CGPoint(x: 0, y: self.collectionView!.contentSize.height - oldBottomOffset)
            }
        }
        self.resetTimer()
    }
    
    
    
    func finishReceivingAsyncMessage(_ index: Int, isInitialLoading: Bool, isLoadMoreLoading: Bool, limiteLoadMore: UInt) -> Int {
        self.finishReceivingMessage()
        if UInt(index+1) == self.INITIAL_MESSAGE_LIMIT && isInitialLoading {
            self.scrollToBottom(animated: true)
            MBProgressHUD.hideAllHUDs(for: self.navigationController?.view, animated: true)
        } else if UInt(index+1) == limiteLoadMore && isLoadMoreLoading {
            //self.collectionView!.infiniteScrollingView.stopAnimating()
        }
        return index+1
    }
    
    func shouldUpdateLastTimestamp(_ timestamp: TimeInterval) -> Bool {
        return (lastTimestamp == nil) || timestamp < lastTimestamp
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: Date!) {
        FirebaseManager.firebaseManager.sendMessageFirebase(text, senderId: senderId, senderDisplayName: senderDisplayName, date: date, isMedia: false, imageURL: "", sound: true)
        finishSendingMessage()
        isTyping = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
    
    func shouldDisplayDate (_ index: Int) -> Bool{
        
        let message = messages[index]
        
        if index > 0 {
            if let _ = message.date {
                let previousMessage = messages[index-1]
                if let _ = previousMessage.date {
                    let timeInterval = Int(message.date.timeIntervalSince(previousMessage.date))
                    let shouldDisplay: Bool = timeInterval >= timeIntervalBetweenMessages
                    return shouldDisplay
                }
            }
        }
        return false
    }
    
    func resetTimer() {
        timer.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(ChatViewController.handleIdleEvent(_:)), userInfo: nil, repeats: false)
        print("TIMERRRR 1")
        timer = nextTimer
    }
    
    func handleIdleEvent(_ timer: Timer) {
        print("TIMERRRR 2")
        self.collectionView!.infiniteScrollingView.stopAnimating()
    }
    
//    func customSortJSQMessage(msg1: JSQMessage, msg2 : JSQMessage) -> Bool {
//        return (msg1.date.compare(msg2.date) == NSComparisonResult.OrderedAscending)
//    }
    
//    func addMessage(id: String, text: String, senderDisplayName: String, date: NSDate, isLoadMoreLoading: Bool) {
//        if messageAlreadyPresent(id, senderDisplayName:senderDisplayName, text: text, date: date) == false {
//            let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
//            if isLoadMoreLoading {
//                messages.insert(msg, atIndex: 0)
//            } else {
//                messages.append(msg)
//            }
//            messages.sortInPlace({
//                return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
//            })
//        }
//    }
    
    func addMessage(_ id: String, text: String?, media: JSQPhotoMediaItem?, senderDisplayName: String, date: Date, isLoadMoreLoading: Bool) {
        if messageAlreadyPresent(id, senderDisplayName: senderDisplayName, text: text, date: date) == false {
            var msg: JSQMessage?
            if text == nil {
               msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, media: media)
            } else {
                msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
            }
            if isLoadMoreLoading {
                messages.insert(msg!, at: 0)
            } else {
                messages.append(msg!)
            }
            messages.sort(by: {
                return ($0.date.compare($1.date) == ComparisonResult.orderedAscending)
            })
        }
    }
    
    func messageAlreadyPresent(_ id: String, senderDisplayName: String, text: String?, date: Date) -> Bool {
        var msg = "\(id)\(senderDisplayName)\(text)\(date)"
        if text == nil {
            msg = "\(id)\(senderDisplayName)\(date)"
        }
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
    
//    func messageAlreadyPresent(id: String, senderDisplayName: String, date: NSDate) -> Bool {
//        let msg = "\(id)\(senderDisplayName)\(date)"
//        var msgToCompare = ""
//        for message in messages {
//            if message.isMediaMessage == true {
//                msgToCompare = "\(message.senderId)\(message.senderDisplayName)\(message.date)"
//                if msgToCompare == msg {
//                    return true
//                }
//            }
//        }
//        return false
//    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("didTapLoadEarlierMessagesButton")
        headerView.loadButton?.isHidden = false
        loadMoreMessages()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        if shouldDisplayDate(indexPath.item) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
            as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.isMediaMessage == false {
            if message.senderId == senderId {
                cell.textView!.textColor = UIColor.white
            } else {
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.blue, NSUnderlineColorAttributeName: UIColor.blue, NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
                cell.textView!.textColor = UIColor.black
            }
        }
        return cell
    }
    
    /*
     Display an Avatar
     */
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        if shouldDisplayAvatar {
            let currentMessage = messages[indexPath.item]
            //let initial = String(currentMessage.senderDisplayName.characters.first!)
            let senderDisplayNameCurrentMessage = currentMessage.senderDisplayName
            let senderIDCurrentMessage = currentMessage.senderId
            var initial = String((senderDisplayNameCurrentMessage?[(senderDisplayNameCurrentMessage?.startIndex)!])!)
            if (senderDisplayNameCurrentMessage?.characters.count)! >= 2 {
                initial = (senderDisplayNameCurrentMessage?[(senderDisplayNameCurrentMessage?.startIndex)!...(senderDisplayNameCurrentMessage?.index((senderDisplayNameCurrentMessage?.startIndex)!, offsetBy: 1))!])!
            }
            let avatarLightGray = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initial, backgroundColor: UIColor.jsq_messageBubbleLightGray(), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont.systemFont(ofSize: 14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            let avatarTransparent = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: "", backgroundColor: UIColor.white, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            let avatarAdmin = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initial, backgroundColor: UIColor(red: 0.90, green: 0.1, blue: 0.15, alpha: 0.5), textColor: UIColor.black, font: UIFont.systemFont(ofSize: 14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            // si c'est le dernier de la liste, j'affiche l'avatar
            if indexPath.item == messages.count-1 {
                if isAMasterOfChatApp(listMastersChat, senderIdMessage: senderIDCurrentMessage!, senderDisplayNameMessage: senderDisplayNameCurrentMessage!) {
                    return avatarAdmin
                } else {
                    return avatarLightGray
                }
            }
            let nextMessage = messages[indexPath.item+1]
            if currentMessage.senderId == nextMessage.senderId && currentMessage.senderDisplayName == nextMessage.senderDisplayName {
                return avatarTransparent
            } else {
                if isAMasterOfChatApp(listMastersChat, senderIdMessage: senderIDCurrentMessage!, senderDisplayNameMessage: senderDisplayNameCurrentMessage!) {
                    return avatarAdmin
                } else {
                    return avatarLightGray
                }
            }
        } else {
            return nil
        }
    }
    
    func getInitials(_ name: String) -> String {
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
    func lastMessageFromSenderDisplayNameAndOutComming(_ senderDisplayName: String) -> Bool {
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
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
            let timeInterval = Int(message.date.timeIntervalSince(prevMessage.date))
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
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
            let timeInterval = Int(currentMessage.date.timeIntervalSince(previousMessage.date))
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
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        let message = messages[indexPath.item]
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        } else if shouldDisplayDate(indexPath.item) {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    fileprivate func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("done button did press")
        let pickedImage = images[0].resizedImageClosestTo1000
        let imageData = pickedImage.lowQualityJPEGNSData
        let imageName = "\(self.senderDisplayName)-\(Date())"
        let imageChatRef = FirebaseManager().createStorageRefChat(imageName)
        self.finishSendingMessage()
        dismiss(animated: true, completion: nil)
        
        let _ = imageChatRef.put(imageData, metadata: nil) { metadata, error in
            if (error != nil) {
                print("Error with imageData uploadTask [send image in Chat]")
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                let imageURL = downloadURL()!.absoluteString
                print("imageURL = \(imageURL)")
                FirebaseManager.firebaseManager.sendMessageFirebase("", senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: Date(), isMedia: true, imageURL: imageURL, sound: true)
            }
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        print("cancel button pressed")
    }
    
    
    func createPhotoArray(_ image: UIImage) -> ([Photo], Int) {
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
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
                present(viewer, animated: true, completion: nil)
            } else {
                let viewer = NYTPhotosViewController(photos: [photo])
                present(viewer, animated: true, completion: nil)
            }
        } else {
            print("Problem with the image JSQMediaItem when I click on an image on chat")
        }
    }
    
    /*[JSQMessage, scroll to bottom]*/
    /*
     Delegate JSQMessage
     */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func shouldScrollToNewlyReceivedMessage(at indexPath: IndexPath!) -> Bool {
        //print("should scroll to botom: \(self.isLastCellVisible)")
        return self.isLastCellVisible
    }
    
    func shouldScrollToLastMessageAtStartup() -> Bool {
        return true
    }
    
}

extension ChatViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.popover.dismiss()
    }
}

extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.connectedUsersTmp.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = self.connectedUsersTmp[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Users"
    }
    
}
