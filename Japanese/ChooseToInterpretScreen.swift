//
//  ChooseToInterpretScreen.swift
//  Japanese
//
//  Created by Alexander Greene on 11/18/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI

typealias TokenTuple = (Character, Token, Bool)

extension Notification.Name {
	static let kanjiSelected = Notification.Name("kanjiSelected")
	static let kanjiInfoScreenDismissed = Notification.Name("kanjiInfoScreenDismissed")
	static let refreshStrokeOrderImages = Notification.Name("refreshStrokeOrderImages")
	static let presentVideoPlayerController = Notification.Name("presentVideoPlayerController")
	static let dismissVideoPlayerController = Notification.Name("dismissVideoPlayerController")
	static let extractedTextFromImage = Notification.Name("extractedTextFromImage")
	static let imageProcessedPercentage = Notification.Name("imageProcessedPercentage")
	static let imageProcessStarted = Notification.Name("imageProcessStarted")
	static let pairsFinishedProcessing = Notification.Name("pairsFinishedProcessing")
}

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
