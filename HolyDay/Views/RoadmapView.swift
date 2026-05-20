//
//  RoadmapView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI

struct RoadmapView: View {
    @State private var service = FeatureVoteService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("roadmap.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if let err = service.error {
                    ContentUnavailableView(err, systemImage: "wifi.exclamationmark")
                        .padding(.top, 20)
                } else if service.proposals.isEmpty {
                    ContentUnavailableView(
                        String(localized: "roadmap.empty.title"),
                        systemImage: "list.bullet.clipboard",
                        description: Text("roadmap.empty.subtitle")
                    )
                    .padding(.top, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(service.proposals) { proposal in
                            ProposalCard(proposal: proposal) {
                                Task { await service.vote(for: proposal) }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("Roadmap")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.backgroundPrimary.ignoresSafeArea())
        .task { await service.load() }
        .refreshable { await service.load() }
    }
}

// MARK: Proposal card

private struct ProposalCard: View {
    let proposal: FeatureProposal
    let onVote: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.adorationPurple.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: proposal.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.adorationPurple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(proposal.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(proposal.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onVote) {
                VStack(spacing: 4) {
                    Image(systemName: proposal.hasVoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(proposal.voteCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(proposal.hasVoted ? AppTheme.adorationPurple : AppTheme.textSecondary)
                .frame(width: 54, height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(proposal.hasVoted
                              ? AppTheme.adorationPurple.opacity(0.15)
                              : Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    proposal.hasVoted
                                    ? AppTheme.adorationPurple.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .buttonStyle(.plain)
            .disabled(proposal.hasVoted)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: proposal.hasVoted)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

#Preview {
    NavigationStack {
        RoadmapView()
    }
    .preferredColorScheme(.dark)
}
