//
//  KanjiStrokeSVGView.swift
//  Japanese
//
//  Created by Alexander Greene on 12/4/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI
import PocketSVG
import SnapKit
import SVGKit

struct KanjiStrokeSVGView: View {
    var body: some View {
			VStack {
				KanjiStrokeAnimationView()
					.background(Color.red)
			}
    }
}

class KanjiStrokeAnimationController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white

		guard
			let path = Bundle.main.path(forResource: "kanji", ofType: "svg"),
			let url = URL(string: path)
		else { return }

		let svgImage = SVGImageView(contentsOf: url)
		svgImage.contentMode = .scaleAspectFit
    svgImage.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(svgImage)

		svgImage.snp.makeConstraints {
			$0.right.left.bottom.top.equalTo(view)
		}

		let layers = svgImage.paths.map { path -> CAShapeLayer in
			let shapeLayer = CAShapeLayer()
			shapeLayer.path = path.cgPath
			return shapeLayer
		}

		layers.forEach { view.layer.addSublayer($0) }

		layers.forEach { animateSVG(layer: $0, start: 0, end: 1) }
	}

	func animateSVG(layer: CAShapeLayer, start: CGFloat, end: CGFloat, duration: CFTimeInterval = 4.0) {
		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.duration = duration
		animation.fromValue = start
		animation.toValue = end
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		layer.strokeEnd = end
		layer.strokeStart = start
		layer.add(animation, forKey: "animateStroke")
	}
}

struct KanjiStrokeAnimationView: UIViewControllerRepresentable {

	func makeUIViewController(context: UIViewControllerRepresentableContext<KanjiStrokeAnimationView>) -> KanjiStrokeAnimationController {
		return KanjiStrokeAnimationController()
	}

	func updateUIViewController(_ uiViewController: KanjiStrokeAnimationController, context: UIViewControllerRepresentableContext<KanjiStrokeAnimationView>) {

	}
}
