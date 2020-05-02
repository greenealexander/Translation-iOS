//
//  KanjiAliveAPI.swift
//  Japanese
//
//  Created by Alexander Greene on 11/21/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SVGKit

class KanjiAliveAPI {
	static let shared = KanjiAliveAPI()
	private let endpointUrl = "https://kanjialive-api.p.rapidapi.com/api/public/kanji"
	private let headers = [
		"x-rapidapi-host": "kanjialive-api.p.rapidapi.com",
		"x-rapidapi-key": "f93b60fa34msh3962ccf5b9e6dafp1e6278jsn646194874cd6"
	]
	private var checkedKanjis = [String:KanjiInfo]()

	private init() {}

	private func executeRequest(kanji: String, url: URL, _ completed: ((KanjiInfo?)->())? = nil) {
		var req = URLRequest(url: url)
		headers.forEach {
			let (key, value) = $0
			req.addValue(value, forHTTPHeaderField: key)
		}
		req.httpMethod = "GET"

		URLSession.shared.dataTask(with: req) { (data, res, err) in
			if let err = err {
				print(err)
				return
			}

			guard let data = data else { return }

			do {
				let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

				guard
					let dict = json as? [String:Any],
					let kanjiDict = dict["kanji"] as? [String:Any],
					let videoDict = kanjiDict["video"] as? [String:Any],
					let videoUrl = videoDict["mp4"] as? String,
					let meaningDict = kanjiDict["meaning"] as? [String:String],
					let meaning = meaningDict["english"],
					let kunyomiDict = kanjiDict["kunyomi"] as? [String:String],
					let kunyomi = kunyomiDict["hiragana"],
					let strokesDict = kanjiDict["strokes"] as? [String:Any],
					let strokes = strokesDict["count"] as? Int,
					let strokeImages = strokesDict["images"] as? [String],
					let examplesArray = dict["examples"] as? [[String:Any]]
				else { return }

				let examples = examplesArray.compactMap { example -> KanjiExample? in
					guard
						let audioDict = example["audio"] as? [String:Any],
						var japanese = example["japanese"] as? String,
						let meaningDict = example["meaning"] as? [String:Any],
						let mp3Url = audioDict["mp3"] as? String,
						let meaning = meaningDict["english"] as? String
					else { return nil }

					if japanese.first == "*" {
						japanese = japanese.dropFirst().description
					}
					return KanjiExample(mp3Url: mp3Url, text: japanese, meaning: meaning)
				}

				let info = KanjiInfo(
					kanji: kanji,
					numStrokes: strokes,
					meaning: meaning,
					kunyomi: kunyomi,
					imagePaths: strokeImages,
					examples: examples,
					videoUrl: videoUrl
				)

				DispatchQueue.main.async {
					completed?(info)
				}
			} catch let error {
				print(error)
				DispatchQueue.main.async {
					completed?(nil)
				}
			}
		}.resume()
	}

	func getImages(strokeImages: [String], _ completed: (([KanjiImage]?)->())? = nil) {
		let imagePaths = strokeImages.compactMap { imageUrl -> String? in
			guard let path = URL(string: Constants.appTmpDirectory + imageUrl.split(separator: "/").last!)
			else { return nil }
			return path.absoluteString
		}

		let downloaded = imagePaths.allSatisfy { FileManager.default.fileExists(atPath: $0) }

		print("are the images downloaded: \(downloaded)")

		if downloaded {

			let kanjiImages = imagePaths.compactMap { path -> KanjiImage? in
				guard
					let imageData = FileManager.default.contents(atPath: path),
					let image = UIImage(data: imageData)
				else { return nil }

				return KanjiImage(path: path, image: image)
			}

			completed?(kanjiImages)
			return
		}

		downloadImages(paths: strokeImages, filePaths: imagePaths) { (kanjiImages) in
			completed?(kanjiImages)
		}
	}

	private func downloadImages(paths: [String], filePaths: [String], _ completed: (([KanjiImage]?)->())? = nil) {
		let downloadImageTaskGroup = DispatchGroup()

		paths.forEach { imageUrl in
			if let url = URL(string: imageUrl) {
				downloadImageTaskGroup.enter()

				URLSession.shared.dataTask(with: url) { (data: Data?, res: URLResponse?, err: Error?) in
					do {
						if let err = err {
							throw err
						}

						guard
							let data = data,
							let image = SVGKImage(data: data).uiImage,
							let imageSaveData = image.pngData(),
							let path = URL(string: Constants.appTmpDirectory + imageUrl.split(separator: "/").last!)
						else {
							downloadImageTaskGroup.leave()
							return
						}

						if !FileManager.default.fileExists(atPath: Constants.appTmpDirectory) {
							do {
								try FileManager.default.createDirectory(atPath: Constants.appTmpDirectory, withIntermediateDirectories: true, attributes: nil)
							} catch let error {
								print(error)
							}
						}

						FileManager.default.createFile(atPath: path.absoluteString, contents: imageSaveData, attributes: nil)

					} catch let error {
						print(error)
					}

					downloadImageTaskGroup.leave()
				}.resume()
			}
		}

		downloadImageTaskGroup.notify(queue: .main) {
//			info.imagePaths = imagePaths.sorted()

			var images = filePaths.compactMap({ path -> KanjiImage? in
				if FileManager.default.fileExists(atPath: path) {
					guard
						let imageData = FileManager.default.contents(atPath: path),
						let uiImage = UIImage(data: imageData)
					else { return nil }

					return KanjiImage(path: path, image: uiImage)
				}

				return nil
			})
			images.sort { (lhs, rhs) -> Bool in
				let orders = [lhs, rhs].map { ki -> Int in
					var s = ki.path.split(separator: "_")[1].description
					s.removeLast(4)
					return Int(s)!
				}
				return orders[0] < orders[1]
			}

			completed?(images)
		}
	}

	func getInfoFor(kanji: String, _ kanjiInfoReceived: ((KanjiInfo?)->())? = nil, _ kanjiImagesReceived: (([KanjiImage]?)->())? = nil) {
		guard
			let escapedKanji = kanji.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			let url = URL(string: "\(endpointUrl)/\(escapedKanji)")
		else {
			return
		}

		if let kanjiInfo = checkedKanjis[kanji] {
			kanjiInfoReceived?(kanjiInfo)
			getImages(strokeImages: kanjiInfo.imagePaths, kanjiImagesReceived)
			return
		}

		executeRequest(kanji: kanji, url: url) { [weak self] (kanjiInfo) in
			kanjiInfoReceived?(kanjiInfo)

			guard let kanjiInfo = kanjiInfo else { return }
			
			self?.checkedKanjis[kanji] = kanjiInfo 

			self?.getImages(strokeImages: kanjiInfo.imagePaths, kanjiImagesReceived)
		}
	}
}
