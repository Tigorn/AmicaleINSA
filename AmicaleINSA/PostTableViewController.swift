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
        var timestamp: TimeInterval
        var urlImage: String
    }
    
    
    var posts = [post]()
    var postRef: FIRDatabaseReference!
    var lastTimestamp: TimeInterval!
    var lastTimestampReverse: TimeInterval!
    
    var timer = Timer()
    
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var myActivityIndicator: UIActivityIndicatorView!
    var myActivityIndicatorHUD = MBProgressHUD()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
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
        
        self.refreshControl?.addTarget(self, action: #selector(PostTableViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        
        postRef = FirebaseManager.firebaseManager.createPostRef()
        
        tableView.estimatedRowHeight = 405
        tableView.rowHeight = UITableViewAutomaticDimension
        
        obversePosts()
        
        lastTimestampReverse = 0
    }
    
    
    func segueToSettingsIfNeeded(){
        if !getBeenToSettingsOnce() {
            self.performSegue(withIdentifier: Public.segueBeenToSettingsOnce, sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    func refresh(_ sender:AnyObject)
    {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(PostTableViewController.endRefresh), userInfo: nil, repeats: true)
    }
    
    func endRefresh(){
        self.refreshControl!.endRefreshing()
    }
    
    func initUI() {
        tableView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.addInfiniteScroll { (scrollView) -> Void in
            self.loadMorePosts()
        }
    }
    
    
    func obversePosts(){
        initActivityIndicator()
        let postQuery = postRef.queryLimited(toLast: INITIAL_POST_LIMIT)
        
        postQuery.observe(.value, with: { (snapshots) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let numberOfPosts = Int(snapshots.childrenCount)
            var currentNumberOfPosts = 0
            _log_Title("Downloading Posts", location: "PostTableVC.observePosts()", shouldLog: self.LOG)
            _log_Element("I download \(numberOfPosts) post(s)", shouldLog: self.LOG)
            //            for snapshot in snapshots.children {
            //                print("Snapshot: ", snapshot.value)
            //                //let snapDict = snapshot as? [String: Any]
            //                //print("snapDict: ", snapDict)
            //                //guard let titleString = snapshot["title"] as? String else {return}
            //            }
            let snapDict = snapshots.value as! [String:Any]
            for snapshot in snapDict {
                //    print("snapshot: ", snapshot)
            }
            for child in snapshots.children {
                let snap = child as! FIRDataSnapshot
                let dict = snap.value as! [String: Any]
                guard let titleString = dict["title"] as? String else {return}
                guard let descriptionString = dict["description"] as? String else {return}
                guard let authorString = dict["author"] as? String else {return}
                guard let dateString = dict["date"] as? String else {return}
                guard let dateTimestampInterval = dict["timestamp"] as? TimeInterval else {return}
                guard let dateTimestampInverseInterval = dict["timestampInverse"] as? TimeInterval else {return}
                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
                    self.lastTimestamp = dateTimestampInterval
                }
                
                self.lastTimestampReverse = dateTimestampInverseInterval
                
                var imageURLString = ""
                if let imageURL = dict["imageURL"] as? String {
                    imageURLString = imageURL
                }
                
                if imageURLString != "" {
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
                    self.tableView.reloadData()
                } else {
                    currentNumberOfPosts += 1
                    if currentNumberOfPosts == numberOfPosts {
                        print("I have all my posts")
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                    }
                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
                }
                
                self.tableView.reloadData()
            }
            
        })
    }
    //                guard let titleString = snapshot.value!["title"] as? String else {return}
    //                guard let titleString = (snapshot as NSDictionary).value!["title"] as? String else {return}
    //                guard let descriptionString = (snapshot as AnyObject).value!["description"] as? String else {return}
    //                guard let authorString = (snapshot as AnyObject).value!["author"] as? String else {return}
    //                guard let dateString = (snapshot as AnyObject).value!["date"] as? String else {return}
    //                guard let dateTimestampInterval = (snapshot as AnyObject).value!["timestamp"] as? TimeInterval else {return}
    //                guard let dateTimestampInverseInterval = (snapshot as AnyObject).value!["timestampInverse"] as? TimeInterval else {return}
    //
    //                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                    self.lastTimestamp = dateTimestampInterval
    //                }
    //
    //                self.lastTimestampReverse = dateTimestampInverseInterval
    //
    //                var imageURLString = ""
    //                if let imageURL = (snapshot as AnyObject).value!["imageURL"] as? String {
    //                    imageURLString = imageURL
    //                }
    //
    //                if imageURLString != "" {
    //                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
    //                    self.tableView.reloadData()
    //                } else {
    //                    currentNumberOfPosts += 1
    //                    if currentNumberOfPosts == numberOfPosts {
    //                        print("I have all my posts")
    //                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
    //                    }
    //                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
    //                }
    //
    //                self.tableView.reloadData()
    //            }
    //
    //        })
    //    }
    
    
    //        postQuery.observe(.value) { (snapshots: FIRDataSnapshot!) in
    //            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
    //            let numberOfPosts = Int(snapshots.childrenCount)
    //            var currentNumberOfPosts = 0
    //            _log_Title("Downloading Posts", location: "PostTableVC.observePosts()", shouldLog: self.LOG)
    //            _log_Element("I download \(numberOfPosts) post(s)", shouldLog: self.LOG)
    //
    //            for snapshot in snapshots.children {
    //
    //
    //
    //
    //                guard let titleString = snapshot.value!["title"] as? String else {return}
    //                guard let titleString = (snapshot as NSDictionary).value!["title"] as? String else {return}
    //                guard let descriptionString = (snapshot as AnyObject).value!["description"] as? String else {return}
    //                guard let authorString = (snapshot as AnyObject).value!["author"] as? String else {return}
    //                guard let dateString = (snapshot as AnyObject).value!["date"] as? String else {return}
    //                guard let dateTimestampInterval = (snapshot as AnyObject).value!["timestamp"] as? TimeInterval else {return}
    //                guard let dateTimestampInverseInterval = (snapshot as AnyObject).value!["timestampInverse"] as? TimeInterval else {return}
    //
    //                if (self.shouldUpdateLastTimestamp(dateTimestampInterval)){
    //                    self.lastTimestamp = dateTimestampInterval
    //                }
    //
    //                self.lastTimestampReverse = dateTimestampInverseInterval
    //
    //                var imageURLString = ""
    //                if let imageURL = (snapshot as AnyObject).value!["imageURL"] as? String {
    //                    imageURLString = imageURL
    //                }
    //
    //                if imageURLString != "" {
    //                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
    //                    self.tableView.reloadData()
    //                } else {
    //                    currentNumberOfPosts += 1
    //                    if currentNumberOfPosts == numberOfPosts {
    //                        print("I have all my posts")
    //                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
    //                    }
    //                    self.addPostBeginning(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
    //                }
    //
    //                self.tableView.reloadData()
    //            }
    //        }
    
    
    func loadMorePosts() {
        //        let postQuery = postRef.queryOrdered(byChild: "timestampInverse").queryStarting(atValue: lastTimestampReverse).queryLimited(toFirst: LOAD_MORE_POST_LIMIT+LOAD_MORE_POST_LIMIT)
        //        var index = UInt(0)
        //        postQuery.observe(.childAdded) { (snapshot: FIRDataSnapshot!) in
        //            print("I download \(snapshot.childrenCount) more posts")
        //
        ////            guard let titleString = snapshot.value!["title"] as? String else {return}
        ////            guard let descriptionString = snapshot.value!["description"] as? String else {return}
        ////            guard let authorString = snapshot.value!["author"] as? String else {return}
        ////            guard let dateString = snapshot.value!["date"] as? String else {return}
        ////            guard let dateTimestampInterval = snapshot.value!["timestamp"] as? TimeInterval else {return}
        ////            guard let dateTimestampInverseInterval = snapshot.value!["timestampInverse"] as? TimeInterval else {return}
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
        //                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, timestamp: dateTimestampInterval, urlImage: imageURLString)
        //                    self.tableView.reloadData()
        //                } else {
        //                    self.addPostAppend(titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, timestamp: dateTimestampInterval, urlImage: "")
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
    }
    
    func printMessage(_ title:String, description: String, timestamp: TimeInterval, date: String) {
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
    
    func addPostAppend(_ title: String, description: String, date: String, author: String, imagePresents: Bool, timestamp: TimeInterval, urlImage: String) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.append(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, timestamp: timestamp, urlImage: urlImage))
            self.posts.sort(by: {
                return ($0.timestamp.distance(to: $1.timestamp) < 0)
            })
        } else {
            print("/!\\ le post est déjà présent !!")
        }
    }
    
    func addPostBeginning(_ title: String, description: String, date: String, author: String, imagePresents: Bool, timestamp: TimeInterval, urlImage: String) {
        if self.postAlreadyPresent(timestamp, titleDescription: "\(title)\(description)") == false {
            self.posts.insert(post(title: title, description: description, date: date, author: author, imagePresents: imagePresents, timestamp: timestamp, urlImage: urlImage), at: 0)
            self.posts.sort(by: {
                return ($0.timestamp.distance(to: $1.timestamp) < 0)
            })
        } else {
            print("ObservePost: post already present!!")
        }
    }
    
    func postAlreadyPresent(_ timestampPost: TimeInterval, titleDescription: String) -> Bool {
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
        let nextTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(PostTableViewController.handleIdleEvent(_:)), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    func handleIdleEvent(_ timer: Timer) {
        self.tableView.finishInfiniteScroll()
    }
    
    func shouldUpdateLastTimestamp(_ timestamp: TimeInterval) -> Bool {
        return (lastTimestamp == nil) || timestamp < lastTimestamp
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        registerForNotificationsAndEnterApp(self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 14
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.gray
        header.tintColor = UIColor(red: 0.77, green: 0.776, blue: 0.8, alpha: 1)
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return posts[section].date
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let imagePresents = posts[section].imagePresents
        
        
        if imagePresents {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell_image", for: indexPath) as! PostWithImageTableViewCell
            
            let colorForBorder = UIColor.black
            let placeholderImage = UIImage(named: "Amicaloading")
            cell.postImageView.kf.setImage(with: URL(string: posts[section].urlImage)!, placeholder: placeholderImage, options: nil, progressBlock: nil, completionHandler: nil
            )
            cell.postImageView.contentMode = .scaleAspectFill
            cell.postImageView.tag = section
            cell.descriptionTextView.text = posts[section].description
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.titlePostLabel.text = posts[section].title
            
            cell.datePostLabel.text = posts[section].date
            
            //cell.postImageView.layer.cornerRadius = 6.0;
            cell.postImageView.layer.borderWidth = 0.5
            cell.postImageView.clipsToBounds = true
            cell.postImageView.layer.borderColor = colorForBorder.cgColor
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(PostTableViewController.imageTapped(_:)))
            cell.postImageView.isUserInteractionEnabled = true
            cell.postImageView.addGestureRecognizer(tapGestureRecognizer)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell_no_image", for: indexPath) as! PostWithoutImageTableViewCell
            cell.titlePostLabel.text = posts[section].title
            cell.descriptionTextView.text = posts[section].description
            cell.datePostLabel.text = posts[section].date
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }
    }
    
    func initActivityIndicator() {
        myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.indeterminate
        myActivityIndicatorHUD.labelText = "Loading..."
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PostTableViewController.tapToCancel)))
        myActivityIndicatorHUD.layer.zPosition = 2
        self.tableView.layer.zPosition = 1
    }
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
    }
    
    func createPhotoArray(_ image: UIImage) -> ([Photo], Int) {
        var arrayPhoto = [Photo]()
        var index = 0
        var tag = -1
        for post in posts {
            if post.imagePresents {
                let ImageView = UIImageView()
                ImageView.kf.setImage(with: URL(string: post.urlImage))
                if let imageViewImage = ImageView.image {
                    arrayPhoto.append(Photo(photo: imageViewImage))
                    if imageViewImage == image {
                        tag = index
                    }
                    index += 1
                }
            }
        }
        return (arrayPhoto, tag)
    }
    
    func imageTapped(_ img: AnyObject)
    {
        if let tag = img.view?.tag {
            let ImageView = UIImageView()
            //            for post in posts {
            //                if post.imagePresents {
            //                    ImageView.kf_setImageWithURL(NSURL(string: post.urlImage))
            //                    //guard let _ = ImageView.image else {return}
            //                }
            //            }
            ImageView.kf.setImage(with: URL(string: posts[tag].urlImage))
            guard let _ = ImageView.image else {return}
            let photo = Photo(photo: ImageView.image!)
            let photos = createPhotoArray(ImageView.image!)
            let tagIndexPhotoInArray = photos.1
            if tagIndexPhotoInArray != -1 {
                let viewer = NYTPhotosViewController(photos: photos.0, initialPhoto: photos.0[tagIndexPhotoInArray])
                present(viewer, animated: true, completion: nil)
            } else {
                let viewer = NYTPhotosViewController(photos: [photo])
                present(viewer, animated: true, completion: nil)
            }
        } else {
            print("Problem with the tag when I click on an image")
        }
    }
    
}
