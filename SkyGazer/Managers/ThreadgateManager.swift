//
//  ThreadgateManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import Foundation
import ATProtoKit

class ThreadgateManager {
	nonisolated func extractThreadgate(threadgateDefinition: AppBskyLexicon.Feed.ThreadgateViewDefinition?, quotesDisabled: Bool?, userRepliesDisabled: Bool?) -> ThreadGate {
		var threadgate = ThreadGate()
		
		threadgate.allowQuotes = !(quotesDisabled ?? false)
		threadgate.userCanReply = !(userRepliesDisabled ?? false)
		
		if let threadgateDefinition {
			let record = threadgateDefinition.record.getRecord(ofType: AppBskyLexicon.Feed.ThreadgateRecord.self)
			
			if let record {
				if let allowList = record.allow {
					if allowList.isEmpty {
						threadgate.allowReplies = false
					}
					else {
						threadgate.allowReplies = true
						for allow in allowList {
							switch allow {
							case .mentionRule(_):
								threadgate.rules.append(.mentioned)
							case .followerRule(_):
								threadgate.rules.append(.followers)
							case .followingRule(_):
								threadgate.rules.append(.following)
							case .listRule(let rule):
								threadgate.rules.append(.list(listURI: rule.listURI))
							case .unknown(_, _):
								continue
							}
						}
					}
				}
			}
			else {
				threadgate.allowReplies = true
				threadgate.rules = []
			}
		}
		
		return threadgate
	}
	
	func compileThreadgate(threadgate: ThreadGate) -> [ATProtoBluesky.ThreadgateAllowRule]? {
		typealias AllowRule = ATProtoBluesky.ThreadgateAllowRule
		
		if threadgate.allowReplies && threadgate.rules.isEmpty {
			return nil
		}
		else if threadgate.allowReplies {
			var returnList: [AllowRule] = []
			for rule in threadgate.rules {
				switch rule {
				case .mentioned:
					returnList.append(AllowRule.allowMentions)
				case .followers:
					returnList.append(AllowRule.allowFollowers)
				case .following:
					returnList.append(AllowRule.allowFollowing)
				case .list(let listURI):
					returnList.append(AllowRule.allowList(listURI: listURI))
				}
			}
			return returnList
		}
		else {
			return []
		}
	}
}
