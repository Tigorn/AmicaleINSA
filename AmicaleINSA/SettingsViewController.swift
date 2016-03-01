//
//  SettingsViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 01/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var usernameChatTextField: UITextField!
    
    let LIMITE_USERNAME_LENGTH = 12
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        usernameChatTextField.delegate = self
        
        usernameChatTextField.layer.cornerRadius = 8.0
        usernameChatTextField.layer.masksToBounds = true
        usernameChatTextField.layer.borderColor = UIColor.redColor().CGColor
        usernameChatTextField.layer.borderWidth = 2.0
        
        usernameChatTextField.attributedPlaceholder = NSAttributedString(string: Storyboard.usernameChat, attributes: [NSForegroundColorAttributeName: UIColor(red: 100, green: 0, blue: 0, alpha: 0.4)])
        
    }
    
    
    /*
        TextField methodes delegate
    */
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        saveUsernameChat(usernameChatTextField.text!)
        view.endEditing(true)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= LIMITE_USERNAME_LENGTH
    }

    
    func dismissKeyboard() {
        saveUsernameChat(usernameChatTextField.text!)
        view.endEditing(true)
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        usernameChatTextField.text = NSUserDefaults.standardUserDefaults().stringForKey(Storyboard.usernameChat)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
