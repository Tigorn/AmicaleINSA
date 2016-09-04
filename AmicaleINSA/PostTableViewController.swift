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
import FirebaseStorage
import Kingfisher

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
        var timestamp: NSTimeInterval
        var urlImage: String
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
    
//    func obversePosts(){
//        initActivityIndicator()
//        let postQuery = postRef.queryLimitedToLast(INITIAL_POST_LIMIT)
//        postQuery.observeEventType(.Value) { (snapshots: FIRDataSnapshot!) in
//            let numberOfPosts = Int(snapshots.childrenCount)
//            var currentNumberOfPosts = 0
//            _log_Title("Downloading Posts", location: "PostTableVC.observePosts()", shouldLog: self.LOG)
//            _log_Element("I download \(numberOfPosts) post(s)", shouldLog: self.LOG)
//            for snapshot in snapshots.children {
//                
//                guard let titleString = snapshot.value!["title"] as? String else {return}
//                guard let descriptionString = snapshot.value!["description"] as? String else {return}
//                guard let authorString = snapshot.value!["author"] as? String else {return}
//                guard let dateString = snapshot.value!["date"] as? String else {return}
//                guard let dateTimestampInterval = snapshot.value!["timestamp"] as? NSTimeInterval else {return}
//                guard let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as? NSTimeInterval else {return}
//            
//                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
//                    self.lastTimestamp = dateTimestampInterval
//                }
//                
//                self.lastTimestampReverse = dateTimestampInverseInterval
//                
//                var imageURLString = ""
//                if let imageURL = snapshot.value!["imageURL"] as? String {
//                    imageURLString = imageURL
//                    print("imageURL: \(imageURLString)")
//                }
//                
//                if imageURLString != "" {
//                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
//                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
//                        if (error != nil) {
//                            print("Error downloading image from httpsReferenceImage firebase")
//                            print("Error: \(error)")
//                        } else {
//                            currentNumberOfPosts += 1
//                            if currentNumberOfPosts == numberOfPosts {
//                                _log_Element("I have all my post(s)", shouldLog: self.LOG)
//                                _log_FullLineStars(self.LOG)
//                                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
//                            }
//                            let image = UIImage(data: data!)?.resizedImageClosestTo1000
//                            self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image, timestamp: dateTimestampInterval)
//                            self.tableView.reloadData()
//                        }
//                    }
//                } else {
//                    currentNumberOfPosts += 1
//                    if currentNumberOfPosts == numberOfPosts {
//                        print("I have all my posts")
//                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
//                    }
//                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
//                }
//                
//                self.tableView.reloadData()
//            }
//        }
//    }

    
    func obversePosts(){
        initActivityIndicator()
        let postQuery = postRef.queryLimitedToLast(INITIAL_POST_LIMIT)
        postQuery.observeEventType(.Value) { (snapshots: FIRDataSnapshot!) in
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            let numberOfPosts = Int(snapshots.childrenCount)
            var currentNumberOfPosts = 0
            _log_Title("Downloading Posts", location: "PostTableVC.observePosts()", shouldLog: self.LOG)
            _log_Element("I download \(numberOfPosts) post(s)", shouldLog: self.LOG)
            for snapshot in snapshots.children {
                
                guard let titleString = snapshot.value!["title"] as? String else {return}
                guard let descriptionString = snapshot.value!["description"] as? String else {return}
                guard let authorString = snapshot.value!["author"] as? String else {return}
                guard let dateString = snapshot.value!["date"] as? String else {return}
                guard let dateTimestampInterval = snapshot.value!["timestamp"] as? NSTimeInterval else {return}
                guard let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as? NSTimeInterval else {return}
                
                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                    self.lastTimestamp = dateTimestampInterval
                }
                
                self.lastTimestampReverse = dateTimestampInverseInterval
                
                var imageURLString = ""
                if let imageURL = snapshot.value!["imageURL"] as? String {
                    imageURLString = imageURL
                    print("imageURL: \(imageURLString)")
                }
                
                if imageURLString != "" {
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
                    self.tableView.reloadData()
                } else {
                    currentNumberOfPosts += 1
                    if currentNumberOfPosts == numberOfPosts {
                        print("I have all my posts")
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    }
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
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
            
            guard let titleString = snapshot.value!["title"] as? String else {return}
            guard let descriptionString = snapshot.value!["description"] as? String else {return}
            guard let authorString = snapshot.value!["author"] as? String else {return}
            guard let dateString = snapshot.value!["date"] as? String else {return}
            guard let dateTimestampInterval = snapshot.value!["timestamp"] as? NSTimeInterval else {return}
            guard let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as? NSTimeInterval else {return}
            
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            
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
                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
                    self.tableView.reloadData()
                } else {
                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
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


    
    
//    func loadMorePosts() {
//        let postQuery = postRef.queryOrderedByChild("timestampInverse").queryStartingAtValue(lastTimestampReverse).queryLimitedToFirst(LOAD_MORE_POST_LIMIT+LOAD_MORE_POST_LIMIT)
//        var index = UInt(0)
//        postQuery.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
//            print("I download \(snapshot.childrenCount) more posts")
//            
//            guard let titleString = snapshot.value!["title"] as? String else {return}
//            guard let descriptionString = snapshot.value!["description"] as? String else {return}
//            guard let authorString = snapshot.value!["author"] as? String else {return}
//            guard let dateString = snapshot.value!["date"] as? String else {return}
//            guard let dateTimestampInterval = snapshot.value!["timestamp"] as? NSTimeInterval else {return}
//            guard let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as? NSTimeInterval else {return}
//            
//            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
//                self.lastTimestamp = dateTimestampInterval
//            }
//            
//            self.lastTimestampReverse = dateTimestampInverseInterval
//            index += 1
//            var imageURLString = ""
//            if let imageURL = snapshot.value!["imageURL"] as? String {
//                imageURLString = imageURL
//            }
//            print("index: \(index) LOAD_MORE_POST_LIMIT: \(self.LOAD_MORE_POST_LIMIT)")
//            self.printMessage(titleString, description: descriptionString, timestamp: dateTimestampInterval, date: dateString)
//            if index <= (self.LOAD_MORE_POST_LIMIT+self.LOAD_MORE_POST_LIMIT) {
//                if imageURLString != "" {
//                    let httpsReferenceImage = FIRStorage.storage().referenceForURL(imageURLString)
//                    httpsReferenceImage.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
//                        if (error != nil) {
//                            print("Error downloading image from httpsReferenceImage firebase")
//                            print("Error: \(error)")
//                        } else {
//                            let image = UIImage(data: data!)?.resizedImageClosestTo1000
//                            self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image, timestamp: dateTimestampInterval)
//                            self.tableView.reloadData()
//                        }
//                    }
//                } else {
//                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
//                    print("image no present")
//                }
//                
//                print("title = \(titleString), description = \(descriptionString)")
//                self.tableView.reloadData()
//            } else {
//                print("self.tableView.finishInfiniteScroll()")
//                self.tableView.finishInfiniteScroll()
//                self.tableView.reloadData()
//            }
//            
//        }
//        self.resetTimer()
//    }
    
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
    
    func addPostAppend(title: String, description: String, date: String, author: String, imagePresents: Bool, timestamp: NSTimeInterval, urlImage: String) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.append(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, timestamp: timestamp, urlImage: urlImage))
            self.posts.sortInPlace({
                return ($0.timestamp.distanceTo($1.timestamp) < 0)
            })
        } else {
            print("/!\\ le post est déjà présent !!")
        }
    }
    
    func addPostBeginning(title: String, description: String, date: String, author: String, imagePresents: Bool, timestamp: NSTimeInterval, urlImage: String) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.insert(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, timestamp: timestamp, urlImage: urlImage), atIndex: 0)
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
        //tableView.backgroundColor = UIColor(red: 0.77, green: 0.776, blue: 0.8, alpha: 1)
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
        //return 14
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 14
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.grayColor()
        header.tintColor = UIColor(red: 0.77, green: 0.776, blue: 0.8, alpha: 1)
        //header.backgroundColor = UIColor(red: 0.58, green: 0.60, blue: 0.62, alpha: 1)
        //header.textLabel?.textColor = UIColor(red: 0.58, green: 0.60, blue: 0.62, alpha: 1)
        //UIColor(red: 0.90, green: 0.1, blue: 0.15, alpha: 0.5)
        header.textLabel?.font = UIFont.boldSystemFontOfSize(11)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.Center
        // tableView.contentInset = UIEdgeInsetsMake(-14, 0, 0, 0)
        //self.tableView.contentInset = UIEdgeInsetsMake(-dummyViewHeight, 0, 0, 0);
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return posts[section].date
        return ""
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let imagePresents = posts[section].imagePresents

        
        if imagePresents {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell_image", forIndexPath: indexPath) as! PostWithImageTableViewCell
            
            let colorForBorder = UIColor.blackColor()
            let placeholderImage = UIImage(named: "Amicaloading")
            cell.postImageView.kf_setImageWithURL(NSURL(string: posts[section].urlImage)!,
                                                            placeholderImage: placeholderImage,
                                                            optionsInfo: nil,
                                                            progressBlock: { (receivedSize, totalSize) -> () in
                                                                //print("Download Progress: \(receivedSize)/\(totalSize)")
                },
                                                            completionHandler: { (image, error, cacheType, imageURL) -> () in
                                                                print("Downloaded and set!")
                }
            )
            cell.postImageView.contentMode = .ScaleAspectFill
            cell.postImageView.tag = section
            cell.textPostLabel.text = posts[section].description
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.titlePostLabel.text = posts[section].title
            
            cell.datePostLabel.text = posts[section].date
            
            //cell.postImageView.layer.cornerRadius = 6.0;
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
            cell.datePostLabel.text = posts[section].date
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }

        
        
