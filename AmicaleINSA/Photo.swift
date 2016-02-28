//
//  Photo.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Foundation
import NYTPhotoViewer

class Photo: NSObject, NYTPhoto {
    
    private let photo: UIImage
    
    init(photo: UIImage) {
        self.photo = photo
    }
    
    var image: UIImage? { return photo }
    
    var imageData: NSData? { return nil }
    
    var placeholderImage: UIImage? { return nil }
    
    var attributedCaptionTitle: NSAttributedString? { return nil }
    
    var attributedCaptionSummary: NSAttributedString? { return nil }
    
    var attributedCaptionCredit: NSAttributedString? { return nil }
}