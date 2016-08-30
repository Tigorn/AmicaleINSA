//
//  PostTableViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 03/04/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import SWRevealViewController
import Firebase
import MBProgressHUD
import UIScrollView_InfiniteScroll

class PostTableViewController: UITableViewController {
    
    let LOG = false
    
    let INITIAL_POST_LIMIT = UInt(8)
    let LOAD_MORE_POST_LIMIT  = UInt(8)
    
    struct post {
        var title: String
        var description : String
        var date: String
        var author: String
        var imagePresents: Bool
        var image: UIImage?
        var timestamp: NSTimeInterval
    }
    
    
    var posts = [post]()
    var postRef: FIRDatabaseReference!
    var lastTimestamp: NSTimeInterval!
    var lastTimestampReverse: NSTimeInterval!
    
    var timer = NSTimer()
    
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var myActivityIndicator: UIActivityIndicatorView!
    var myActivityIndicatorHUD = MBProgressHUD()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        segueToSettingsIfNeeded()
        
        initApp()
        initUI()
        
        self.refreshControl?.addTarget(self, action: #selector(PostTableViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        postRef = FirebaseManager.firebaseManager.createPostRef()
        
        tableView.estimatedRowHeight = 405
        tableView.rowHeight = UITableViewAutomaticDimension
        
        obversePosts()
        
        lastTimestampReverse = 0
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    
    func segueToSettingsIfNeeded(){
        if !getBeenToSettingsOnce() {
            self.performSegueWithIdentifier(Public.segueBeenToSettingsOnce, sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    
    func refresh(sender:AnyObject)
    {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(PostTableViewController.endRefresh), userInfo: nil, repeats: true)
    }
    
    func endRefresh(){
        self.refreshControl!.endRefreshing()
    }
    
    func initUI() {
        tableView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 24, 24))
        tableView.addInfiniteScrollWithHandler { (scrollView) -> Void in
            self.loadMorePosts()
        }
    }
    
    func obversePosts(){
        initActivityIndicator()
        let postQuery = postRef.queryLimitedToLast(INITIAL_POST_LIMIT)
        postQuery.observeEventType(.Value) { (snapshots: FIRDataSnapshot!) in
            let numberOfPosts = Int(snapshots.childrenCount)
            var currentNumberOfPosts = 0
            _log_Title("Downloading Posts", location: "PostTableVC.observePosts()", shouldLog: self.LOG)
            _log_Element("I download \(numberOfPosts) post(s)", shouldLog: self.LOG)
            for snapshot in snapshots.children {
                var titleString = ""
                var descriptionString = ""
                var authorString = ""
                var dateString = ""
                
                if let title = snapshot.value!.objectForKey("title") as? String {
                    titleString = title
                    _log_Element("Title: \(titleString)", shouldLog: self.LOG)
                }
                
                if let description = snapshot.value!.objectForKey("description") as? String {
                    descriptionString = description
                }
                
                if let author = snapshot.value!.objectForKey("author") as? String {
                    authorString = author
                }
                
                if let date = snapshot.value!.objectForKey("date") as? String {
                    dateString = date
                }
                
                let dateTimestampInterval = snapshot.value!["timestamp"] as! NSTimeInterval
                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                    self.lastTimestamp = dateTimestampInterval
                }
                
                let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as! NSTimeInterval
                self.lastTimestampReverse = dateTimestampInverseInterval
                
                var imageURLString = ""
                if let imageURL = snapshot.value!["imageURL"] as? String {
                    imageURLString = imageURL
                }
                
                if imageURLString != "" {
                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
                        if (error != nil) {
                            print("Error downloading image from httpsReferenceImage firebase")
                            print("Error: \(error)")
                        } else {
                            currentNumberOfPosts += 1
                            if currentNumberOfPosts == numberOfPosts {
                                _log_Element("I have all my post(s)", shouldLog: self.LOG)
                                _log_FullLineStars(self.LOG)
                                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                            }
                            let image = UIImage(data: data!)
                            self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image, timestamp: dateTimestampInterval)
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    currentNumberOfPosts += 1
                    if currentNumberOfPosts == numberOfPosts {
                        print("I have all my posts")
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    }
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    func loadMorePosts() {
        let postQuery = postRef.queryOrderedByChild("timestampInverse").queryStartingAtValue(lastTimestampReverse).queryLimitedToFirst(LOAD_MORE_POST_LIMIT+LOAD_MORE_POST_LIMIT)
        var index = UInt(0)
        postQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            print("I download \(snapshot.childrenCount) more posts")
            var titleString = ""
            var descriptionString = ""
            var authorString = ""
            var dateString = ""
            
            if let title = snapshot.value!.objectForKey("title") as? String {
                titleString = title
            }
            
            if let description = snapshot.value!.objectForKey("description") as? String {
                descriptionString = description
            }
            
            if let author = snapshot.value!.objectForKey("author") as? String {
                authorString = author
            }
            
            if let date = snapshot.value!.objectForKey("date") as? String {
                dateString = date
            }
            
            let dateTimestampInterval = snapshot.value!["timestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as! NSTimeInterval
            self.lastTimestampReverse = dateTimestampInverseInterval
            index += 1
            var imageURLString = ""
            if let imageURL = snapshot.value!["imageURL"] as? String {
                imageURLString = imageURL
            }
            print("index: \(index) LOAD_MORE_POST_LIMIT: \(self.LOAD_MORE_POST_LIMIT)")
            self.printMessage(titleString, description: descriptionString, timestamp: dateTimestampInterval, date: dateString)
            if index <= (self.LOAD_MORE_POST_LIMIT+self.LOAD_MORE_POST_LIMIT) {
                if imageURLString != "" {
                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
                        if (error != nil) {
                            print("Error downloading image from httpsReferenceImage firebase")
                            print("Error: \(error)")
                        } else {
                            let image = UIImage(data: data!)
                            self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image, timestamp: dateTimestampInterval)
                            //self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image, timestamp: dateTimestampInterval)
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
                    print("image no present")
                }
                
                print("title = \(titleString), description = \(descriptionString)")
                self.tableView.reloadData()
            } else {
                print("self.tableView.finishInfiniteScroll()")
                self.tableView.finishInfiniteScroll()
                self.tableView.reloadData()
            }
            
        }
        self.resetTimer()
    }
    
    func printMessage(title:String, description: String, timestamp: NSTimeInterval, date: String) {
        print("")
        print("----------------------------------------------------------------------")
        print("---                        PRINT MESSAGE                           ---")
        print("")
        print("Title: \(title)")
        print("Description: \(description)")
        print("Date: \(date)")
        print("Timestamp: \(timestamp)")
        print("----------------------------------------------------------------------")
        print("")
    }
    
    func addPostAppend(title: String, description: String, date: String, author: String, imagePresents: Bool, image: UIImage?, timestamp: NSTimeInterval) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.append(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, image: image, timestamp: timestamp))
        } else {
            print("/!\\ le post est déjà présent !!")
        }
    }
    
    func addPostBeginning(title: String, description: String, date: String, author: String, imagePresents: Bool, image: UIImage?, timestamp: NSTimeInterval) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.insert(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, image: image, timestamp: timestamp), atIndex: 0)
            self.posts.sortInPlace({
                return ($0.timestamp.distanceTo($1.timestamp) < 0)
            })
        } else {
            print("ObservePost: post already present!!")
        }
    }
    
    func postAlreadyPresent(timestampPost: NSTimeInterval, titleDescription: String) -> Bool {
        var alreadyPresent = false
        for post in posts {
            if post.timestamp == timestampPost || "\(post.title)\(post.description)" == titleDescription {
                alreadyPresent = true
                print("FOUND IT --> ALREADY PRESENT, timestamp = \(post.timestamp), title = \(post.title)")
            }
        }
        return alreadyPresent
    }
    
    func resetTimer() {
        timer.invalidate()
        let nextTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(PostTableViewController.handleIdleEvent(_:)), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    func handleIdleEvent(timer: NSTimer) {
        self.tableView.finishInfiniteScroll()
    }
    
    func shouldUpdateLastTimestamp(timestamp: NSTimeInterval) -> Bool {
        return (lastTimestamp == nil) || timestamp < lastTimestamp
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.reloadData()
        registerForNotificationsAndEnterApp(self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.grayColor()
        header.textLabel?.font = UIFont.boldSystemFontOfSize(13)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.Center
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return posts[section].date
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let imagePresents = posts[section].imagePresents
        
        if imagePresents {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell_image", forIndexPath: indexPath) as! PostWithImageTableViewCell
            
            let colorForBorder = UIColor.blackColor()
            cell.postImageView.image = posts[section].image
            cell.postImageView.contentMode = .ScaleAspectFill
            cell.postImageView.tag = section
            cell.textPostLabel.text = posts[section].description
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.titlePostLabel.text = posts[section].title
            
            cell.postImageView.layer.cornerRadius = 6.0;
            cell.postImageView.layer.borderWidth = 0.5
            cell.postImageView.clipsToBounds = true
            cell.postImageView.layer.borderColor = colorForBorder.CGColor
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(PostTableViewController.imageTapped(_:)))
            cell.postImageView.userInteractionEnabled = true
            cell.postImageView.addGestureRecognizer(tapGestureRecognizer)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell_no_image", forIndexPath: indexPath) as! PostWithoutImageTableViewCell
            //cell.textPostLabel.delegate = self
            cell.titlePostLabel.text = posts[section].title
            cell.textPostLabel.text = posts[section].description
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func initActivityIndicator() {
        myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = "Loading..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PostTableViewController.tapToCancel)))
        myActivityIndicatorHUD.layer.zPosition = 2
        self.tableView.layer.zPosition = 1
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }
    
    func createPhotoArray(image: UIImage) -> ([Photo], Int) {
        var arrayPhoto = [Photo]()
        var index = 0
        var tag = -1
        for post in posts {
            
            if post.imagePresents {
                arrayPhoto.append(Photo(photo: post.image!))
                if post.image! == image {
                    tag = index
                }
                index += 1
            }
        }
        return (arrayPhoto, tag)
    }
    
    func imageTapped(img: AnyObject)
    {
        if let tag = img.view?.tag {
            let image = posts[tag].image
            let photo = Photo(photo: image!)
            let photos = createPhotoArray(image!)
            let tagIndexPhotoInArray = photos.1
            if tagIndexPhotoInArray != -1 {
                let viewer = NYTPhotosViewController(photos: photos.0, initialPhoto: photos.0[tagIndexPhotoInArray])
                presentViewController(viewer, animated: true, completion: nil)
            } else {
                let viewer = NYTPhotosViewController(photos: [photo])
                presentViewController(viewer, animated: true, completion: nil)
            }
        } else {
            print("Problem with the tag when I click on an image")
        }
    }
    
}