//        if imagePresents {
//            let cell = tableView.dequeueReusableCellWithIdentifier("cell_image", forIndexPath: indexPath) as! PostWithImageTableViewCell
//            
//            let colorForBorder = UIColor.blackColor()
//            cell.postImageView.image = posts[section].image
//            cell.postImageView.contentMode = .ScaleAspectFill
//            cell.postImageView.tag = section
//            cell.textPostLabel.text = posts[section].description
//            cell.selectionStyle = UITableViewCellSelectionStyle.None
//            cell.titlePostLabel.text = posts[section].title
//            
//            cell.postImageView.layer.cornerRadius = 6.0;
//            cell.postImageView.layer.borderWidth = 0.5
//            cell.postImageView.clipsToBounds = true
//            cell.postImageView.layer.borderColor = colorForBorder.CGColor
//            
//            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(PostTableViewController.imageTapped(_:)))
//            cell.postImageView.userInteractionEnabled = true
//            cell.postImageView.addGestureRecognizer(tapGestureRecognizer)
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCellWithIdentifier("cell_no_image", forIndexPath: indexPath) as! PostWithoutImageTableViewCell
//            //cell.textPostLabel.delegate = self
//            cell.titlePostLabel.text = posts[section].title
//            cell.textPostLabel.text = posts[section].description
//            cell.selectionStyle = UITableViewCellSelectionStyle.None
//            return cell
//        }
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
                let ImageView = UIImageView()
                ImageView.kf_setImageWithURL(NSURL(string: post.urlImage))
                arrayPhoto.append(Photo(photo: ImageView.image!))
                if ImageView.image == image {
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
            let ImageView = UIImageView()
            for post in posts {
                if post.imagePresents {
                    ImageView.kf_setImageWithURL(NSURL(string: post.urlImage))
                    guard let _ = ImageView.image else {return}
                }
            }
            ImageView.kf_setImageWithURL(NSURL(string: posts[tag].urlImage))
            let photo = Photo(photo: ImageView.image!)
            let photos = createPhotoArray(ImageView.image!)
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
