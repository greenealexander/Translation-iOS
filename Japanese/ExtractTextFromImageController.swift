//
//  ExtractTextFromImageController.swift
//  Japanese
//
//  Created by Alexander Greene on 11/24/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SwiftUI
import TesseractOCR
import VisionKit

class ImageReceiver: NSObject, VNDocumentCameraViewControllerDelegate, G8TesseractDelegate {
	func processImage(image: UIImage) -> String? {
		guard let tesseract = G8Tesseract(language: "jpn+eng") else {
			print("failed to create tesseract instance")
			return nil
		}

		tesseract.delegate = self
		tesseract.image = image.scaledImage(1000)?.preprocessedImage() ?? image
		tesseract.recognize()

		return tesseract.recognizedText
	}

	func progressImageRecognition(for tesseract: G8Tesseract) {
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .imageProcessedPercentage, object: tesseract.progress)
		}
	}

	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
		controller.dismiss(animated: true) {
			DispatchQueue.global(qos: .userInitiated).async {
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: .imageProcessStarted, object: nil)
				}

				var strings = [String]()
				for pageNumber in 0 ..< scan.pageCount {
					let image = scan.imageOfPage(at: pageNumber)
					strings.append(self.processImage(image: image) ?? "")
				}
				let string = strings.joined(separator: "\n\n")

				DispatchQueue.main.async {
					NotificationCenter.default.post(name: .extractedTextFromImage, object: string)
				}
			}
		}
	}
}

struct ExtractTextFromImageView: UIViewControllerRepresentable {
	@EnvironmentObject var interprettedTextStore: InterpretTextStore
	let imageReceiver = ImageReceiver()

	func makeUIViewController(context: UIViewControllerRepresentableContext<ExtractTextFromImageView>) -> VNDocumentCameraViewController {
		let controller = VNDocumentCameraViewController()
		controller.delegate = imageReceiver
		return controller
	}

	func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<ExtractTextFromImageView>) {

	}
}
