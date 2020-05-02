//
//  KanjiDetailViewController.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class KanjiDetailViewController: UIViewController {
	let viewModel = KanjiDetailViewModel()
	let header = KanjiInfoHeaderView()

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = UIColor(named: "background")

		let _ = viewModel.$kanjiInfo
			.receive(on: DispatchQueue.main)
			.assign(to: \.kanjiInfo, on: header)

		view.addSubview(header)

		header.snp.makeConstraints {
			$0.top.right.left.equalTo(view)
		}
	}
}
