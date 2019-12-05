//
//  KanjiStrokeOrderController.swift
//  Japanese
//
//  Created by Alexander Greene on 11/23/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SwiftUI
import SnapKit
import AVKit

class KanjiImageCell: UICollectionViewCell {
	static let identifier = "KanjiImageCell"

	var kanjiImage: KanjiImage? {
		didSet {
			guard let kanjiImage = kanjiImage else { return }
			imageView.image = kanjiImage.image.withTintColor(UIColor(named: "foreground") ?? .white, renderingMode: .alwaysTemplate)
		}
	}

	let imageView: UIImageView = {
		let view = UIImageView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.tintColor = UIColor(named: "foreground")
		return view
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		contentView.addSubview(imageView)
		imageView.snp.makeConstraints {
			$0.top.right.left.bottom.equalTo(contentView)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


struct KanjiStrokeOrderView: UIViewControllerRepresentable {
	@EnvironmentObject var kanjiDetailStore: KanjiDetailStore

	func makeUIViewController(context: UIViewControllerRepresentableContext<KanjiStrokeOrderView>) -> KanjiStrokeOrderController {
		let controller = KanjiStrokeOrderController()
		controller.kanjiDetailStore = kanjiDetailStore
		return controller
	}

	func updateUIViewController(_ uiViewController: KanjiStrokeOrderController, context: UIViewControllerRepresentableContext<KanjiStrokeOrderView>) {

	}
}

class KanjiStrokeOrderController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AVPlayerViewControllerDelegate {

	lazy var collectionView: UICollectionView = {
		let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
		cv.translatesAutoresizingMaskIntoConstraints = false
		cv.delegate = self
		cv.dataSource = self
		cv.backgroundColor = UIColor(named: "background")
		cv.register(KanjiImageCell.self, forCellWithReuseIdentifier: KanjiImageCell.identifier)
		return cv
	}()

	weak var kanjiDetailStore: KanjiDetailStore?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(collectionView)

		collectionView.snp.makeConstraints {
			$0.top.right.left.bottom.equalTo(view)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: .refreshStrokeOrderImages, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handlePresentVideoPlayerController(_:)), name: .presentVideoPlayerController, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func handlePresentVideoPlayerController(_ notification: Notification) {
		guard
			let string = notification.object as? String,
			let url = URL(string: string)
		else { return }

		let videoPlayer = AVPlayer(url: url)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = videoPlayer
		videoPlayer.play()
		playerViewController.delegate = self
		present(playerViewController, animated: true, completion: nil)
	}

	func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		NotificationCenter.default.post(name: .dismissVideoPlayerController, object: nil)
	}

	@objc func handleRefresh() {
		collectionView.reloadData()
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		print(kanjiDetailStore?.images?.count ?? 0)
		return kanjiDetailStore?.images?.count ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KanjiImageCell.identifier, for: indexPath) as? KanjiImageCell
		else { return UICollectionViewCell() }

		cell.kanjiImage = kanjiDetailStore?.images?[indexPath.item]

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 40, height: 40)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 4
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 4
	}
}
