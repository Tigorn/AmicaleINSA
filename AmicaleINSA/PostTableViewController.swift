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
    
    let INITIAL_POST_LIMIT = UInt(15)
    let LOAD_MORE_POST_LIMIT  = UInt(10)
    
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
    
    var postRef: Firebase!
    
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
        print("bool = \(getBeenToSettingsOnce())")
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
        
        var SwiftSpinnerAlreadyHidden = false
        
        let postQuery = postRef.queryLimitedToLast(INITIAL_POST_LIMIT)
        postQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
        
            if !SwiftSpinnerAlreadyHidden {
                SwiftSpinnerAlreadyHidden = true
                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
            }
            var titleString = ""
            var descriptionString = ""
            var authorString = ""
            var dateString = ""
            var imagePresentsBool = false
            var imageDataString = ""
            
            if let title = snapshot.value.objectForKey("title") as? String {
                titleString = title
            }
            
            if let description = snapshot.value.objectForKey("description") as? String {
                descriptionString = description
            }
            
            if let author = snapshot.value.objectForKey("author") as? String {
                authorString = author
            }
            
            if let date = snapshot.value.objectForKey("date") as? String {
                dateString = date
            }
            
            if let imagePresents = snapshot.value.objectForKey("imagePresents") as? Bool {
                imagePresentsBool = imagePresents
            }
            
            if let imageData = snapshot.value.objectForKey("imageData") as? String {
                imageDataString = imageData
            }
            
            if let timestamp = snapshot.value.objectForKey("timestamp") as? String {
                imageDataString = timestamp
            }
            
            let dateTimestampInterval = snapshot.value["timestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
            }
            
            let dateTimestampInverseInterval = snapshot.value["timestampInverse"] as! NSTimeInterval
            self.lastTimestampReverse = dateTimestampInverseInterval
            
            if imagePresentsBool {
                print("image present")
                let base64EncodedString = imageDataString
                if let imageData = NSData(base64EncodedString: base64EncodedString,
                    options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
                    let image = UIImage(data: imageData)
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image!, timestamp: dateTimestampInterval)
                } else {
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
                    print("image no present, imageData bug!")
                }
            } else {
                self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
                print("image no present")
            }
            
            self.tableView.reloadData()
        }
    }
    
    

    func loadMorePosts() {
        let postQuery = postRef.queryOrderedByChild("timestampInverse").queryStartingAtValue(lastTimestampReverse).queryLimitedToFirst(LOAD_MORE_POST_LIMIT+LOAD_MORE_POST_LIMIT)
        var index = UInt(0)
        postQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            var titleString = ""
            var descriptionString = ""
            var authorString = ""
            var dateString = ""
            var imagePresentsBool = false
            var imageDataString = ""
            
            if let title = snapshot.value.objectForKey("title") as? String {
                titleString = title
            }
            
            if let description = snapshot.value.objectForKey("description") as? String {
                descriptionString = description
            }
            
            if let author = snapshot.value.objectForKey("author") as? String {
                authorString = author
            }
            
            if let date = snapshot.value.objectForKey("date") as? String {
                dateString = date
            }
            
            if let imagePresents = snapshot.value.objectForKey("imagePresents") as? Bool {
                imagePresentsBool = imagePresents
            }
            
            if let imageData = snapshot.value.objectForKey("imageData") as? String {
                imageDataString = imageData
            }
            
            let dateTimestampInterval = snapshot.value["timestamp"] as! NSTimeInterval
            if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                self.lastTimestamp = dateTimestampInterval
                //print("---------------> in lastTimeStamp update : title = \(titleString)")
            }
            let dateTimestampInverseInterval = snapshot.value["timestampInverse"] as! NSTimeInterval
            self.lastTimestampReverse = dateTimestampInverseInterval
            index += 1
            print("index: \(index) LOAD_MORE_POST_LIMIT: \(self.LOAD_MORE_POST_LIMIT)")
            self.printMessage(titleString, description: descriptionString, timestamp: dateTimestampInterval, date: dateString)
            if index <= (self.LOAD_MORE_POST_LIMIT+self.LOAD_MORE_POST_LIMIT) {
                //print("index = \(index), self.LOAD_MORE_POST_LIMIT = \(self.LOAD_MORE_POST_LIMIT)")
                if imagePresentsBool {
                    //print("image present")
                    let base64EncodedString = imageDataString
                    if let imageData = NSData(base64EncodedString: base64EncodedString,
                                              options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
                        let image = UIImage(data: imageData)
                            self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image!, timestamp: dateTimestampInterval)
                    } else {
                            self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil, timestamp: dateTimestampInterval)
                        print("image no present, imageData bug!")
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
        //print("------------------------------------------------------------------")
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false{
            self.posts.append(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, image: image, timestamp: timestamp))
        } else {
            print("/!\\ le post est déjà présent !!")
        }
        //print("D'add dans mon array [append]")
        //print("title = \(title), description = \(description) timestamp = \(timestamp)")
        //print("------------------------------------------------------------------")
    }
    
    func addPostBeginning(title: String, description: String, date: String, author: String, imagePresents: Bool, image: UIImage?, timestamp: NSTimeInterval) {
        self.posts.insert(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, image: image, timestamp: timestamp), atIndex: 0)
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
        //print("TIMERRRR 1")
        timer = nextTimer
    }
    
    func handleIdleEvent(timer: NSTimer) {
        //print("TIMERRRR 2")
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
        initActivityIndicator()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //print("posts.count = \(posts.count)")
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
            
            cell.postImageView.layer.cornerRadius = 10.0;
            cell.postImageView.layer.borderWidth = 0.5
            cell.postImageView.clipsToBounds = true
            cell.postImageView.layer.borderColor = colorForBorder.CGColor
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(PostTableViewController.imageTapped(_:)))
            cell.postImageView.userInteractionEnabled = true
            cell.postImageView.addGestureRecognizer(tapGestureRecognizer)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell_no_image", forIndexPath: indexPath) as! PostWithoutImageTableViewCell
            cell.titlePostLabel.text = posts[section].title
            cell.textPostLabel.text = posts[section].description
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func initActivityIndicator() {
        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = "Loading..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PostTableViewController.tapToCancel)))
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
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
                print("Tag calc = \(tagIndexPhotoInArray)")
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
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
