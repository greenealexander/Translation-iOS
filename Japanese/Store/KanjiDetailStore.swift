//
//  KanjiDetailStore.swift
//  Japanese
//
//  Created by Alexander Greene on 11/28/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import AVKit

class KanjiDetailStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
	var isShowingVideo = false
	@Published var kanji: String? {
		didSet {
			guard let kanji = kanji else {
				images = nil
				isLoadingInfo = false
				isLoadingImages = false
				return
			}
			getKanjiInfo(kanji: kanji)
		}
	}
	@Published var kanjiInfo: KanjiInfo?
	@Published var isLoadingInfo = false
	@Published var isLoadingImages = false
	@Published var images: [KanjiImage]? {
		didSet {
			NotificationCenter.default.post(name: .refreshStrokeOrderImages, object: nil)
		}
	}
	@Published var isPlaying = false
	@Published var selectedExample: KanjiExample? {
		didSet {
			guard
				let example = selectedExample,
				let url = URL(string: example.mp3Url)
			else { return }

			if let oldValue = oldValue {
				if oldValue == example {
					if examplePlayer?.isPlaying ?? false {
						examplePlayer?.stop()
						examplePlayer = nil
						selectedExample = nil
					}
					return
				}
			}

			downloadMP3Task?.cancel()
			examplePlayer?.stop()
			isPlaying = false
			downloadMP3Task = nil
			examplePlayer = nil

			let path = Constants.appTmpDirectory + "\(example.meaning.removeWhiteSpace()).mp3"

			if FileManager.default.fileExists(atPath: path) {
				guard	let fileUrl = URL(string: path) else { return }

				do {
					self.examplePlayer = try AVAudioPlayer(contentsOf: fileUrl, fileTypeHint: "mp3")
					self.examplePlayer?.delegate = self
					self.examplePlayer?.play()
					self.isPlaying = true
				} catch let error {
					print(error)
				}

				return
			}

			downloadMP3Task = URLSession.shared.dataTask(with: url) { (data, res, err) in
				if let err = err {
					print(err)
					return
				}

				guard let data = data else { return }

				if !FileManager.default.fileExists(atPath: Constants.appTmpDirectory) {
					do {
						try FileManager.default.createDirectory(atPath: Constants.appTmpDirectory, withIntermediateDirectories: true, attributes: nil)
					} catch let error {
						print(error)
					}
				}

				let didCreateFile = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)

				guard
					didCreateFile,
					let fileUrl = URL(string: path)
				else { return }

				do {
					self.examplePlayer = try AVAudioPlayer(contentsOf: fileUrl, fileTypeHint: "mp3")
					self.examplePlayer?.delegate = self
					self.examplePlayer?.play()
					DispatchQueue.main.async {
						self.isPlaying = true
					}
				} catch let error {
					print(error)
				}
			}

			downloadMP3Task?.resume()
		}
	}

	var downloadMP3Task: URLSessionDataTask?
	var examplePlayer: AVAudioPlayer?

	override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(handleKanjiSelected(_:)), name: .kanjiSelected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleKanjiInfoScreenDismissed), name: .kanjiInfoScreenDismissed, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handlePresentVideoPlayer), name: .presentVideoPlayerController, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleDismissVideoPlayer), name: .dismissVideoPlayerController, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func handleDismissVideoPlayer() {
		isShowingVideo = false
	}

	@objc func handlePresentVideoPlayer() {
		isShowingVideo = true
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		isPlaying = false
		selectedExample = nil
	}

	@objc func handleKanjiInfoScreenDismissed() {
		guard !isShowingVideo else { return }

		clear()
	}

	func clear() {
		kanji = nil
		kanjiInfo = nil
		downloadMP3Task?.cancel()
		examplePlayer?.stop()
		examplePlayer = nil
		downloadMP3Task = nil
		selectedExample = nil
	}

	@objc func handleKanjiSelected(_ notification: Notification) {
		print(notification.object ?? "no kanji is present")
		guard let kanji = notification.object as? String else {
			self.kanji = nil
			return
		}
		self.kanji = kanji
	}

	func getKanjiInfo(kanji: String) {
		if isLoadingImages || isLoadingInfo { return }

		isLoadingInfo = true

		KanjiAliveAPI.shared.getInfoFor(
			kanji: kanji,
			kanjiInfoReceived(_:),
			kanjiImagesReceived(_:)
		)
	}

	private func kanjiInfoReceived(_ kanjiInfo: KanjiInfo?) {
		self.isLoadingInfo = false

		guard let kanjiInfo = kanjiInfo else {
			self.isLoadingImages = false
			return
		}

		self.kanjiInfo = kanjiInfo
		isLoadingImages = true
	}

	private func kanjiImagesReceived(_ kanjiImages: [KanjiImage]?) {
		isLoadingImages = false

		self.images = kanjiImages
	}
}
