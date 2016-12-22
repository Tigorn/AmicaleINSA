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
    
    let LOG = false
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var pseudoTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var pickerViewYearsINSA: UIPickerView!
    @IBOutlet weak var yearSpeGroupLabel: UILabel!
    
    let LIMITE_USERNAME_LENGTH = 14
    let yearsINSA: [(String, String)] = getYearsINSAPlanning()
    var savedMBProgressHUD = MBProgressHUD()
    fileprivate var showYearsPickerINSAVisible = false
    var comeFromWebPlanningBecauseNoGroupSelected = false
    
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
        let defautlRowPickerView = UserDefaults.standard.integer(forKey: Public.rowPickerViewSettings)
        pickerViewYearsINSA.selectRow(defautlRowPickerView, inComponent: 0, animated: true)
        yearSpeGroupLabel.text = yearsINSA[defautlRowPickerView].0
        pseudoTextField.addTarget(self, action: #selector(SettingsTableViewController.pseudoDidChange), for: .editingDidBegin)
        pseudoTextField.addTarget(self, action: #selector(SettingsTableViewController.pseudoChangesFinished), for: .editingDidEnd)
        
        if comeFromWebPlanningBecauseNoGroupSelected {
            showPopUpIfComeFromPlanningBecauseNoGroup()
            comeFromWebPlanningBecauseNoGroupSelected = false
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        profileImageView.image = getProfilPicture()
        registerForNotificationsAndEnterApp(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pseudoTextField.text = getUsernameChat()
    }
    
    fileprivate func initUI() {
        
        // picture
        let tapOnProfilePicture = UITapGestureRecognizer(target: self, action: #selector(SettingsTableViewController.profilePictureSelected))
        profileImageView.addGestureRecognizer(tapOnProfilePicture)
        profileImageView.isUserInteractionEnabled = true
        let colorForBorder = UIColor.black
        profileImageView.layer.borderColor = colorForBorder.cgColor
        profileImageView.layer.borderWidth = 0.5
        self.profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
 
        // text field pseudo
        pseudoTextField.text = Public.usernameChat
        // Year spe group
        yearSpeGroupLabel.layer.cornerRadius = 6.0
        yearSpeGroupLabel.layer.masksToBounds = true
        yearSpeGroupLabel.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        yearSpeGroupLabel.layer.borderWidth = 0.5
    }
    
    /* Delegate textField */
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard var pseudo = pseudoTextField.text else {return false}
        pseudo = pseudo.trim()
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            print("Pseudo: \(pseudo)")
            setUsernameChat(pseudo)
            savedMBProgressHUDAction()
            view.endEditing(true)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        print("newLength: \(newLength)")
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
        _log_Title("Settings Pseudo", location: "SettingsTVC.pseudoChangesFinished()", shouldLog: LOG)
        _log_Element("I end editing the pseudo", shouldLog: LOG)
        _log_FullLineStars(LOG)
        //savedMBProgressHUDAction()
    }
    
    /* Picture methods */
    
    func profilePictureSelected() {
        let imagePickerController = ImagePickerController()
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    
    /* Done button */
    
    @IBAction func doneButtonAction(_ sender: AnyObject) {
        guard var pseudo = pseudoTextField.text else {return}
        pseudo = pseudo.trim()
        print("Pseudo done: \(pseudo)")
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudo)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let frontNavigationController = storyboard.instantiateViewController(withIdentifier: "PostViewController")
            let rearNavifationController = storyboard.instantiateViewController(withIdentifier: "menuViewController")
            let mainRevealController : SWRevealViewController = SWRevealViewController(rearViewController: rearNavifationController, frontViewController: frontNavigationController)
            self.revealViewController().setFront(mainRevealController, animated: true)
        }
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("wrapperDidPress")
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        print("DoneButtonDiDPress")
        if let pickedImage = UIImage(data: images[0].lowestQualityJPEGNSData as Data) {
            profileImageView.image = pickedImage
            setProfilPicture(pickedImage.resizedImageClosestTo1000)
        } else {
            profileImageView.image = UIImage(named: "defaultPic")!
            setProfilPicture(UIImage(named: "defaultPic")!)
        }
        dismiss(animated: true, completion: nil)
    }

    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        print("cancel button pressed")
    }
    
    /* Delegate Picker View */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return yearsINSA.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return yearsINSA[row].0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let idPlanningExpress = yearsINSA[row].1
        let yearSpeGroupString = yearsINSA[row].0
        yearSpeGroupLabel.text = yearSpeGroupString
        UserDefaults.standard.set(row, forKey: Public.rowPickerViewSettings)
        //savedMBProgressHUDAction()
        setIDPlanningExpress(idPlanningExpress)
        setYearSpeGroupPlanningExpress(yearSpeGroupString)
    }
    
    fileprivate func toggleShowDateDatepicker () {
        dismissKeyboard()
        showYearsPickerINSAVisible = !showYearsPickerINSAVisible
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    /* Popup */
    
    fileprivate func showPopUpIfComeFromPlanningBecauseNoGroup() {
        alertViewNoGroupINSA()
    }
    
    
    /* MBProgressHUD */
    
    func savedMBProgressHUDAction(){
        if let superView = self.view.superview {
            savedMBProgressHUD = MBProgressHUD.showAdded(to: superView, animated: true)
        } else {
            savedMBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        }
        savedMBProgressHUD.customView = UIImageView(image: UIImage(named: "37x-Checkmark.png"))
        savedMBProgressHUD.mode = MBProgressHUDMode.customView
        savedMBProgressHUD.labelText = "Saved!"
        savedMBProgressHUD.isUserInteractionEnabled = false
        savedMBProgressHUD.hide(true, afterDelay: 2)
    }
    
    
    /* Keyboard delegate */
    
    func dismissKeyboard() {
        guard var pseudo = pseudoTextField.text else {return}
        pseudo = pseudo.trim()
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudo)
            view.endEditing(true)
        }
    }
    
    func dismissKeyboardFromMenu(_ ViewController: MenuController) {
        guard var pseudo = pseudoTextField.text else {return}
        pseudo = pseudo.trim()
        if stringNotWhiteSpaceAndNotEmpty(pseudo) {
            setUsernameChat(pseudo)
        }
        print("I end editing(true)")
        view.endEditing(true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            _log_Title("Picker", location: "SettingsTVC.didSelectRowAtIndexPath()", shouldLog: LOG)
            _log_Element("Clicked on Picker", shouldLog: LOG)
            _log_FullLineStars(LOG)
            toggleShowDateDatepicker()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !showYearsPickerINSAVisible && indexPath.section == 2 && indexPath.row == 1 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.gray
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.left
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
