//
//  PostWithImageTableViewCell.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 03/04/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import NYTPhotoViewer

class PostWithImageTableViewCell: UITableViewCell, NYTPhotosViewControllerDelegate {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var titlePostLabel: UILabel!
    @IBOutlet weak var textPostLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(PostWithImageTableViewCell.imageTapped(_:)))
//        postImageView.userInteractionEnabled = true
//        postImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    func imageTapped(img: AnyObject)
//    {
//        print("image clicked")
////        if let image = img as? UIImageView {
//////            let photo = Photo(photo: image.image!)
//////            let viewer = NYTPhotosViewController(photos: [photo])
//////            presentViewController(viewer, animated: true, completion: nil)
////        }
//    }

}
