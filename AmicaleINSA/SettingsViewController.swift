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

class SettingsViewController: UIViewController, UITextFieldDelegate, ImagePickerDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var usernameChatTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
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
        
        usernameChatTextField.layer.cornerRadius = 8.0
        usernameChatTextField.layer.masksToBounds = true
        usernameChatTextField.layer.borderColor = UIColor.redColor().CGColor
        usernameChatTextField.layer.borderWidth = 2.0
        
        usernameChatTextField.attributedPlaceholder = NSAttributedString(string: Storyboard.usernameChat, attributes: [NSForegroundColorAttributeName: UIColor(red: 100, green: 0, blue: 0, alpha: 0.4)])
        
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
