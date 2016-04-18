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


class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MenuControllerDelegate, ImagePickerDelegate {
//, JSQMessagesViewControllerScrollingDelegate {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var myActivityIndicator: UIActivityIndicatorView!
    var myActivityIndicatorHUD = MBProgressHUD()
    
    var messages = [JSQMessage]()
    var messagesHashValue = [String]()
    
    var delegate : ChatViewController?
    
    static let chatViewController : ChatViewController = {
        return ChatViewController()
    }()
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var messageRef: Firebase!
    var firebaseRef = Firebase(url: Secret.BASE_URL)
    //let firebaseManager = FirebaseManager()
    
    var lastTimestamp: NSTimeInterval!
    let LOAD_MORE_MESSAGE_LIMIT  = UInt(10)
    let INITIAL_MESSAGE_LIMIT = UInt(10)
    
    var userIsTypingRef: Firebase! // 1
    private var localTyping = false // 2
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
    
    var usersTypingQuery: FQuery!
    
    private func observeTyping() {
        let typingIndicatorRef = FirebaseManager.firebaseManager.createTypingIndicatorRef()
        userIsTypingRef = typingIndicatorRef.childByAppendingPath(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        usersTypingQuery.observeEventType(.Value) { (data: FDataSnapshot!) in
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
        }
    }
    
//    func initActivityIndicator() {
//        myActivityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0, 50, 50)) as UIActivityIndicatorView
//        myActivityIndicator.center = CGPoint(x: UIScreen.mainScreen().bounds.width/2, y: UIScreen.mainScreen().bounds.height/2)
//        myActivityIndicator.hidesWhenStopped = true
//        myActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
//        view.addSubview(myActivityIndicator)
//    }
    
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
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            //let pan = self.revealViewController().panGestureRecognizer()
            //pan.addTarget(self, action: #selector(ChatViewController.dismissKeyboard))
            //self.view.addGestureRecognizer(pan)
        }
        initChat()
        initActivityIndicator()
        collectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 24, 24))
        /*[JSQMessage, scroll to bottom]*/
        //self.scrollingDelegate = self
        
        title = "Chat"
        setupBubbles()
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        messageRef = FirebaseManager.firebaseManager.createMessageRef()
        // #Test: before: automaticallyScrollsToMostRecentMessage = false, and no scrollToBottomAnimated
        //automaticallyScrollsToMostRecentMessage = true
        //self.scrollToBottomAnimated(true)
        
        
        
        /* [JSQMESSAGE] Ceci est le code avant de faire la MAJ JSQMessage*/
        automaticallyScrollsToMostRecentMessage = false
        automaticallyAdjustsScrollViewInsets = true
        //Configuration.doneButtonTitle = "Send"
        
        collectionView!.addInfiniteScrollingWithActionHandler( { () -> Void in
            self.loadMoreMessages()
            }, direction: UInt(SVInfiniteScrollingDirectionTop) )
        
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Normal)
        self.inputToolbar?.contentView?.leftBarButtonItem?.setImage(UIImage(named: "Camera"), forState: .Highlighted)
        self.inputToolbar?.contentView?.leftBarButtonItem?.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.inputToolbar?.contentView?.leftBarButtonItemWidth = 30
    }
    
    func initChat(){
        firebaseRef.authAnonymouslyWithCompletionBlock { (error, authData) in // 1
            if error != nil { print("Error connection Firebase Anonymous \(error.description)");}
        }
    }
    
    func testSelector(){
        print("testSelector")
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
    
    
    func addMessage(id: String, text: String, senderDisplayName: String, date: NSDate) {
        let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(msg)
        messages.sortInPlace({
            return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
        })
    }
    
    func addMessage(id: String, media: JSQPhotoMediaItem, senderDisplayName: String, date: NSDate) {
        let msg = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, media: media)
        messages.append(msg)
        messages.sortInPlace({
            return ($0.date.compare($1.date) == NSComparisonResult.OrderedAscending)
        })
    }
    
    private func observeMessages() {
        var SwiftSpinnerAlreadyHidden = false
        //myActivityIndicator.startAnimating()
        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            if !SwiftSpinnerAlreadyHidden {
                SwiftSpinnerAlreadyHidden = true
                //MBProgressHUD.hideAllHUDsForView(self.appDelegate.window, animated: true)
                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
            }
            //self.myActivityIndicator.stopAnimating()
            let id = snapshot.value["senderId"] as! String
            let text = snapshot.value["text"] as! String
            let senderDisplayName = snapshot.value["senderDisplayName"] as! String
            let isMedia = snapshot.value["isMedia"] as! Bool
            let dateTimestampInterval = snapshot.value["dateTimestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
            let hashValue = "\(id)\(date)\(senderDisplayName)".md5()
            let canAdd = self.shouldAddInArray(hashValue)
            if canAdd {
                if isMedia {
                    let base64EncodedString = snapshot.value["image"] as! String
                    let imageData = NSData(base64EncodedString: base64EncodedString,
                                           options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                    print("Length")
                    print(imageData?.length)
                    self.addMessage(id, media: mediaMessageData, senderDisplayName: senderDisplayName, date: date)
                } else {
                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date)
                }
                self.messagesHashValue += [hashValue]
            }
            /* [JSQMESSAGE] Ceci est le code avant de faire la MAJ JSQMessage*/
            self.automaticallyScrollsToMostRecentMessage = false
            
            print("messages = \(self.messages.count)")
            self.finishReceivingMessage()
        }
    }
    
    func shouldUpdateLastTimestamp(timestamp: NSTimeInterval) -> Bool {
        return (lastTimestamp == nil) || timestamp < lastTimestamp
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: NSDate!) {
        FirebaseManager.firebaseManager.sendMessage(text, senderId: senderId, senderDisplayName: senderDisplayName, date: date, image: "", isMedia: false)
        finishSendingMessage()
        isTyping = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeMessages()
        observeTyping()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        let currentMessage = self.messages[indexPath.item]
        
        if(currentMessage.senderId == self.senderId){
            return 0.0
        }
        if(indexPath.item - 1 >= 0){
            let previousMessage = self.messages[indexPath.item - 1]
            if(previousMessage.senderId == currentMessage.senderId){
                return 0.0
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
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
        var index = UInt(0)
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            let id = snapshot.value["senderId"] as! String
            let text = snapshot.value["text"] as! String
            let senderDisplayName = snapshot.value["senderDisplayName"] as! String
            let dateTimestampInterval = snapshot.value["dateTimestamp"] as! NSTimeInterval
            let isMedia = snapshot.value["isMedia"] as! Bool
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
            index += 1
            if index < self.LOAD_MORE_MESSAGE_LIMIT {
                if isMedia {
                    let base64EncodedString = snapshot.value["image"] as! String
                    let imageData = NSData(base64EncodedString: base64EncodedString,
                                           options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                    self.addMessage(id, media: mediaMessageData, senderDisplayName: senderDisplayName, date: date)
                } else {
                    self.addMessage(id, text: text, senderDisplayName: senderDisplayName, date: date)
                }
            } else {
                self.collectionView!.infiniteScrollingView.stopAnimating()
            }
            /* [JSQMESSAGE] Ceci est le code avant de faire la MAJ JSQMessage*/
            self.automaticallyScrollsToMostRecentMessage = false
            self.scrollToBottomAnimated(false)
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
        // do whatever you want when idle after certain period of time
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
        //        if message.senderDisplayName == senderDisplayName {
        //            return outgoingBubbleImageView
        //        } else {
        //            return incomingBubbleImageView
        //        }
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
                cell.textView!.textColor = UIColor.blackColor()
            }
        } else {
            //cell.mediaView?.contentMode = .ScaleAspectFill
        }
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString!
    {
        let message = messages[indexPath.item];
        if(message.senderId == self.senderId){
            return nil;
        }
        if(indexPath.row - 1 > 0){
            let prevMessage = messages[indexPath.row-1];
            if(prevMessage.senderId == message.senderId){
                return nil;
            }
        }
        return NSAttributedString(string: message.senderDisplayName);
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
        let itemRef = messageRef.childByAutoId() // 1
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
        finishSendingMessage()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        let imageData = pickedImage?.mediumQualityJPEGNSData
        let base64String: NSString!
        base64String = imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        picker.dismissViewControllerAnimated(true, completion: nil)
        FirebaseManager.firebaseManager.sendMessage("", senderId: senderId, senderDisplayName: senderDisplayName, date: NSDate(), image: base64String, isMedia: true)
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func wrapperDidPress(images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(images: [UIImage]) {
        print("done button did press")
        let pickedImage = images[0]
        let imageData = pickedImage.lowQualityJPEGNSData
        let base64String: NSString!
        base64String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        FirebaseManager().sendMessage("", senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: NSDate(), image: base64String, isMedia: true)
        self.finishSendingMessage()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func cancelButtonDidPress() {
        print("cancel button pressed")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = self.messages[indexPath.row]
        if message.isMediaMessage {
            if let photoItem = message.media as? JSQPhotoMediaItem {
                let photo = Photo(photo: photoItem.image)
                let viewer = NYTPhotosViewController(photos: [photo])
                presentViewController(viewer, animated: true, completion: nil)
            }
        }
    }
    
    /*[JSQMessage, scroll to bottom]*/
    /*
        Delegate JSQMessage
    */
    
//    func shouldScrollToNewlyReceivedMessageAtIndexPath(indexPath: NSIndexPath!) -> Bool {
//        print("in delegate shouldScrollToNewlyReceivedMessageAtIndexPath \(isLastCellVisible)")
//        return self.isLastCellVisible
//    }
//    
//    func shouldScrollToLastMessageAtStartup() -> Bool {
//        print("shouldScrollToLastMessageAtStartup")
//        return true
//    }
    
}