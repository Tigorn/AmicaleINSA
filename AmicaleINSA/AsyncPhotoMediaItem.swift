//
//  AsyncPhotoMediaItem.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 04/09/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Kingfisher
import JSQMessagesViewController

class AsyncPhotoMediaItem: JSQPhotoMediaItem {
    var asyncImageView: UIImageView!
    
    override init!(maskAsOutgoing: Bool) {
        super.init(maskAsOutgoing: maskAsOutgoing)
    }
    
    init(withURL url: NSURL) {
        super.init()
        
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRectMake(0, 0, 170, 130)
        asyncImageView.contentMode = .ScaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 20
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGrayColor()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.viewWithActivityIndicator()
        activityIndicator.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator)
        
        KingfisherManager.sharedManager.cache.retrieveImageForKey(url.absoluteString, options: nil) { (image, cacheType) -> () in
            
            if let image = image {
                self.asyncImageView.image = image
                activityIndicator.removeFromSuperview()
            } else {
                KingfisherManager.sharedManager.downloader.downloadImageWithURL(url, progressBlock: nil) { (image, error, imageURL, originalData) -> () in
                    
                    if let image = image {
                        self.asyncImageView.image = image
                        activityIndicator.removeFromSuperview()
                        
                        KingfisherManager.sharedManager.cache.storeImage(image, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
                    }
                }
            }
        }
    }
    
    override func mediaView() -> UIView! {
        return asyncImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return asyncImageView.frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}