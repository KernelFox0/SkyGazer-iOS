//
//  PostCreationScreenView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 12. 14..
//

import SwiftUI

struct CharacterCountGaugeView: View {
	let value: Double
	let maxValue: Double
	
	@State private var scale: CGFloat = 0.7
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	private var tintColor: Color {
		if value < maxValue * 0.8 {
			guard preferenceManager.accentColor != .yellow && preferenceManager.accentColor != .red else { return .blue }
			return preferenceManager.accentColor
		} else if value < maxValue * 0.9 {
			return .yellow
		} else {
			return .red
		}
	}
	
	var body: some View {
		Gauge(value: (value / maxValue).clamp(min: 0, max: 1)) {
			EmptyView()
		} currentValueLabel: {
			Text("\((maxValue - value).formatted())")
		}
		.controlSize(.small)
		.gaugeStyle(.accessoryCircularCapacity)
		.tint(tintColor)
		.frame(width: 30, height: 30)
		.scaleEffect(scale)
		.animation(.easeInOut, value: scale)
		.animation(.easeInOut, value: tintColor)
		.onChange(of: tintColor) { _, _ in
			scale = 0.9
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				scale = 0.7
			}
		}
	}
}

struct LocalePickerView: View {
	@Binding var selectedLocale: Locale
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	private let languages: [Locale] = {
		Locale.availableIdentifiers
			.compactMap { Locale(identifier: $0).language.languageCode }
			.reduce(into: [String: Locale]()) { result, code in
				let id = code.identifier
				if result[id] == nil {
					result[id] = Locale(identifier: id)
				}
			}
			.values
			.sorted {
				Locale.current.localizedString(forLanguageCode: $0.language.languageCode?.identifier ?? "") ?? ""
				<
					Locale.current.localizedString(forLanguageCode: $1.language.languageCode?.identifier ?? "") ?? ""
			}
	}()
	
	var body: some View {
		Picker(Locale.current.localizedString(forLanguageCode: selectedLocale.language.languageCode?.identifier ?? "en") ?? "Unknown", selection: $selectedLocale) {
			ForEach(languages, id: \.identifier) { locale in
				Text(
					Locale.current.localizedString(
						forLanguageCode: locale.language.languageCode?.identifier ?? ""
					) ?? locale.identifier
				)
				.tag(locale)
			}
		}
		.pickerStyle(.menu)
		.tint(preferenceManager.accentColor)
		.onAppear {
			guard let locale = preferenceManager.defaultPostLocaleIdentifier else { return }
			selectedLocale = Locale(identifier: locale)
		}
	}
}

struct PostCreationScreenView: View {
	@State private var text: String = ""
	private let maxCharacterCount = 300
	@FocusState private var keyboardIsFocused
	@State private var profilePictureURL: URL? = nil
	@State private var selectedLocale: Locale = Locale(identifier: Locale.current.language.languageCode?.identifier ?? "en")
	@State private var threadgate = ThreadGate()
	@State private var showThreadgateEditor: Bool = false
	@State private var postProgress: Bool = false
	
	@Environment(\.dismiss) private var dismiss
	@Environment(PreferenceManager.self) private var preferenceManager
	@Environment(AppMessageManager.self) private var appMessageManager
	
