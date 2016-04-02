//
//  SettingsViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 01/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import ImagePicker
import SWRevealViewController
import MBProgressHUD

class SettingsViewController: UIViewController, UITextFieldDelegate, ImagePickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var usernameChatTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var pickerViewYearsINSA: UIPickerView!
    
    var savedMBProgressHUD = MBProgressHUD()
    
    var yearsINSA = [("1A - A", "667"),
                     ("1A - B", "668"),
                     ("1A - C", "668"),
                     ("1A - D", "668"),
                     ("1A - E", "668"),
                     ("1A - F", "668"),
                     ("1A - G", "668"),
                     ("1A - H", "668"),
                     ("1A - I", "668"),
                     ("1A - J", "668"),
                     ("1A - K", "668"),
                     ("1A - L", "668"),
                     ("1A - M", "668"),
                     ("1A - N", "668"),
                     ("1A - Z", "668"),
                     ("2A-MIC - A", "668"),
                     ("2A-MIC - B", "668"),
                     ("2A-MIC - C", "668")]
    
    let LIMITE_USERNAME_LENGTH = 12
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        
        let tapDismissKeyboard: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.dismissKeyboard))
        view.addGestureRecognizer(tapDismissKeyboard)
        
        usernameChatTextField.delegate = self
        pickerViewYearsINSA.delegate = self
        
        usernameChatTextField.layer.cornerRadius = 8.0
        usernameChatTextField.layer.masksToBounds = true
        usernameChatTextField.layer.borderColor = UIColor.redColor().CGColor
        usernameChatTextField.layer.borderWidth = 2.0
        
        usernameChatTextField.attributedPlaceholder = NSAttributedString(string: Storyboard.usernameChat, attributes: [NSForegroundColorAttributeName: UIColor(red: 100, green: 0, blue: 0, alpha: 0.4)])
        
        // pickerView set default row
        let defautlRowPickerView = NSUserDefaults.standardUserDefaults().integerForKey(Storyboard.rowPickerViewSettings)
        pickerViewYearsINSA.selectRow(defautlRowPickerView, inComponent: 0, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        profileImageView.image = getProfilPicture()
    }
    
    func profilePictureSelected() {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    /*
        PickerView delegate
    */
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return yearsINSA.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return yearsINSA[row].0
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let idPlanningExpress = yearsINSA[row].1
        NSUserDefaults.standardUserDefaults().setInteger(row, forKey: Storyboard.rowPickerViewSettings)
        NSUserDefaults.standardUserDefaults().setObject(idPlanningExpress, forKey: Storyboard.idPlanningExpress)
        savedMBProgressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        savedMBProgressHUD.customView = UIImageView(image: UIImage(named: "37x-Checkmark.png"))
        savedMBProgressHUD.mode = MBProgressHUDMode.CustomView
        savedMBProgressHUD.labelText = "Saved!"
        savedMBProgressHUD.userInteractionEnabled = false
        savedMBProgressHUD.hide(true, afterDelay: 2)
    }
    
    
    
    func dismissKeyboard() {
        setUsernameChat(usernameChatTextField.text!)
        view.endEditing(true)
    }
    
    private func initUI() {
        let tapOnProfilePicture = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.profilePictureSelected))
        profileImageView.addGestureRecognizer(tapOnProfilePicture)
        profileImageView.userInteractionEnabled = true
        let colorForBorder = UIColor.blackColor()
        profileImageView.layer.borderColor = colorForBorder.CGColor
        profileImageView.layer.borderWidth = 0.5
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
    }
    
    /*
        Image Picker methodes delegate
    */
    
    func wrapperDidPress(images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(images: [UIImage]) {
        let pickedImage = images[0].imageRotatedByDegrees(90, flip: false)
        profileImageView.image = pickedImage
        setProfilPicture(pickedImage)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func cancelButtonDidPress() {
        print("cancel button pressed")
    }

    
    /*
        TextField methodes delegate
    */
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        setUsernameChat(usernameChatTextField.text!)
        view.endEditing(true)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= LIMITE_USERNAME_LENGTH
    }
    
    override func viewWillAppear(animated: Bool) {
        usernameChatTextField.text = getUsernameChat()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}
