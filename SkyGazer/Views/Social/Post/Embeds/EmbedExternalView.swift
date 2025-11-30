//
//  EmbedExternalView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 22..
//

import SwiftUI

struct EmbedExternalView: View {
	var externalModel: EmbedExternal
	
	@State private var showFullTitle: Bool = false
	
	var body: some View {
		if let gif = URL(string: externalModel.uri)?.toGifMedia(altText: externalModel.title) {
			GIFView(gif: gif)
		} else {
			linkView
		}
	}
	
	@ViewBuilder
	private var linkView: some View {
		VStack(alignment: .leading, spacing: 10) {
			if let url = externalModel.thumbnailURL {
				Rectangle()
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.aspectRatio(.init(width: 1.91, height: 1), contentMode: .fill)
					.overlay {
						DownloadableImage(url: url) {
							ProgressView()
						} error: {
							ImageFailedView()
						} image: { image in
							image
								.resizable()
								.aspectRatio(contentMode: .fill)
								.contentShape(imageShape)
						}
					}
					.clipShape(imageShape)
					.clipped()
					.overlay(alignment: .bottomLeading) {
						textOverlay
					}
				
			} else {
				Text(externalModel.title)
					.font(.headline)
					.padding(.horizontal, 10)
					.padding(.top, 10)
			}
			if !externalModel.description.isEmpty {
				Text(externalModel.description)
					.font(.subheadline)
					.padding(.horizontal, 10)
				Divider()
			}
			Text(externalModel.uri)
				.font(.caption)
				.foregroundStyle(.secondary)
				.padding(.horizontal, 10)
				.padding(.bottom, 10)
		}
		.background {
			RoundedRectangle(cornerRadius: 10)
				.fill(.thickMaterial)
		}
	}
	
	@ViewBuilder
	private var textOverlay: some View {
		Text(externalModel.title)
			.font(.subheadline)
			.fontWeight(.medium)
			.padding(10)
			.glassEffect(in: showFullTitle ? RoundedRectangle(cornerRadius: 10) : RoundedRectangle(cornerRadius: .infinity))
			.lineLimit(showFullTitle ? nil : 1)
			.padding(8)
			.animation(.easeOut, value: showFullTitle)
			.onTapGesture {
				showFullTitle.toggle()
			}
	}
	
	private var imageShape: some Shape {
		UnevenRoundedRectangle(cornerRadii: .init(
			topLeading: 10,
			bottomLeading: 0,
			bottomTrailing: 0,
			topTrailing: 10
		))
	}
}
