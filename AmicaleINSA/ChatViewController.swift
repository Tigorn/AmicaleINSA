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
    let LOAD_MORE_MESSAGE_LIMIT  = UInt(60)
    let INITIAL_MESSAGE_LIMIT = UInt(60)
    
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
        //print("In viewDidLoad ChatVC")
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
        self.scrollingDelegate = self
        
        title = "Chat"
        setupBubbles()
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        messageRef = FirebaseManager.firebaseManager.createMessageRef()
        // #Test: before: automaticallyScrollsToMostRecentMessage = false, and no scrollToBottomAnimated
        //automaticallyScrollsToMostRecentMessage = true
        //self.scrollToBottomAnimated(true)
        
        
        
        /* [JSQMESSAGE] Ceci est le code avant de faire la MAJ JSQMessage*/
        //automaticallyScrollsToMostRecentMessage = false
        
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
        firebaseRef.authAnonymouslyWithCompletionBlock { (error, authData) in
            if error != nil {
                print("Error connection Firebase Anonymous \(error.description)");
            }
            if authData != nil {
//                print("authData: \(authData)")
//                let activeUsersRef = FirebaseManager.firebaseManager.createActiveUsersRef()
//                let singleUserRef = activeUsersRef.childByAppendingPath(self.senderId)
//                let value = "\(self.senderDisplayName)"
//                singleUserRef.setValue(value)
//                singleUserRef.onDisconnectRemoveValue()
            } else {
                print("in else authData == nil")
            }
        }
    }
    
    private func observeActiveUsers() {
        //print("in observeActiveUsers")
        let activeUsersRef = FirebaseManager.firebaseManager.createActiveUsersRef()
        let singleUserRef = activeUsersRef.childByAppendingPath(self.senderId)
        let value = "\(self.senderDisplayName)"
        singleUserRef.onDisconnectRemoveValue()
        activeUsersRef.observeEventType(.Value, withBlock: { (snapshot: FDataSnapshot!) in
            print("in observeActiveUsers")
            singleUserRef.setValue(value)
            var count = UInt(0)
            if snapshot.exists() {
                count = snapshot.childrenCount
                print("count users: \(count)")
                self.title = "Chat (\(count))"
            }
//            var users = snapshot.children
//            for user in users {
//                print("user: \(user)")
//            }
        })
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
        //print("msg.date = \(date)")
        var msgToCompare = ""
        for message in messages {
            if message.isMediaMessage == true {
                msgToCompare = "\(message.senderId)\(message.senderDisplayName)\(message.date)"
                //print("messgae.date = \(message.date)")
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
        //myActivityIndicator.startAnimating()
        let messagesQuery = messageRef.queryLimitedToLast(INITIAL_MESSAGE_LIMIT)
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            if !SwiftSpinnerAlreadyHidden {
                SwiftSpinnerAlreadyHidden = true
                //MBProgressHUD.hideAllHUDsForView(self.appDelegate.window, animated: true)
                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
            }
            var idString = "errorId"
            var textString = "errorMessage"
            var senderDisplayNameString = "error senderDisplayName"
            var isMediaBool = false
            if let id = snapshot.value["senderId"] as? String {
                idString = id
            }
            
            if let text = snapshot.value["text"] as? String {
                textString = text
            }
            
            if let senderDisplayName = snapshot.value["senderDisplayName"] as? String {
                senderDisplayNameString = senderDisplayName
            }
            if let isMedia = snapshot.value["isMedia"] as? Bool {
                isMediaBool = isMedia
            }
            let dateTimestampInterval = snapshot.value["dateTimestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let date = NSDate(timeIntervalSince1970: dateTimestampInterval)
            let hashValue = "\(idString)\(date)\(senderDisplayNameString)".md5()
            let canAdd = self.shouldAddInArray(hashValue)
            if canAdd {
                if isMediaBool {
                    let base64EncodedString = snapshot.value["image"] as! String
                    let imageData = NSData(base64EncodedString: base64EncodedString,
                                           options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    let mediaMessageData: JSQPhotoMediaItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                    //print("Length")
                    //print(imageData?.length)
                    self.addMessage(idString, media: mediaMessageData, senderDisplayName: senderDisplayNameString, date: date)
                } else {
                    self.addMessage(idString, text: textString, senderDisplayName: senderDisplayNameString, date: date)
                }
                self.messagesHashValue += [hashValue]
            }
            /* [JSQMESSAGE] Ceci est le code avant de faire la MAJ JSQMessage*/
            //self.automaticallyScrollsToMostRecentMessage = false
            
            //print("messages = \(self.messages.count)")
            self.finishReceivingMessage()
            index += 1
            //self.scrollToBottomAnimated(true)
            if UInt(index) == self.INITIAL_MESSAGE_LIMIT {
                self.scrollToBottomAnimated(true)
                //print("[self.scrollToBottomAnimated(true)]")
            }
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
            //self.automaticallyScrollsToMostRecentMessage = false
            //self.scrollToBottomAnimated(false)
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
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.blueColor(), NSUnderlineColorAttributeName: UIColor.blueColor(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
                cell.textView!.textColor = UIColor.blackColor()
            }
        } else {
            //cell.mediaView.layer.borderColor = UIColor.blackColor().CGColor
            //cell.mediaView.layer.borderWidth = CGFloat(10)
            //cell.mediaView?.contentMode = .ScaleAspectFill
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
        /*[]*/
        /*Ceci est pour savoir si je dois afficher le pseudo si c'est moi qui envoi
         Commenter si je veux que oui
         */
        if(message.senderId == self.senderId){
            return nil;
        }
        if(indexPath.row - 1 > 0){
            let prevMessage = messages[indexPath.row-1];
//            if(prevMessage.senderId == message.senderId){
//                return nil;
//            }
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
        //        if(indexPath.item - 1 >= 0){
        //            let previousMessage = self.messages[indexPath.item - 1]
        //            print("preview senderId = \(previousMessage.senderId)")
        //            print("current senderId = \(currentMessage.senderId)")
        //            if(previousMessage.senderId == currentMessage.senderId){
        //                return 0.0
        //            }
        //        }
        if(indexPath.item - 1 >= 0){
            let previousMessage = self.messages[indexPath.item - 1]
            //print("previous senderDisplayName = \(previousMessage.senderDisplayName)")
            //print("current senderDisplayName = \(currentMessage.senderDisplayName)")
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
        //print("numberOfItemsInSection = \(messages.count)")
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
        //print("In viewWillAppear ChatVC")
    }
    
        func shouldScrollToNewlyReceivedMessageAtIndexPath(indexPath: NSIndexPath!) -> Bool {
            //print("in delegate shouldScrollToNewlyReceivedMessageAtIndexPath \(self.isLastCellVisible)")
            return self.isLastCellVisible
        }
    
        func shouldScrollToLastMessageAtStartup() -> Bool {
            //print("shouldScrollToLastMessageAtStartup")
            return true
        }
    
}