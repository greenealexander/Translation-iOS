//
//  AboutView.swift
//  Japanese
//
//  Created by Alexander Greene on 11/30/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
			ScrollView {
				VStack(alignment: .center) {
					Image("icon")
						.resizable()
						.frame(width: 80, height: 80)
						.cornerRadius(16)
						.padding()


					Text("Sources:")
						.foregroundColor(Color("accent"))
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal)

					ToolUsedView(name: "Google Translate API", description: "Translation of words", link: "https://translate.google.com")

					ToolUsedView(name: "MeCab", description: "Sentence tokenization and morphological analysis", link: "https://github.com/taku910/mecab")

					ToolUsedView(name: "KanjiAlive API", description: "Kanji information, stroke orders, and sound clips", link: "https://kanjialive.com")

					ToolUsedView(name: "Kanjidic2", description: "This app uses the Kanjidic2 dictionary file. This file is the property of the Electronic Dictionary Research and Development Group, and is used in conformance with the Group's licence.", link: "http://www.edrdg.org/wiki/index.php/KANJIDIC_Project")
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			.background(Color("background"))
    }
}

struct ToolUsedView: View {
	let name: String
	let description: String
	let link: String

	var body: some View {
		VStack {
			HStack {
				Image("paperclip")
					.resizable()
					.foregroundColor(Color("accent"))
					.frame(width: 20, height: 20)

				Text(name)
					.font(.headline)
					.fontWeight(.semibold)

				Spacer()
			}
			.onTapGesture {
					if let url = URL(string: self.link) {
							UIApplication.shared.open(url)
					}
			}

			Text(description)
				.font(.subheadline)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding()
	}
}
