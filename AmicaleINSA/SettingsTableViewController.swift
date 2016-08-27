//
//  SettingsTableViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 17/07/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SWRevealViewController
import ImagePicker
import MBProgressHUD

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, ImagePickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, MenuControllerDelegate {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var pseudoTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var pickerViewYearsINSA: UIPickerView!
    @IBOutlet weak var yearSpeGroupLabel: UILabel!
    
    let LIMITE_USERNAME_LENGTH = 14
    let yearsINSA: [(String, String)] = getYearsINSAPlanning()
    var savedMBProgressHUD = MBProgressHUD()
    private var showYearsPickerINSAVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        initUI()
        setBeenToSettingsOnce()
        pseudoTextField.delegate = self
        pickerViewYearsINSA.delegate = self
        // pickerView set default row
        let defautlRowPickerView = NSUserDefaults.standardUserDefaults().integerForKey(Public.rowPickerViewSettings)
        pickerViewYearsINSA.selectRow(defautlRowPickerView, inComponent: 0, animated: true)
        yearSpeGroupLabel.text = yearsINSA[defautlRowPickerView].0
        pseudoTextField.addTarget(self, action: #selector(SettingsTableViewController.pseudoDidChange), forControlEvents: .EditingDidBegin)
        pseudoTextField.addTarget(self, action: #selector(SettingsTableViewController.pseudoChangesFinished), forControlEvents: .EditingDidEnd)
    }
    
    override func viewDidAppear(animated: Bool) {
        profileImageView.image = getProfilPicture()
        registerForNotificationsAndEnterApp(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        pseudoTextField.text = getUsernameChat()
    }
    
    private func initUI() {
        
        // picture
        let tapOnProfilePicture = UITapGestureRecognizer(target: self, action: #selector(SettingsTableViewController.profilePictureSelected))
        profileImageView.addGestureRecognizer(tapOnProfilePicture)
        profileImageView.userInteractionEnabled = true
        let colorForBorder = UIColor.blackColor()
        profileImageView.layer.borderColor = colorForBorder.CGColor
        profileImageView.layer.borderWidth = 0.5
        self.profileImageView.contentMode = .ScaleAspectFill
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
 
        // text field pseudo
        pseudoTextField.text = Public.usernameChat
        // Year spe group
        yearSpeGroupLabel.layer.cornerRadius = 6.0
        yearSpeGroupLabel.layer.masksToBounds = true
        yearSpeGroupLabel.layer.borderColor = UIColor.grayColor().colorWithAlphaComponent(0.5).CGColor
        yearSpeGroupLabel.layer.borderWidth = 0.5
    }
    
    /* Delegate textField */
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let pseudo = pseudoTextField.text!
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudoTextField.text!)
            savedMBProgressHUDAction()
            view.endEditing(true)
        }
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= LIMITE_USERNAME_LENGTH
    }
    
    func pseudoDidChange() {
        if showYearsPickerINSAVisible {
            showYearsPickerINSAVisible = false
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func pseudoChangesFinished() {
        print("I end editing")
        //savedMBProgressHUDAction()
    }
    
    /* Picture methods */
    
    func profilePictureSelected() {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    
    /* Done button */
    
    @IBAction func doneButtonAction(sender: AnyObject) {
        print("doneButtonAction clicked")
        let pseudo = pseudoTextField.text!
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudoTextField.text!)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let frontNavigationController = storyboard.instantiateViewControllerWithIdentifier("PostViewController")
            let rearNavifationController = storyboard.instantiateViewControllerWithIdentifier("menuViewController")
            let mainRevealController : SWRevealViewController = SWRevealViewController(rearViewController: rearNavifationController, frontViewController: frontNavigationController)
            self.revealViewController().setFrontViewController(mainRevealController, animated: true)
        }
    }
    
    func wrapperDidPress(imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(imagePicker: ImagePickerController, images: [UIImage]) {
        print("DoneButtonDiDPress")
        if let pickedImage = UIImage(data: images[0].lowestQualityJPEGNSData) {
            profileImageView.image = pickedImage
            setProfilPicture(pickedImage.resizedImageClosestTo1000)
        } else {
            profileImageView.image = UIImage(named: "defaultPic")!
            setProfilPicture(UIImage(named: "defaultPic")!)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    func cancelButtonDidPress(imagePicker: ImagePickerController) {
        print("cancel button pressed")
    }
    
    /* Delegate Picker View */
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return yearsINSA.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return yearsINSA[row].0
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let idPlanningExpress = yearsINSA[row].1
        let yearSpeGroupString = yearsINSA[row].0
        yearSpeGroupLabel.text = yearSpeGroupString
        NSUserDefaults.standardUserDefaults().setInteger(row, forKey: Public.rowPickerViewSettings)
        //savedMBProgressHUDAction()
        setIDPlanningExpress(idPlanningExpress)
        setYearSpeGroupPlanningExpress(yearSpeGroupString)
    }
    
    private func toggleShowDateDatepicker () {
        dismissKeyboard()
        showYearsPickerINSAVisible = !showYearsPickerINSAVisible
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    
    /* MBProgressHUD */
    
    func savedMBProgressHUDAction(){
        if let superView = self.view.superview {
            savedMBProgressHUD = MBProgressHUD.showHUDAddedTo(superView, animated: true)
        } else {
            savedMBProgressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        }
        savedMBProgressHUD.customView = UIImageView(image: UIImage(named: "37x-Checkmark.png"))
        savedMBProgressHUD.mode = MBProgressHUDMode.CustomView
        savedMBProgressHUD.labelText = "Saved!"
        savedMBProgressHUD.userInteractionEnabled = false
        savedMBProgressHUD.hide(true, afterDelay: 2)
    }
    
    
    /* Keyboard delegate */
    
    func dismissKeyboard() {
        let pseudo = pseudoTextField.text!
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudoTextField.text!)
            view.endEditing(true)
        }
    }
    
    func dismissKeyboardFromMenu(ViewController: MenuController) {
        let pseudo = pseudoTextField.text!
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudoTextField.text!)
        }
        print("I end editing(true)")
        view.endEditing(true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            print("Clicked on Picker")
            toggleShowDateDatepicker()
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if !showYearsPickerINSAVisible && indexPath.section == 2 && indexPath.row == 1 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.grayColor()
        header.textLabel?.font = UIFont.boldSystemFontOfSize(13)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.Left
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
