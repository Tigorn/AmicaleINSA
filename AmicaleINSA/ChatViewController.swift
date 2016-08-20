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



class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MenuControllerDelegate, ImagePickerDelegate,JSQMessagesViewControllerScrollingDelegate {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var myActivityIndicator: UIActivityIndicatorView!
    var myActivityIndicatorHUD = MBProgressHUD()
    
    var messages = [JSQMessage]()
    var messagesHashValue = [String]()
    
    var delegate : ChatViewController?
    
    static let chatViewController : ChatViewController = {
        return ChatViewController()
    }()
    
    
    
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
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
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
            print("number users typing: \(data.childrenCount)")
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
            if self.showTypingIndicator && self.isLastCellVisible {
                self.scrollToBottomAnimated(true)
            }
        }
    }
    
    func initActivityIndicator() {
        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = "Loading..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.tapToCancel)))
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("In viewDidLoad ChatVC")
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        initChat()
        initActivityIndicator()
        collectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 24, 24))
        /*[JSQMessage, scroll to bottom]*/
        self.scrollingDelegate = self
        
        title = "Chat"
        setupBubbles()
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        messageRef = FirebaseManager.firebaseManager.createMessageRef()
        
        automaticallyAdjustsScrollViewInsets = true
        
        collectionView!.addInfiniteScrollingWithActionHandler( { () -> Void in
            self.loadMoreMessages()
            }, direction: UInt(SVInfiniteScrollingDirectionTop) )
        
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Normal)
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Highlighted)
        self.inputToolbar?.contentView?.leftBarButtonItem?.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.inputToolbar?.contentView?.leftBarButtonItemWidth = 30
    }
    
    
    func initChat(){}
    
    
    private func observeActiveUsers() {
        let activeUsersRef = FirebaseManager.firebaseManager.createActiveUsersRef()
        let singleUserRef = activeUsersRef.child(self.senderId)
        var value = "\(self.senderDisplayName)"
        singleUserRef.onDisconnectRemoveValue()
        activeUsersRef.observeEventType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in
            value = getUsernameChat()
            print("in observeActiveUsers, setValue, value: \(value)")
            singleUserRef.setValue(value)
            var count = 0
            if snapshot.exists() {
                count = Int(snapshot.childrenCount)
                var titleChat = "Chat (\(count)) "
                if count == 1 {
                    titleChat += "👶"
                } else if  count == 2 {
                    titleChat += "👦"
                } else if  count == 3 {
                    titleChat += "👧"
                } else if  count == 4 {
                    titleChat += "🤗"
                } else if  count == 5 {
                    titleChat += "🚶"
                } else if  count == 6 {
                    titleChat += "🍻"
                } else if count <= 7 {
                    titleChat += "😎"
                } else if count <= 10 {
                    titleChat += "🤓"
                } else if count <= 15 {
                    titleChat += "😱"
                } else if count <= 20 {
                    titleChat += "😍"
                } else if count <= 25 {
                    titleChat += "🍷"
                } else if count <= 30 {
                    titleChat += "🐤"
                } else if count <= 35 {
                    titleChat += "🐙"
                } else if count <= 40 {
                    titleChat += "🐸"
                } else if count <= 45 {
                    titleChat += "🐔"
                } else if count <= 50 {
                    titleChat += "🐌"
                } else if count <= 60 {
                    titleChat += "🐨"
                } else if count <= 70 {
                    titleChat += "🐢"
                } else if count <= 80 {
                    titleChat += "🐳"
                } else if count <= 90 {
                    titleChat += "🐲"
                } else if count <= 100 {
                    titleChat += "💥"
                } else if count <= 110 {
                    titleChat += "🌨"
                } else if count <= 120 {
                    titleChat += "🌩"
                } else if count <= 130 {
                    titleChat += "⛈"
                } else if count <= 140 {
                    titleChat += "🌧"
                } else if count <= 150 {
                    titleChat += "🌦"
                } else if count <= 160 {
                    titleChat += "🌬"
                } else if count <= 170 {
                    titleChat += "☁️"
                } else if count <= 180 {
                    titleChat += "⛅️"
                } else if count <= 190 {
                    titleChat += "🌤"
                } else if count <= 195 {
                    titleChat += "☀️"
                } else if count <= 200 {
                    titleChat += "🔥"
                } else {
                    titleChat += "👁"
                }
                print("count users: \(count)")
                self.title = titleChat
            }
        })
    }
    
    
    
    func testSelector(){
        print("testSelector")
    }
    
    func dismissKeyboard(){
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func dismissKeyboardFromMenu(ViewController:MenuController) {
        print("dismiss keyboard chat")
        inputToolbar?.contentView?.textView?.resignFirstResponder()
    }
    
    
    func shouldAddInArray(hashValue: String) -> Bool {
        return !messagesHashValue.contains(hashValue)
    }
    
    
    func addMessage(id: String, text: String, senderDisplayName: String, date: NSDate) {
        if messageAlreadyPresent(id, senderDisplayName:senderDisplayName, text: text, date: date) == false {
            let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
            messages.append(msg)
            messages.sortInPlace({
                return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
            })
        }
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
    
    func addMessage(id: String, media: JSQPhotoMediaItem, senderDisplayName: String, date: NSDate) {
        if messageAlreadyPresent(id, senderDisplayName: senderDisplayName, media: media, date: date) == false {
            let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, media: media)
            messages.append(msg)
            messages.sortInPlace({
                return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
            })
        }
    }
    
    private func observeMessages() {
        var SwiftSpinnerAlreadyHidden = false
        var index = 0;
        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            if !SwiftSpinnerAlreadyHidden {
                SwiftSpinnerAlreadyHidden = true
                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
            }
            var idString = "errorId"
            var textString = "errorMessage"
            var senderDisplayNameString = "error senderDisplayName"
            var isMediaBool = false
            if let id = snapshot.value!["senderId"] as? String {
                idString = id
            }
            
            if let text = snapshot.value!["text"] as? String {
                textString = text
            }
            
            if let senderDisplayName = snapshot.value!["senderDisplayName"] as? String {
                senderDisplayNameString = senderDisplayName
            }
            if let isMedia = snapshot.value!["isMedia"] as? Bool {
                isMediaBool = isMedia
            }
            let dateTimestampInterval = snapshot.value!["dateTimestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
            let hashValue = "\(idString)\(date)\(senderDisplayNameString)".md5()
            let canAdd = self.shouldAddInArray(hashValue)
            if canAdd {
                if isMediaBool {
                    if let imageURL = snapshot.value!["imageURL"] as? String {
                        let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURL)
                        httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
                            if (error != nil) {
                                print("Error downloading image from httpsReferenceImage firebase")
                                // Uh-oh, an error occurred!
                            } else {
                                print("I download image from firebase reference")
                                let image = UIImage(data: data!)
                                let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: image)
                                self.addMessage(idString, media: mediaMessageData, senderDisplayName: senderDisplayNameString, date: date)
                                index = self.finishReceivingAsyncMessage(index)
                            }
                        }
                    } else {
                        index = self.finishReceivingAsyncMessage(index)
                        print("Image without imageURL!")
                    }
                    /* else {
                        print("Download image with base64 string")
                        let base64EncodedString = snapshot.value!["image"] as! String
                        let imageData = NSData(base64EncodedString: base64EncodedString,
                                           options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                        let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                        self.addMessage(idString, media: mediaMessageData, senderDisplayName: senderDisplayNameString, date: date)
                        index = self.finishReceivingAsyncMessage(index)
                    } */
                } else {
                    self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date)
                    index = self.finishReceivingAsyncMessage(index)
                }
                print("Je dois en avoir 60, je pense que je vais voir le nombre: 58, et en réalité j'en ai \(index).")
                self.messagesHashValue += [hashValue]
            }
        }
    }
    
    func finishReceivingAsyncMessage(index: Int) -> Int {
        self.finishReceivingMessage()
        if UInt(index+1) == self.INITIAL_MESSAGE_LIMIT {
            self.scrollToBottomAnimated(true)
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
        print("viewDidAppear")
        observeMessages()
        observeTyping()
        observeActiveUsers()
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
                    let shouldDisplay: Bool = timeInterval >= 3600
                    return shouldDisplay
                }
            }
        }
        return false
    }
    
    
    func loadMoreMessages(){
        let oldBottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y
        let messagesQuery = messageRef.queryOrderedByChild("dateTimestamp").queryEndingAtValue(lastTimestamp).queryLimitedToLast(LOAD_MORE_MESSAGE_LIMIT)
        var index = 0
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            let id = snapshot.value!["senderId"] as! String
            let text = snapshot.value!["text"] as! String
            let senderDisplayName = snapshot.value!["senderDisplayName"] as! String
            let dateTimestampInterval = snapshot.value!["dateTimestamp"] as! NSTimeInterval
            let isMedia = snapshot.value!["isMedia"] as! Bool
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
            index += 1
            if index < Int(self.LOAD_MORE_MESSAGE_LIMIT) {
                if isMedia {
                    if let imageURL = snapshot.value!["imageURL"] as? String {
                        let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURL)
                        httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
                            if (error != nil) {
                                print("Error downloading image from httpsReferenceImage firebase")
                            } else {
                                print("I download image from firebase reference")
                                let image = UIImage(data: data!)
                                let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: image)
                                self.addMessage(id, media: mediaMessageData, senderDisplayName: senderDisplayName, date: date)
                                index = self.finishReceivingAsyncMessage(index)
                            }
                        }
                    } else {
                        index = self.finishReceivingAsyncMessage(index)
                        print("Image without imageURL!")
                    }
                    /*let base64EncodedString = snapshot.value!["image"] as! String
                    let imageData = NSData(base64EncodedString: base64EncodedString,
                                           options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                    self.addMessage(id, media: mediaMessageData, senderDisplayName: senderDisplayName, date: date)*/
                } else {
                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date)
                }
            } else {
                self.collectionView!.infiniteScrollingView.stopAnimating()
            }
            self.finishReceivingMessageAnimated(false)
            self.collectionView!.layoutIfNeeded()
            self.collectionView!.contentOffset = CGPointMake(0, self.collectionView!.contentSize.height - oldBottomOffset)
        }
        self.resetTimer()
    }
    
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
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    /*
     Si le message que j'ai envoyé est signé d'un senderDisplayName différent, alors que renvoit true, sinon je renvoie false
     True: senderDisplayName différent du current, donc je dois mettre un espace et afficher le nom
     False: senderDisplayName égale au current, je mets pas d'espace et j'affiche pas le nom
     */
    func lastMessageFromSendeDisplayNameAndOutComming(senderDisplayName: String) -> Bool {
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
        let message = messages[indexPath.item];
        /*Ceci est pour savoir si je dois afficher le pseudo si c'est moi qui envoi
         Commenter si je veux que oui */
        if(message.senderId == self.senderId){
            return nil;
        }
        if(indexPath.row - 1 > 0){
            let prevMessage = messages[indexPath.row-1];
            if(prevMessage.senderDisplayName == message.senderDisplayName){
                return nil;
            }
        }
        return NSAttributedString(string: message.senderDisplayName);
    }
    
    /*
     ça c'est pour savoir si on affiche un espace avant le message ou pas, pour laisser une place
     */
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        let currentMessage = self.messages[indexPath.item]
        
        /*Ceci est pour savoir si je dois afficher le pseudo si c'est moi qui envoi
         Commenter si je veux que oui
         */
        if(currentMessage.senderId == self.senderId){
            return 0.0
        }
        if(indexPath.item - 1 >= 0){
            let previousMessage = self.messages[indexPath.item - 1]
            if(previousMessage.senderDisplayName == currentMessage.senderDisplayName){
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
    
    
    func sendToFirebase(text: String, senderId: String, senderDisplayName: String, date: NSDate, image: NSString, isMedia: Bool) {
        let dateTimestamp = date.timeIntervalSince1970
        if (shouldUpdateLastTimestamp(dateTimestamp)) {
            lastTimestamp = dateTimestamp
        }
        let dateString = String(date)
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
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
        finishSendingMessage()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("in imagePickerController didFinishPickingMediaWithInfo")
        let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        let imageData = pickedImage?.mediumQualityJPEGNSData
        let imageChatRef = FirebaseManager().createStorageRefChat((pickedImage?.accessibilityIdentifier!)!)
        // let base64String: NSString!
        // base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let imageData = imageData {
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
        } else {
            print("Error with imageData didFinishPickingMediaWithInfo [send image in Chat]")
        }
        finishSendingMessage()
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
        let pickedImage = images[0]
        let imageData = pickedImage.lowQualityJPEGNSData
        let imageName = "\(self.senderDisplayName)-\(NSDate())"
        let imageChatRef = FirebaseManager().createStorageRefChat(imageName)
        // let base64String: NSString!
        // base64String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
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

func createPhotoArray(image: UIImage) -> ([Photo], Int) {
    var arrayPhoto = [Photo]()
    var index = 0
    var tag = -1
    for message in messages {
        
        if message.isMediaMessage {
            if let imageItem = message.media as? JSQPhotoMediaItem {
                arrayPhoto.append(Photo(photo: imageItem.image))
                if imageItem.image == image {
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
    if let imageItem = message.media as? JSQPhotoMediaItem {
        let image = imageItem.image
        let photo = Photo(photo: image!)
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
    return self.isLastCellVisible
}

func shouldScrollToLastMessageAtStartup() -> Bool {
    return true
}

}