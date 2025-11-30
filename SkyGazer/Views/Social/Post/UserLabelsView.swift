//
//  UserLabelsView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 21..
//

import SwiftUI

struct UserLabelsView: View {
	let labels: [UserLabel]
	
	@State private var selectedLabelForDetails: UserLabel? = nil
	
	var body: some View {
		if !labels.isEmpty {
			WrappingHStack(lineSpacing: 4) {
				ForEach(labels) {
					labelView($0)
				}
			}
			.frame(maxWidth: .infinity)
			.adaptiveSheet(item: $selectedLabelForDetails) {
				labelDetailsView($0)
			}
		}
	}
	
	@ViewBuilder
	private func labelView(_ label: UserLabel) -> some View {
		HStack(spacing: 5) {
			DownloadableImage(url: label.avatarURL) {
				Circle()
					.fill(.thinMaterial)
			} error: {
				EmptyView()
			} image: { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
			.frame(width: 15, height: 15)
			.clipShape(Circle())
			.clipped()
			.contentShape(Circle())
			Text(label.name)
				.font(.caption2)
		}
		.onTapGesture {
			selectedLabelForDetails = label
		}
	}
	
	@ViewBuilder
	private func labelDetailsView(_ label: UserLabel) -> some View {
		VStack(alignment: .leading) {
			Group {
				Text(label.name)
					.font(.title3)
					.padding(.bottom, 3)
				Text(label.description)
					.font(.callout)
				Divider()
				HStack(spacing: 0) {
					Text("Source: ")
						.foregroundStyle(.secondary)
					Button(label.creatorHandle) {
						// TODO: - make it do something
					}
					Spacer(minLength: 0)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.callout)
			}
			.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, 15)
		.padding(.top, 22)
		.padding(.bottom, 10)
	}
}
