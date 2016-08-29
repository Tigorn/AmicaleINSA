//
//  MenuController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import Firebase

protocol MenuControllerDelegate  { 
    func dismissKeyboardFromMenu(_: MenuController)
}

class MenuController: UITableViewController {
    
    @IBOutlet weak var topViewMenu: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameChatLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    var delegate : MenuControllerDelegate?
    let LOG = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateUI()
        delegate?.dismissKeyboardFromMenu(self)
    }
    
    private func updateUI() {
        usernameChatLabel.text = getUsernameChat()
        profileImageView.image = getProfilPicture()
        temperatureLabel.text = getTemperature()
    }
    
    
    private func initUI() {
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        profileImageView.layer.borderWidth = 0.5
        profileImageView.layer.borderColor =   UIColor.blackColor().CGColor
        profileImageView.clipsToBounds = true
        self.profileImageView.contentMode = .ScaleAspectFill
        UIGraphicsBeginImageContext(self.topViewMenu.frame.size)
        let image: UIImage = UIImage(named: "redGradient3")!
        image.drawInRect(self.topViewMenu.bounds)
        UIGraphicsEndImageContext()
        topViewMenu.backgroundColor = UIColor(patternImage: image)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)
    {
        if(segue.identifier == "GoToChat")
        {
            super.prepareForSegue(segue, sender: sender)
            let navVc = segue.destinationViewController as! UINavigationController
            let chatVc = navVc.viewControllers.first as! ChatViewController
            let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
            
            /* ça c'est pas bon parce qu'il faut faire la diff entre plusieurs pseudos, */
            chatVc.senderId = "\(uuid.md5())"
            chatVc.senderDisplayName = getUsernameChat()
            _log_Title("Pseudo Chat", location: "MenuController.prepareForSegue()", shouldLog: LOG)
            _log_Element("Sender Display Name: \(chatVc.senderDisplayName)", shouldLog: LOG)
            _log_FullLineStars(LOG)
            delegate = chatVc
        } else if (segue.identifier == "GoToSettings"){
            let navVc = segue.destinationViewController as! UINavigationController
            let settingsTVc = navVc.viewControllers.first as! SettingsTableViewController
            delegate = settingsTVc
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
