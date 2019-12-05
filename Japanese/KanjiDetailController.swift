//
//  KanjiDetailController.swift
//  Japanese
//
//  Created by Alexander Greene on 11/21/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI
import SVGKit
import AVFoundation
import RealmSwift

let kanjiRealmConfig = Realm.Configuration(fileURL: URL(string: Bundle.main.path(forResource: "kanji", ofType: "realm")!)!, readOnly: true, objectTypes: [Kanji.self])
let kanjiRealm = try! Realm(configuration: kanjiRealmConfig)

class Kanji: Object {
	@objc dynamic var dicRef = ""
	@objc dynamic var literal = ""
	@objc dynamic var radValue = ""
	@objc dynamic var strokeCount = ""
	@objc dynamic var cpValue = ""

	@objc dynamic var kunyomi = ""
	@objc dynamic var onyomi = ""

	@objc dynamic var variant = ""
	@objc dynamic var grade = ""
	@objc dynamic var meaning = ""

	convenience init(dicRef: String?, literal: String?, radValue: String?, strokeCount: String?, cpValue: String?, kunyomi: String?, onyomi: String?, variant: String?, grade: String?, meaning: String?) {
		self.init()

		self.dicRef = dicRef ?? ""
		self.literal = literal ?? ""
		self.radValue = radValue ?? ""
		self.strokeCount = strokeCount ?? ""
		self.cpValue = cpValue ?? ""
		self.kunyomi = kunyomi ?? ""
		self.onyomi = onyomi ?? ""
		self.variant = variant ?? ""
		self.grade = grade ?? ""
		self.meaning = meaning ?? ""
	}

	static func fromDict(dict: [String:String]) -> Kanji {
		return Kanji(
			dicRef: dict["dic_ref"],
			literal: dict["literal"],
			radValue: dict["rad_value"],
			strokeCount: dict["stroke_count"],
			cpValue: dict["cp_value"],
			kunyomi: dict["kunyomi"],
			onyomi: dict["onyomi"],
			variant: dict["variant"],
			grade: dict["grade"],
			meaning: dict["meaning"]
		)
	}

	override class func primaryKey() -> String? {
		return "literal"
	}
}

struct KanjiInfo {
	let kanji: String
	let numStrokes: Int
	let meaning: String
	let kunyomi: String
	let imagePaths: [String]
	let examples: [KanjiExample]
	let videoUrl: String
}

struct KanjiExample: Comparable {
	let mp3Url: String
	let text: String
	let meaning: String

	static func < (lhs: KanjiExample, rhs: KanjiExample) -> Bool {
		return lhs.mp3Url == rhs.mp3Url
	}
}

struct KanjiImage {
	let path: String
	let image: UIImage
}

struct KanjiRow: View {
	let kanjiImages: [KanjiImage]

