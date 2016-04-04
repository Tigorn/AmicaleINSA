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

class PostTableViewController: UITableViewController {
    
    let text1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    let text2 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    
    let arrayImage = ["image2", "image3"]
    
    struct post {
        var title: String
        var description : String
        var date: String
        var author: String
        var imagePresents: Bool
        var image: UIImage?
    }
    
    var posts = [post]()
    
    var postRef: Firebase!
    
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
        
        initApp()
        
        postRef = FirebaseManager.firebaseManager.createPostRef()
        
        tableView.estimatedRowHeight = 405
        tableView.rowHeight = UITableViewAutomaticDimension
        
        obversePosts()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func obversePosts(){
        var SwiftSpinnerAlreadyHidden = false
        postRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            if !SwiftSpinnerAlreadyHidden {
                SwiftSpinnerAlreadyHidden = true
                //MBProgressHUD.hideAllHUDsForView(self.appDelegate.window, animated: true)
                MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
            }
            var titleString = ""
            var descriptionString = ""
            var authorString = ""
            var dateString = ""
            var imagePresentsBool = false
            var imageDataString = ""
            //let title = snapshot.value.objectForKey("title") as! String
            if let title = snapshot.value.objectForKey("title") as? String {
                titleString = title
            }
            //let description = snapshot.value.objectForKey("description") as! String
            if let description = snapshot.value.objectForKey("description") as? String {
                descriptionString = description
            }
            //let author = snapshot.value.objectForKey("author") as! String
            if let author = snapshot.value.objectForKey("author") as? String {
                authorString = author
            }
            //let date = snapshot.value.objectForKey("date") as! String
            if let date = snapshot.value.objectForKey("date") as? String {
                dateString = date
            }
            //let imagePresents = snapshot.value.objectForKey("imagePresents") as! Bool
            if let imagePresents = snapshot.value.objectForKey("imagePresents") as? Bool {
                imagePresentsBool = imagePresents
            }
            //let imageData = snapshot.value.objectForKey("imageData") as! String
            if let imageData = snapshot.value.objectForKey("imageData") as? String {
                imageDataString = imageData
            }
            
            if imagePresentsBool {
                print("image present")
                let base64EncodedString = imageDataString
                if let imageData = NSData(base64EncodedString: base64EncodedString,
                    options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) {
                    let image = UIImage(data: imageData)
                    self.posts.insert(post(title: titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: true, image: image!), atIndex:0)
                } else {
                    self.posts.insert(post(title: titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil), atIndex:0)
                    print("image no present, imageData bug!")
                }
            } else {
                self.posts.insert(post(title: titleString, description: descriptionString, date: dateString, author: authorString, imagePresents: false, image: nil), atIndex:0)
                print("image no present")
            }
            print(snapshot.value.objectForKey("author")!)
            print(snapshot.value.objectForKey("title")!)
            print(snapshot.value.objectForKey("description")!)
            print(snapshot.value.objectForKey("imagePresents")!)
            /*
             let base64EncodedString = snapshot.value["image"] as! String
             let imageData = NSData(base64EncodedString: base64EncodedString,
             options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
             */
            
            self.tableView.reloadData()
        })
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.reloadData()
        initActivityIndicator()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        print("posts.count = \(posts.count)")
        return posts.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    //    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //        let headerView = UIView()
    //        if section == 0 {
    //            return headerView
    //        } else {
    //            headerView.backgroundColor = UIColor.lightGrayColor()
    //            headerView.alpha = 0.75
    //            return headerView
    //        }
    //    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.grayColor()
        header.textLabel?.font = UIFont.boldSystemFontOfSize(13)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.Center
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //        if section == 0 {
        //            return "01/01/2016"
        //        } else {
        //            return "02/01/2016"
        //        }
        return posts[section].date
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        //let row = indexPath.row
        let imagePresents = posts[section].imagePresents
        
        if imagePresents {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell_image", forIndexPath: indexPath) as! PostWithImageTableViewCell
            //let image = UIImage(named: arrayImage[indexPath.row%2])
            
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
    
    func imageTapped(img: AnyObject)
    {
        if let tag = img.view?.tag {
            print("image clicked, tag = \(tag)")
            let image = posts[tag].image
            print("ici c'est ok ")
            let photo = Photo(photo: image!)
            let viewer = NYTPhotosViewController(photos: [photo])
            presentViewController(viewer, animated: true, completion: nil)
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
