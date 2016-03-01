//
//  Public.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Foundation
import UIKit

public struct Storyboard {
    
    // Chat
    static let usernameChat = "usernameChat"
    static let usernameChatRegistred = "usernameChatRegistred"
    
    // Settings
    static let profilePictureIsSet = "profilePictureIsSet"
    static let profilePicture = "profilePicture"
    
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
    
}

/*
    Function called when app launched
*/

public func initApp() {
    if (NSUserDefaults.standardUserDefaults().boolForKey(Storyboard.usernameChatRegistred) ==  false) {
        let usernameChat = "invite\(Int(arc4random_uniform(UInt32(2500))))"
        NSUserDefaults.standardUserDefaults().setObject(usernameChat, forKey: Storyboard.usernameChat)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Storyboard.usernameChatRegistred)
    }
}

/*
    username getter/setter
*/

public func setUsernameChat(username: String) {
    NSUserDefaults.standardUserDefaults().setObject(username, forKey: Storyboard.usernameChat)
}

public func getUsernameChat() -> String {
    return NSUserDefaults.standardUserDefaults().stringForKey(Storyboard.usernameChat)!
}


/*
    profile picture getter/setter
*/

public func setProfilPicture(image : UIImage){
    NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(image), forKey: Storyboard.profilePicture)
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Storyboard.profilePictureIsSet)
    NSUserDefaults.standardUserDefaults().synchronize()
}

public func getProfilPicture() -> UIImage {
    let isProfilePictureIsSet = NSUserDefaults.standardUserDefaults().boolForKey(Storyboard.profilePictureIsSet)
    if isProfilePictureIsSet{
        if let  imageData = NSUserDefaults.standardUserDefaults().objectForKey(Storyboard.profilePicture) as? NSData {
            let profilePicture = UIImage(data: imageData)
            return profilePicture!
        } else{
            return  UIImage(named: "defaultPic")! }
    } else {
        return UIImage(named: "defaultPic")!
    }
}

extension UIImage {
    
    var uncompressedPNGData: NSData      { return UIImagePNGRepresentation(self)!        }
    var highestQualityJPEGNSData: NSData { return UIImageJPEGRepresentation(self, 1.0)!  }
    var highQualityJPEGNSData: NSData    { return UIImageJPEGRepresentation(self, 0.75)! }
    var mediumQualityJPEGNSData: NSData  { return UIImageJPEGRepresentation(self, 0.5)!  }
    var lowQualityJPEGNSData: NSData     { return UIImageJPEGRepresentation(self, 0.25)! }
    var lowestQualityJPEGNSData:NSData   { return UIImageJPEGRepresentation(self, 0.0)!  }
    
    
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}