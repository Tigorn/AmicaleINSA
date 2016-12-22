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
    
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
        delegate?.dismissKeyboardFromMenu(self)
    }
    
    fileprivate func updateUI() {
        usernameChatLabel.text = getUsernameChat()
        profileImageView.image = getProfilPicture()
        temperatureLabel.text = getTemperature()
    }
    
    
    fileprivate func initUI() {
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        profileImageView.layer.borderWidth = 0.5
        profileImageView.layer.borderColor =   UIColor.black.cgColor
        profileImageView.clipsToBounds = true
        self.profileImageView.contentMode = .scaleAspectFill
        UIGraphicsBeginImageContext(self.topViewMenu.frame.size)
        let image: UIImage = UIImage(named: "redGradient3")!
        image.draw(in: self.topViewMenu.bounds)
        UIGraphicsEndImageContext()
        topViewMenu.backgroundColor = UIColor(patternImage: image)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!)
    {
        if(segue.identifier == "GoToChat")
        {
            super.prepare(for: segue, sender: sender)
            let navVc = segue.destination as! UINavigationController
            let chatVc = navVc.viewControllers.first as! ChatViewController
            let uuid = UIDevice.current.identifierForVendor!.uuidString
            
            /* ça c'est pas bon parce qu'il faut faire la diff entre plusieurs pseudos, */
            chatVc.senderId = "\(uuid.md5())"
            chatVc.senderDisplayName = getUsernameChat()
            _log_Title("Pseudo Chat", location: "MenuController.prepareForSegue()", shouldLog: LOG)
            _log_Element("Sender Display Name: \(chatVc.senderDisplayName)", shouldLog: LOG)
            _log_FullLineStars(LOG)
            delegate = chatVc
        } else if (segue.identifier == "GoToSettings"){
            let navVc = segue.destination as! UINavigationController
            let settingsTVc = navVc.viewControllers.first as! SettingsTableViewController
            delegate = settingsTVc
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
