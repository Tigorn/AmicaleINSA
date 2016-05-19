//
//  Public.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SCLAlertView

public struct Public {
    
    // Chat
    static let usernameChat = "usernameChat"
    static let usernameChatRegistred = "usernameChatRegistred"
    
    // Settings
    static let profilePictureIsSet = "profilePictureIsSet"
    static let profilePicture = "profilePicture"
    static let beenToSettingsOnce = "beenToSettingsOnce"
    static let segueBeenToSettingsOnce = "showSettingsFirstConnexion"
    
    // Webview offset
    static let Monday_iPhone4 = 0
    static let Tuesday_iPhone4 = 160
    static let Wednesday_iPhone4 = 350
    static let Thursday_iPhone4 = 530
    static let Friday_iPhone4 = 700
    static let Weekend_iPhone4 = 0
    
    static let Monday_iPhone5 = 0
    static let Tuesday_iPhone5 = 165
    static let Wednesday_iPhone5 = 350
    static let Thursday_iPhone5 = 530
    static let Friday_iPhone5 = 700
    static let Weekend_iPhone5 = 0
    
    static let Monday_iPhone6 = 0
    static let Tuesday_iPhone6 = 190
    static let Wednesday_iPhone6 = 410
    static let Thursday_iPhone6 = 625
    static let Friday_iPhone6 = 850
    static let Weekend_iPhone6 = 0
    
    static let Monday_iPhone6Plus = 0
    static let Tuesday_iPhone6Plus = 210
    static let Wednesday_iPhone6Plus = 445
    static let Thursday_iPhone6Plus = 685
    static let Friday_iPhone6Plus = 860
    static let Weekend_iPhone6Plus = 0
    
    static let urlProxyWash = "http://www.proxiwash.com/weblaverie/ma-laverie-2?s=cf4f39&16d33a57b3fb9a05d4da88969c71de74=1"
    static let urlWeatherToulouse = "https://api.forecast.io/forecast/5877c3394948db03ae04471da46fde3c/43.5722715,1.4687831"
    static let urlWashINSAAPI = "http://92.222.86.168/washinsa/json"
    
    // Planning Express
    static let idPlanningExpress = "idPlanningExpress"
    static let yearSpeGroupPlanningExpress = "yearSpeGroupPlanningExpress"
    static let rowPickerViewSettings = "rowPickerViewSettings"
    
    // Weather
    static let temperatureNSUserDefaults = "temperatureWeather"
    
    // Push Notifications
    static let isRegisterForPushNotifications = "isRegisterForPushNotifications"
    static let userWantsToBeRegistreredForPushNotifications = "userWantsToBeRegistreredForPushNotifications"
    static let userDeclinedToBeRegisteredForPushNotifications = "userDeclinedToBeRegisteredForPushNotifications"
    static let userAnsweredForPushNotifications = "userAnsweredForPushNotifications"
    
    static let titleAlertPushNotification = "Push Notifications"
    static let subtitleAlertPushNotification = "Accepte les notifications pour bénéficier des dernières infos du campus en temps réel !"
    //
    
}

/*
 removeNSUserDefault
 */

public func removeNSUserDefault(){
    for key in NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys {
        print(key)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
    }
    NSUserDefaults.standardUserDefaults().synchronize()
}

/*
 Function called when app launched
 */

public func initApp() {
    if (NSUserDefaults.standardUserDefaults().boolForKey(Public.usernameChatRegistred) ==  false) {
        let usernameChat = "invite\(Int(arc4random_uniform(UInt32(2500))))"
        NSUserDefaults.standardUserDefaults().setObject(usernameChat, forKey: Public.usernameChat)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.usernameChatRegistred)
    }
    setTemperature()
}

/*
 Settings
 */

public func setBeenToSettingsOnce(){
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.beenToSettingsOnce)
}

public func getBeenToSettingsOnce() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.beenToSettingsOnce)
}

/*
 username getter/setter
 */

public func setUsernameChat(username: String) {
    NSUserDefaults.standardUserDefaults().setObject(username, forKey: Public.usernameChat)
}

public func getUsernameChat() -> String {
    if let username = NSUserDefaults.standardUserDefaults().stringForKey(Public.usernameChat) {
        return username
    } else {
        return "invite\(Int(arc4random_uniform(UInt32(2500))))"
    }
}

/*
    Planning Express
 */

private func _returnDefaultIDPlanningExpress() -> String {
    return "394"
}

private func _returnDefaultYearSpeGroupPlanningExpress() -> String {
    return "1A - A"
}

public func getIDPlanningExpress() -> String {
    if let idPlanningExpress = NSUserDefaults.standardUserDefaults().stringForKey(Public.idPlanningExpress) {
        return idPlanningExpress
    } else {
        return _returnDefaultIDPlanningExpress()
    }
}

public func setIDPlanningExpress(id: String) {
    NSUserDefaults.standardUserDefaults().setObject(id, forKey: Public.idPlanningExpress)
}

public func getYearSpeGroupPlanningExpress() -> String {
    if let yearSpeGroup = NSUserDefaults.standardUserDefaults().stringForKey(Public.yearSpeGroupPlanningExpress) {
        return yearSpeGroup
    } else {
        return _returnDefaultYearSpeGroupPlanningExpress()
    }
}