	var body: some View {
		HStack {
			ForEach(kanjiImages, id: \.path) { (image: KanjiImage) in
				Image(uiImage: image.image)
					.resizable()
					.frame(width: 40, height: 40)
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct KanjiDetailView: View {
	@Environment(\.presentationMode) var presentationMode
	@EnvironmentObject var kanjiDetailStore: KanjiDetailStore

	let kanji: String

	func calculateHeight() -> CGFloat {
		let count = kanjiDetailStore.images?.count ?? 0
		let numRows = count / 7 + (count % 7 == 0 ? 0 : 1)
		let spacing = 4 * (numRows - 1)
		return CGFloat((40 * numRows) + spacing)
	}

	var body: some View {
		let isKanjiSelected = kanjiDetailStore.kanji != nil && kanjiDetailStore.kanjiInfo != nil
		return VStack(spacing: 0) {
			if isKanjiSelected {
				HStack {
					ZStack(alignment: .bottomTrailing) {
						Text(kanji)
							.font(.system(size: 80))

						Image(systemName: "play.circle.fill")
							.resizable()
							.frame(width: 20, height: 20, alignment: .bottomTrailing)
							.opacity(kanjiDetailStore.kanjiInfo?.videoUrl != nil ? 0.5 : 0)
					}
					.onTapGesture {
						if self.kanjiDetailStore.kanjiInfo?.videoUrl != nil {
							NotificationCenter.default.post(name: .presentVideoPlayerController, object: self.kanjiDetailStore.kanjiInfo?.videoUrl)
						}
					}

					VStack(alignment: .leading) {
						Text(kanjiDetailStore.kanjiInfo != nil ? "Meaning" : "")
							.foregroundColor(Color("accent"))
							.frame(maxWidth: .infinity, alignment: .leading)
						Text(kanjiDetailStore.kanjiInfo?.meaning ?? "")
							.padding(.bottom)
							.frame(maxWidth: .infinity, alignment: .leading)


						Text(kanjiDetailStore.kanjiInfo != nil ? "Kunyomi" : "")
							.foregroundColor(Color("accent"))
							.frame(maxWidth: .infinity, alignment: .leading)

						Text(kanjiDetailStore.kanjiInfo?.kunyomi ?? "")
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.padding(.leading)

				}
				.padding()
				.animation(.easeInOut)

				Divider()
					.frame(height: kanjiDetailStore.kanjiInfo != nil ? 1 : 0)
					.animation(.easeInOut)


				KanjiStrokeOrderView()
					.padding()
					.frame(maxHeight: kanjiDetailStore.images != nil ? calculateHeight() + 32 : 0)
					.animation(.easeInOut)

				Divider()
					.opacity(kanjiDetailStore.images != nil ? 1 : 0)
					.frame(height: kanjiDetailStore.kanjiInfo != nil ? 1 : 0)
					.padding(.vertical, 0)
					.animation(.easeInOut)

				ScrollView {
					VStack {
						ForEach(kanjiDetailStore.kanjiInfo?.examples ?? [], id: \.text) { example in
							HStack {
								VStack {
									Text("\(example.text)")
										.frame(maxWidth: .infinity, alignment: .leading)
										.foregroundColor(Color("accent"))

									Text("\(example.meaning)")
										.frame(maxWidth: .infinity, alignment: .leading)
								}

								Image(systemName: self.kanjiDetailStore.isPlaying && self.kanjiDetailStore.selectedExample == example ? "stop" : "play")
									.foregroundColor(Color("accent"))
							}
							.frame(maxWidth: .infinity)
							.background(Color("background"))
							.listRowBackground(Color("background"))
							.onTapGesture {
								self.kanjiDetailStore.selectedExample = example
								print(example.text)
							}
						}
					}
					.padding()
					.background(Color.clear)
					.opacity(kanjiDetailStore.kanjiInfo != nil ? 1 : 0)
				}
				.animation(.easeInOut)
			} else {
				KanjiNotInKanjiAliveView(key: kanji)
					.edgesIgnoringSafeArea(.all)
			}
		}
		.background(Color("background"))
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.edgesIgnoringSafeArea(.bottom)
		.onDisappear {
			print("kanji detail screen dismissed")
			NotificationCenter.default.post(name: .kanjiInfoScreenDismissed, object: nil)
		}
	}
}




struct KanjiNotInKanjiAliveView: View {
	let key: String

	var body: some View {
		guard let kanji = kanjiRealm.object(ofType: Kanji.self, forPrimaryKey: key) else {
			return AnyView(Text(""))
		}

		return AnyView(
			VStack {
				HStack(alignment: .bottom) {
					VStack {
						Text(kanji.literal)
							.font(.system(size: 80))
						HStack(spacing: 4) {
							Text("\(kanji.strokeCount) strokes")
								.foregroundColor(Color("foreground").opacity(0.5))
								.font(.subheadline)
						}
					}

					VStack(alignment: .leading) {
						Text("Meaning")
							.foregroundColor(Color("accent"))
							.frame(maxWidth: .infinity, alignment: .leading)
						Text(kanji.meaning)
							.padding(.bottom)
							.frame(maxWidth: .infinity, alignment: .leading)


						Text("Kunyomi")
							.foregroundColor(Color("accent"))
							.frame(maxWidth: .infinity, alignment: .leading)

						Text(kanji.kunyomi.split(separator: ".").joined(separator: ", "))
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.padding(.leading)
				}

//				Text("No info found")
//					.foregroundColor(Color("accent"))
//					.frame(alignment: .center)
			}
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		)
	}
}
