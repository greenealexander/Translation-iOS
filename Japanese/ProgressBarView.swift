//
//  ProgressBarView.swift
//  Japanese
//
//  Created by Alexander Greene on 12/6/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class ProgressBarView: UIView {

	var progress: UInt = 0 {
		didSet {
			print(progress)
			progressLabel.text = "\(progress)%"
			progressBarWidthConstraint?.update(offset: 250 * (CGFloat(progress) / 100))
		}
	}

	private let progressLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.textColor = UIColor(named: "accent")
		return label
	}()

	private let barBackground: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 10
		view.backgroundColor = UIColor(named: "accent")?.withAlphaComponent(0.5)
		return view
	}()

	private let progressBar: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 10
		view.backgroundColor = UIColor(named: "accent")
		return view
	}()

	private var progressBarWidthConstraint: Constraint?

	override init(frame: CGRect) {
		super.init(frame: frame)

		[progressLabel, barBackground, progressBar].forEach { addSubview($0) }

		progressLabel.snp.makeConstraints {
			$0.top.equalTo(self).offset(16)
			$0.centerX.equalTo(self)
		}

		barBackground.snp.makeConstraints {
			$0.centerX.equalTo(self)
			$0.top.equalTo(progressLabel).offset(32)
			$0.height.equalTo(20)
			$0.width.equalTo(250)
			$0.bottom.equalTo(self).offset(-16)
		}

		progressBar.snp.makeConstraints {
			$0.centerY.equalTo(barBackground)
			$0.left.equalTo(barBackground)
			$0.height.equalTo(20)
			progressBarWidthConstraint = $0.width.equalTo(0).constraint
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
