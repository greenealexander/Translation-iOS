//
//  GoogleTranslateAPI.swift
//  Japanese
//
//  Created by Alexander Greene on 12/6/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

class GoogleTranslateAPI {
	static let shared = GoogleTranslateAPI()
	private let apiKey = "AIzaSyDp03g1VlxPOW4-nWrNMU-waIaMcTQIi_I"
	private let endpointUrl = "https://translation.googleapis.com/language/translate/v2"
	private var lookedUpWords = [String:String]()

	private init() {}

	func translateText(text: String, _ completed: ((String?)->())? = nil) -> URLSessionDataTask? {
		if let translatedText = lookedUpWords[text] {
			completed?(translatedText)
			return nil
		}

		guard let url = URL(string: "\(endpointUrl)?key=\(apiKey)") else { return nil }

		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.addValue("application/json", forHTTPHeaderField: "Content-Type")
		let body: [String:String] = ["q":text, "source":"ja", "target":"en", "format": "text"]
		var data = body.keys.reduce("") {
			return "\($0)\("\"\($1)\":\"\(body[$1]!)\",")"
		}
		let _ = data.popLast()
		let dataString = "{\(data)}".utf8
		req.httpBody = Data(dataString)

		let task = URLSession.shared.dataTask(with: req) { [weak self] (data, res, err) in
			if let err = err {
				print(err)
				return
			}

			guard let data = data else { return }

			do {
				let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

				guard
					let dict = json as? [String:Any],
					let data = dict["data"] as? [String:Any],
					let translations = data["translations"] as? [[String:String]],
					let translatedText = translations[0]["translatedText"]
				else { return }

				self?.lookedUpWords[text] = translatedText

				DispatchQueue.main.async {
					completed?(translatedText)
				}
			} catch let error {
				print(error)
				DispatchQueue.main.async {
					completed?(nil)
				}
			}
		}
		task.resume()
		return task
	}
}