public func setYearSpeGroupPlanningExpress(yearSpeGroup:String){
    NSUserDefaults.standardUserDefaults().setObject(yearSpeGroup, forKey: Public.yearSpeGroupPlanningExpress)
}

/*
    profile picture getter/setter
 */

public func setProfilPicture(image : UIImage){
    NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(image), forKey: Public.profilePicture)
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.profilePictureIsSet)
    NSUserDefaults.standardUserDefaults().synchronize()
}

public func getProfilPicture() -> UIImage {
    let isProfilePictureIsSet = NSUserDefaults.standardUserDefaults().boolForKey(Public.profilePictureIsSet)
    if isProfilePictureIsSet{
        if let  imageData = NSUserDefaults.standardUserDefaults().objectForKey(Public.profilePicture) as? NSData {
            let profilePicture = UIImage(data: imageData)
            return profilePicture!
        } else{
            return  UIImage(named: "defaultPic")! }
    } else {
        return UIImage(named: "defaultPic")!
    }
}

/*
    Weather
 */

public func getTemperature() -> String {
    if let temperature = NSUserDefaults.standardUserDefaults().stringForKey(Public.temperatureNSUserDefaults) {
        return "\(temperature) °C"
    } else {
        return ""
    }
}

private func setTemperature(){
    let url = Public.urlWeatherToulouse
    let urlNSUrl = NSURL(string: url)
    let qos = Int(QOS_CLASS_USER_INITIATED.rawValue) // qos = quality of service (if it's slow, important...)
    dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
        if  let data = NSData(contentsOfURL: urlNSUrl!) {
            dispatch_async(dispatch_get_main_queue(), {
                let json = JSON(data: data)
                if let temperature = json["currently"]["temperature"].float{
                    let temperatureCelsius = (temperature-32)/1.8
                    let temperatureCelsiusString = String(format: "%.1f", temperatureCelsius)
                    // println("Temperature actuelle =  \(temperatureCelsiusString)")
                    NSUserDefaults.standardUserDefaults().setObject(temperatureCelsiusString, forKey: Public.temperatureNSUserDefaults)
                }
                NSUserDefaults.standardUserDefaults().synchronize()
                }
            )
        }
    }
}

/*
 Push Notifications
 Si l'utilisateur n'a jamais rien dit, il faut lui demander si il veut accepter les push notifications
 Si l'utilisateur a dékà accepté, on dit rien
 Si l'utilisateur a dit non, on dit rien
 */

private func getUserAnsweredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userAnsweredForPushNotifications)
}

private func setUserAnsweredForPushNotifications() {
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.userAnsweredForPushNotifications)
}

private func getUserWantsToBeRegistreredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userWantsToBeRegistreredForPushNotifications)
}

private func getUserDeclinedToBeRegisteredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userDeclinedToBeRegisteredForPushNotifications)
}

public func setUserDeclinedToBeRegisteredForPushNotifications() {
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.userDeclinedToBeRegisteredForPushNotifications)
}

private func getUserAlreadyRegisteredForPushNotifications() -> Bool {
    let notificationType = UIApplication.sharedApplication().currentUserNotificationSettings()!.types
    if notificationType == UIUserNotificationType.None {
        return false
    }else{
        return true
    }
}

/*
 TODO: set userDeclined... to true if user declines to be registered for Push Notification
 */
private func getShowAlertForPermissionPushNotifications() -> Bool {
    let userDeclinedToBeRegisteredForPushNotifications = getUserDeclinedToBeRegisteredForPushNotifications()
    let userAlreadyRegisteredForPushNotifications = getUserAlreadyRegisteredForPushNotifications()
    let userAnsweredForPushNotifications = getUserAnsweredForPushNotifications()
    
    if userDeclinedToBeRegisteredForPushNotifications {
        print("userDeclinedToBeRegisteredForPushNotifications")
        return false
    } else if userAlreadyRegisteredForPushNotifications {
        print("userAlreadyRegisteredForPushNotifications")
        return false
    } else if userAnsweredForPushNotifications {
        return false
    } else {
        print("ELSE getShowAlertForPermissionPushNotifications")
        return true
    }
}


public func registerForNotificationsAndEnterApp(controller: UIViewController) {
    let showAlert = getShowAlertForPermissionPushNotifications()
    if showAlert {
        let alert = SCLAlertView()
        alert.addButton("Compris !") {
            setUserAnsweredForPushNotifications()
            let application = UIApplication.sharedApplication()
            print("J'affiche l'alert qui va demander de recevoir des notifications")
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
//        alert.addButton("TEST") {
//            print("Ceci est un bouton de test")
//        }
        alert.showCloseButton = false
        alert.showInfo(Public.titleAlertPushNotification, subTitle: Public.subtitleAlertPushNotification)
    }
}

public func sendLocalNotificationWashingMachine(time: Int, numeroMachine: Int) {
    let notification = UILocalNotification()
    notification.fireDate = NSDate(timeIntervalSinceNow: Double(time*60))
    notification.alertBody = "Vite, ton linge est prêt !!"
    notification.alertAction = "récupérer ton linge !"
    notification.userInfo = ["numero_machine": numeroMachine]
    notification.soundName = UILocalNotificationDefaultSoundName
    UIApplication.sharedApplication().scheduleLocalNotification(notification)
}
