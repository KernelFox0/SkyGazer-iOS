//
//  RecordView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 21..
//

import SwiftUI

struct RecordView: View {
	let record: EmbedRecord
	
	var body: some View {
		switch record {
		case .post(let post):
			MinimalPostView(recordPost: post)
		case .notFound:
			ContentBox {
				Label("Post not found", systemImage: "nosign")
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		case .blocked:
			ContentBox {
				Label("Post may be from a blocked or blocking account", systemImage: "nosign")
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		case .detached:
			ContentBox {
				Label("Post has been detached", systemImage: "nosign")
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		case .generator(let generator):
			ContentBox {
				Text("It's a generator named \(generator.displayName)")
			}
		case .list(let list):
			ContentBox {
				Text("It's a list named \(list.displayName)")
			}
		case .labeler(let labeler):
			ContentBox {
				Text("It's a labeler named \(labeler.creator?.name ?? "")")
			}
		case .starterPack(let starterPack):
			ContentBox {
				Text("It's a starter pack named \(starterPack?.displayName ?? "")")
			}
		}
	}
}