    var body: some View {
		VStack(alignment: .leading) {
			// Header
			HStack {
				Button("Cancel") {
					HapticsManager.impact(style: .light)
					dismiss()
				}
				.buttonStyle(.glass)
				Spacer(minLength: 0)
				Text("New Post")
					.fontWeight(.semibold)
				Spacer(minLength: 0)
				if !postProgress {
					Button("Post") {
						HapticsManager.impact(style: .medium)
						postProgress = true
						Task {
							do {
								if let result = try await PostManager.shared.createPost(text: text, locales: [selectedLocale], threadgate: threadgate) {
									await MainActor.run {
										appMessageManager.message = ActionedAppMessage(message: "Posted!", icon: "checkmark", actionTitle: "View", action: {
											print("This should show the freshly made post. And it will, once it's implemented :3\nPost URI: \(result)")
										})
										dismiss()
									}
								} else {
									throw AppError(type: .post, message: "Empty URI Response")
								}
							}
							catch {
								await MainActor.run {
									appMessageManager.error = AppError(type: .post, localizedMessage: error.localizedDescription)
								}
							}
						}
					}
					.tint(text.isEmpty || text.count > 300 ? nil : preferenceManager.accentColor) // Attachment checking here
					.buttonStyle(.glassProminent)
					.disabled(text.isEmpty || text.count > 300) // Attachment checking here
				} else {
					ProgressView()
				}
			}
			.padding([.top, .horizontal])
			Divider()
			VStack {
				// Posting Area
				HStack(alignment: .top) {
					Circle()
						.fill(.thinMaterial)
						.frame(width: 50, height: 50)
						.overlay {
							if let profilePictureURL {
								DownloadableImage(url: profilePictureURL) {
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
							}
						}
					.task {
						let url = await UserManager.shared.getMinimalUserDetails(did: UserManager.shared.loggedInDID ?? "")?.profileImage
						await MainActor.run {
							profilePictureURL = url
						}
					}
					TextEditor(text: $text)
						.scrollContentBackground(.hidden)
						.textEditorStyle(.plain)
						.overlay(alignment: .topLeading) {
							if text.count == 0 {
								Text("What's up?")
									.foregroundStyle(.secondary)
									.offset(x: 4, y: 9)
									.allowsHitTesting(false)
							}
						}
						.focused($keyboardIsFocused)
						.onAppear {
							keyboardIsFocused = true
						}
				}
				Spacer()
				// Controls
				HStack { // Interaction and self label settings
					Button(threadgate.uiName(), systemImage: threadgate.uiSystemImage()) {
						keyboardIsFocused = false
						withAnimation {
							showThreadgateEditor = true
						}
					}
					.buttonStyle(.glass)
					.foregroundStyle(.secondary)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				HStack { // Attachment options and other settings
					Group {
						Button {
							
						} label: {
							Image(systemName: "photo.on.rectangle")
						}
						Button {
							
						} label: {
							Image(systemName: "camera")
						}
						Button {
							
						} label: {
							Image(systemName: "rectangle")
								.overlay {
									Text("GIF")
										.font(.caption)
								}
						}
					}
					.buttonStyle(.borderless)
					.font(.title2)
					.fontWeight(.regular)
					.tint(preferenceManager.accentColor)
					.padding(.horizontal, 2)
					Spacer()
					LocalePickerView(selectedLocale: $selectedLocale)
					CharacterCountGaugeView(value: Double(text.count), maxValue: Double(maxCharacterCount))
						.padding(.leading, 5)
				}
			}
			.padding([.bottom, .horizontal])
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.overlay(alignment: .bottom) {
			if showThreadgateEditor {
				threadgateEditor
					.transition(
						.move(edge: .bottom)
							.combined(with: .opacity)
					)
			}
		}
    }
	
	@State private var threadgateViewModel = ThreadgateViewModel()
	
	private var threadgateEditor: some View {
		VStack(alignment: .leading) {
			HStack {
				VStack(alignment: .leading) {
					Text("Interaction settings")
						.font(.title2)
						.fontWeight(.semibold)
					Text("Who can reply")
						.font(.headline)
						.fontWeight(.regular)
				}
				Spacer()
				Image(systemName: "xmark")
					.font(.title2)
					.aspectRatio(contentMode: .fit)
					.frame(width: 20, height: 20)
					.foregroundStyle(.white)
					.padding(7)
					.glassEffect(.regular.interactive(), in: Circle())
					.contentShape(Circle())
					.offset(y: -10)
					.onTapGesture {
						withAnimation {
							showThreadgateEditor = false
						}
					}
			}
			Picker("Who can reply", selection: $threadgateViewModel.mainReplyMode) {
				Text("Everyone")
					.tag(true)
				Text("No one")
					.tag(false)
			}
			.pickerStyle(.segmented)
			.onChange(of: threadgateViewModel.mainReplyMode) { _, value in
				guard let value else { return }
				
				// Reset ViewModel
				threadgateViewModel.allowFollowers = false
				threadgateViewModel.allowFollowing = false
				threadgateViewModel.allowMentioned = false
				threadgateViewModel.allowListUris = []
				
				// Set threadgate
				threadgate.allowReplies = value
				threadgate.rules = []
			}
			VStack {
				Toggle("Your followers", isOn: $threadgateViewModel.allowFollowers)
				Toggle("People you follow", isOn: $threadgateViewModel.allowFollowing)
				Toggle("People you mention", isOn: $threadgateViewModel.allowMentioned)
			}
			.onChange(of: threadgateViewModel.allowFollowers) { _, value in
				if value {
					threadgateViewModel.mainReplyMode = nil
					threadgate.rules.append(.followers)
				} else {
					threadgate.rules.removeAll(where: { $0 == .followers })
				}
			}
			.onChange(of: threadgateViewModel.allowFollowing) { _, value in
				if value {
					threadgateViewModel.mainReplyMode = nil
					threadgate.rules.append(.following)
				} else {
					threadgate.rules.removeAll(where: { $0 == .following })
				}
			}
			.onChange(of: threadgateViewModel.allowMentioned) { _, value in
				if value {
					threadgateViewModel.mainReplyMode = nil
					threadgate.rules.append(.mentioned)
				} else {
					threadgate.rules.removeAll(where: { $0 == .mentioned })
				}
			}
			Toggle("Allow quote posts", isOn: $threadgate.allowQuotes)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.padding(.vertical)
		.background(.thinMaterial, in: ContainerRelativeShape())
		.padding(.horizontal)
		.onAppear {
			// Load Threadgate data into the ViewModel
			
			guard threadgate.allowReplies else {
				threadgateViewModel.mainReplyMode = false
				return
			}
			guard !threadgate.rules.isEmpty else {
				threadgateViewModel.mainReplyMode = true
				return
			}
			
			threadgateViewModel.mainReplyMode = nil
			
			for element in threadgate.rules {
				switch element {
				case .mentioned:
					threadgateViewModel.allowMentioned = true
				case .followers:
					threadgateViewModel.allowFollowers = true
				case .following:
					threadgateViewModel.allowFollowing = true
				case .list(let listURI):
					threadgateViewModel.allowListUris.append(listURI)
				}
			}
		}
	}
}

@Observable
fileprivate class ThreadgateViewModel {
	var mainReplyMode: Bool? = true
	
	var allowFollowers: Bool = false
	var allowFollowing: Bool = false
	var allowMentioned: Bool = false
	
	var allowListUris: [String] = []
}

#Preview {
    PostCreationScreenView()
}
