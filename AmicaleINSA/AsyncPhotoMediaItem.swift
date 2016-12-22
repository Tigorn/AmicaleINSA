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
    
    init(withURL url: URL) {
        super.init()
        
        asyncImageView = UIImageView()
        asyncImageView.frame = CGRect(x: 0, y: 0, width: 170, height: 130)
        asyncImageView.contentMode = .scaleAspectFill
        asyncImageView.clipsToBounds = true
        asyncImageView.layer.cornerRadius = 20
        asyncImageView.backgroundColor = UIColor.jsq_messageBubbleLightGray()
        
        let activityIndicator = JSQMessagesMediaPlaceholderView.withActivityIndicator()
        activityIndicator?.frame = asyncImageView.frame
        asyncImageView.addSubview(activityIndicator!)
        
        KingfisherManager.shared.cache.retrieveImage(forKey: url.absoluteString, options: nil) { (image, cacheType) in
            if let image = image {
                self.asyncImageView.image = image
                activityIndicator?.removeFromSuperview()
            } else {
                KingfisherManager.shared.downloader.downloadImage(with: url, options: nil, progressBlock: nil, completionHandler: { (image, error, imageURL, originalData) in
                    if let image = image {
                        self.asyncImageView.image = image
                        activityIndicator?.removeFromSuperview()
                        KingfisherManager.shared.cache.store(image, forKey: url.absoluteString)
                        /* KingfisherManager.shared.cache.store(image, original: nil, forKey: url.absoluteString, processorIdentifier: url.absoluteString, cacheSerializer: CacheSerializer, toDisk: true, completionHandler: {
                            nil
                        }) */
                        // KingfisherManager.sharedManager.cache.storeImage(image, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
                    }
                })
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
