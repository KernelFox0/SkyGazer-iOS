//
//  PostView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import SwiftUI

struct MinimalPostView: View {
	@State var post: RecordPost
	let embedRecord: EmbedRecord?
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	init(recordPost post: RecordPost) {
		self.post = post
		self.embedRecord = nil
	}
	
	init(anyPost post: some AnyPost) {
		self.post = RecordPost(
			uri: post.uri,
			cid: post.cid,
			postAuthor: post.postAuthor,
			embeds: EmbedRecordEmbedModel(
				images: post.embeds?.images ?? [],
				video: post.embeds?.video,
				external: post.embeds?.external
			),
			labels: post.labels,
			likeCount: post.likeCount,
			repostCount: post.repostCount,
			quoteCount: post.quoteCount,
			replyCount: post.replyCount,
			text: post.text,
			facets: post.facets,
			creationDate: post.CreationDate,
			languages: post.languages,
			tags: post.tags,
			likeURI: post.likeURI,
			repostURI: post.repostURI,
			isThreadMuted: post.isThreadMuted,
			isBookmarked: post.isBookmarked
		)
		self.embedRecord = post.embeds?.record
	}
	
	var body: some View {
		ContentBox(alignment: .leading) {
			VStack(alignment: .leading) {
				HStack(alignment: .center) {
					profilePictureView
					postHeaderView
				}
				UserLabelsView(labels: post.postAuthor.userLabels)
				if !post.text.isEmpty {
					AttributedBskyTextView(post.text, facets: post.facets, accentColor: preferenceManager.accentColor, font: .subheadline) { url in
						print("Link: \(url)")
					} onHandleTap: { handle in
						print("Handle: \(handle)")
					} onTagTap: { tag in
						print("Tag: \(tag)")
					}
				}
				postEmbedsView
				if post.isBookmarked != nil { // Only show interaction if it's a root and not an embed, and roots will never and embeds will always have isBookmarked as nil
					PostInteractionButtons(post: $post)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	@ViewBuilder
	private var profilePictureView: some View {
		NavigationLink {
			UserScreenView(userDid: post.postAuthor.did)
		} label: {
			DownloadableImage(url: post.postAuthor.profileImage) {
				ProgressView()
			} error: {
				ImageFailedView()
			} image: { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fill)
			}
			.clipShape(Circle())
			.clipped()
			.frame(width: 20, height: 20)
			.background {
				Circle()
					.fill(.thinMaterial)
			}
		}
	}
	
	@ViewBuilder
	private var postHeaderView: some View {
		HStack {
			if let name = post.postAuthor.name,
			   !name.isEmpty {
				Text(name)
					.font(.subheadline)
					.fontWeight(.semibold)
				VerificationBadgeView(verified: post.postAuthor.verified)
			}
			
			let hasName: Bool = post.postAuthor.name != nil && (post.postAuthor.name?.isEmpty == false)
			
			Text("@\(post.postAuthor.handle)")
				.font(hasName ? .footnote : .subheadline)
				.fontWeight(hasName ? .light : .semibold)
				.foregroundStyle(hasName ? .secondary : .primary)
			if !hasName {
				VerificationBadgeView(verified: post.postAuthor.verified)
			}
			Group {
				Text("•")
				Text(post.creationDate.getSimpleTimeSince())
					.font(.footnote)
					.fontWeight(.light)
			}
			.foregroundStyle(.secondary)
			.lineLimit(1)
		}
		.lineLimit(1)
	}
	
	@ViewBuilder
	private var postEmbedsView: some View {
		if let embeds = post.embeds {
			if embeds.images.count > 0 {
				EmbedImageView(images: embeds.images)
			}
			if let video = embeds.video,
			   let url = video.url {
				VideoView(video: video, url: url)
			}
			if let externalEmbed = embeds.external {
				EmbedExternalView(externalModel: externalEmbed)
			}
			if let embedRecord {
				RecordView(record: embedRecord)
			}
		}
	}
}

struct PostView<P: AnyPost>: View {
	@State var post: P
	
	@State private var showDespiteContentLabel: Bool = false
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	var body: some View {
		ContentBox(alignment: .leading) {
			postReplyReferenceView
			HStack(alignment: .top) {
				profilePictureView
				VStack(alignment: .leading) {
					postHeaderView
					if (post.labels.moderationLabels?.first(where: { $0.visibility == .blur }) == nil && post.labels.selfLabels?.isEmpty != false) || showDespiteContentLabel {
						if !post.text.isEmpty {
							AttributedBskyTextView(post.text, facets: post.facets, accentColor: preferenceManager.accentColor, font: .subheadline) { url in
								print("Link: \(url)")
							} onHandleTap: { handle in
								print("Handle: \(handle)")
							} onTagTap: { tag in
								print("Tag: \(tag)")
							}
						}
						postEmbedsView
					} else {
						ContentBox {
							HStack {
								VStack(alignment: .leading) {
									Text("Content hidden!")
									Text(postHideLabelsReasons(labels: post.labels))
										.font(.footnote)
								}
								Button("Show") {
									showDespiteContentLabel.toggle()
								}
								.buttonStyle(.glass)
							}
						}
					}
					PostInteractionButtons(post: $post)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}
	
	private func postHideLabelsReasons(labels: PostLabelUnion) -> String {
		var reasonString: String = ""
		
		if let moderationLabels = labels.moderationLabels {
			for label in moderationLabels {
				reasonString = "\(reasonString)\(label.name), "
			}
		}
		
		if let selfLabels = labels.selfLabels {
			for label in selfLabels {
				reasonString = "\(reasonString)\(label.uiName()), "
			}
		}
		
		return reasonString.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .punctuationCharacters)
	}
	
	@ViewBuilder
	private var profilePictureView: some View {
		NavigationLink {
			UserScreenView(userDid: post.postAuthor.did)
		} label: {
			DownloadableImage(url: post.postAuthor.profileImage) {
				ProgressView()
			} error: {
				ImageFailedView()
			} image: { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fill)
			}
			.clipShape(Circle())
			.clipped()
			.frame(width: 50, height: 50)
			.background {
				Circle()
					.fill(.thinMaterial)
			}
		}
	}
	
	@ViewBuilder
	private var postHeaderView: some View {
		VStack(alignment: .leading) {
			HStack {
				if let name = post.postAuthor.name,
				   !name.isEmpty {
					Text(name)
						.font(.subheadline)
						.fontWeight(.semibold)
					VerificationBadgeView(verified: post.postAuthor.verified)
				}
				
				let hasName: Bool = post.postAuthor.name != nil && (post.postAuthor.name?.isEmpty == false)
				
				Text("@\(post.postAuthor.handle)")
					.font(hasName ? .footnote : .subheadline)
					.fontWeight(hasName ? .light : .semibold)
					.foregroundStyle(hasName ? .secondary : .primary)
				if !hasName {
					VerificationBadgeView(verified: post.postAuthor.verified)
				}
				Group {
					Text("•")
					Text(post.CreationDate.getSimpleTimeSince())
						.font(.footnote)
						.fontWeight(.light)
				}
				.foregroundStyle(.secondary)
				.lineLimit(1)
			}
			.lineLimit(1)
			UserLabelsView(labels: post.postAuthor.userLabels)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	@ViewBuilder
	private var postReplyReferenceView: some View {
		if let feedPost = post as? FeedPost {
			if feedPost.parent != nil || feedPost.root != nil {
				VStack {
					postReplyReferenceExtractorView(feedPost.root)
					if feedPost.root != nil && feedPost.parent != nil {
						VStack(alignment: .leading, spacing: -8) {
							Text("•")
							Text("•")
							Text("•")
						}
						.font(.headline)
						.fontWeight(.regular)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.leading, 12)
						.foregroundStyle(.secondary)
					}
					postReplyReferenceExtractorView(feedPost.parent)
				}
				.padding(.bottom)
			}
			if feedPost.feedReason != .none {
				feedPost.feedReason.getLabel()
					.font(.footnote)
					.foregroundStyle(.secondary)
					.padding(.leading, 10)
					.lineLimit(1)
			}
		}
	}
	
	@ViewBuilder
	private func postReplyReferenceExtractorView(_ post: RootPost?) -> some View {
		if let post {
			if post.isBlocked {
				ContentBox(alignment: .leading) {
					Label("Post may be from a blocked or blocking account", systemImage: "nosign")
				}
			} else if let rootPost = post.post {
				// TODO: - minimal post view here
				MinimalPostView(anyPost: rootPost)
			} else {
				ContentBox(alignment: .leading) {
					Label("Post not found", systemImage: "nosign")
				}
			}
		}
	}
	
	@ViewBuilder
	private var postEmbedsView: some View {
		if let embeds = post.embeds {
			if embeds.images.count > 0 {
				EmbedImageView(images: embeds.images)
			}
			if let video = embeds.video,
			   let url = video.url {
				VideoView(video: video, url: url)
			}
			if let externalEmbed = embeds.external {
				EmbedExternalView(externalModel: externalEmbed)
			}
			if let recordEmbed = embeds.record {
				RecordView(record: recordEmbed)
			}
		}
	}
}

import ATProtoKit

#Preview {
	@Previewable @State var facets: [AppBskyLexicon.RichText.Facet]? = nil
	if let facets {
		ScrollView {
			PostView(post: Post(
				uri: "",
				cid: "",
				text: "Hello! This is a test post with links in it! https://example.com.\nAlso mentions like @kernelfox.com.de and #tags #like #this!\n\nThis was the test.",
				facets: facets,
				CreationDate: Date(timeIntervalSince1970: 0),
				labels: PostLabelUnion(),
				languages: ["en", "de", "hu"],
				tags: nil,
				reply: nil,
				replyCount: 888888,
				repostCount: 888888,
				quoteCount: 5,
				likeCount: 888888,
				postAuthor: PostUser(
					did: "",
					name: "Test User",
					handle: "testuser.example.com",
					profileImage: URL(string: "https://picsum.photos/id/237/200/300"),
					labels: nil,
					userLabels: [],
					verified: nil,
					isFollowedBy: false,
					isBlocked: false,
					isMuted: false
				),
				embeds: EmbedModel.init(
					images: [
						EmbedImage(
							thumbnailURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							fullsizeURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							altText: "This is an alt text",
							aspectRatio: nil,
							width: nil,
							height: nil
						),
						EmbedImage(
							thumbnailURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							fullsizeURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							altText: "This is an alt text",
							aspectRatio: nil,
							width: nil,
							height: nil
						),
						EmbedImage(
							thumbnailURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							fullsizeURL: URL(string: "https://picsum.photos/id/237/200/300")!,
							altText: "This is an alt text",
							aspectRatio: nil,
							width: nil,
							height: nil
						),
//						EmbedImage(
//							thumbnailURL: URL(string: "https://picsum.photos/id/237/200/300")!,
//							fullsizeURL: URL(string: "https://picsum.photos/id/237/200/300")!,
//							altText: "This is an alt text",
//							aspectRatio: nil,
//							width: nil,
//							height: nil
//						)
					],
					external: EmbedExternal(title: "Title", description: "Description", thumbnailURL: URL(string: "https://picsum.photos/id/237/200/300?2"), uri: "https://example.com")
				),
				threadgate: ThreadGate.init(
					allowQuotes: true,
					allowReplies: true,
					rules: [
						
					],
					userCanReply: true
				),
				likeURI: nil,
				repostURI: nil,
				isPinned: nil,
				isThreadMuted: nil,
				isBookmarked: false
			))
		}
	}
	if facets == nil {
		EmptyView()
			.task {
				let tempFacets = await ATFacetParser.parseFacets(from: "Hello! This is a test post with links in it! https://example.com.\nAlso mentions like @kernelfox.com.de and #tags #like #this!\n\nThis was the test.")
				await MainActor.run {
					facets = tempFacets
				}
			}
	}
}
