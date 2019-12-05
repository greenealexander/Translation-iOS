//
//  UIImage+Ext.swift
//  Japanese
//
//  Created by Alexander Greene on 11/28/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import GPUImage

extension UIImage {
  // 2
  func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
    // 3
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)
    // 4
    if size.width > size.height {
      scaledSize.height = size.height / size.width * scaledSize.width
    } else {
      scaledSize.width = size.width / size.height * scaledSize.height
    }
    // 5
    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    // 6
    return scaledImage
  }

	func preprocessedImage() -> UIImage? {
		// 1
		let stillImageFilter = GPUImageAdaptiveThresholdFilter()
		// 2
		stillImageFilter.blurRadiusInPixels = 15.0
		// 3
		let filteredImage = stillImageFilter.image(byFilteringImage: self)
		// 4
		return filteredImage
	}
}
