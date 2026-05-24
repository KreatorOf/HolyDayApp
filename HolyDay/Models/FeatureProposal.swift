//
//  FeatureProposal.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation

struct FeatureProposal: Identifiable {
  let id: String
  let title: String
  let description: String
  let icon: String
  var voteCount: Int
  var hasVoted: Bool = false
}
