//
//  PrayerCompanionView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import FoundationModels
import SwiftUI

struct PrayerCompanionView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var session = AIAssistantService.shared.makeCompanionSession()
  @State private var messages: [CompanionMessage] = []
  @State private var input = ""
  @State private var isThinking = false
  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        VStack(spacing: 0) {
          messageList
          inputBar
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("companion.nav.title")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
    .onAppear {
      if messages.isEmpty {
        messages.append(
          CompanionMessage(isUser: false, text: String(localized: "companion.intro")))
      }
    }
  }

  // MARK: - Messages

  private var messageList: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 3) {
          ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
            bubble(message, isGrouped: isGroupedWithPrevious(index))
              .id(message.id)
          }
          if isThinking {
            HStack {
              TypingDots()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                  bubbleShape(isUser: false)
                    .fill(.ultraThinMaterial)
                }
              Spacer(minLength: 56)
            }
            .id("thinking")
            .accessibilityElement()
            .accessibilityLabel(String(localized: "companion.thinking"))
          }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
      }
      .scrollIndicators(.hidden)
      .onChange(of: messages.count) { _, _ in scrollToEnd(proxy) }
      .onChange(of: isThinking) { _, thinking in
        if thinking {
          withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("thinking", anchor: .bottom) }
        }
      }
    }
  }

  private func bubble(_ message: CompanionMessage, isGrouped: Bool) -> some View {
    HStack {
      if message.isUser { Spacer(minLength: 56) }
      Text(message.text)
        .font(.body)
        .foregroundStyle(message.isUser ? .white : AppTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
          bubbleShape(isUser: message.isUser)
            .fill(
              message.isUser
                ? AnyShapeStyle(AppTheme.adorationPurple)
                : AnyShapeStyle(.ultraThinMaterial))
        }
      if !message.isUser { Spacer(minLength: 56) }
    }
    .padding(.top, isGrouped ? 0 : 6)
    .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(message.isUser ? message.text : "Logos. \(message.text)")
    .transition(.opacity)
  }

  // iMessage-style bubble: rounded everywhere except a small "tail" corner on the sender side.
  private func bubbleShape(isUser: Bool) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      topLeadingRadius: 18,
      bottomLeadingRadius: isUser ? 18 : 5,
      bottomTrailingRadius: isUser ? 5 : 18,
      topTrailingRadius: 18,
      style: .continuous
    )
  }

  private func isGroupedWithPrevious(_ index: Int) -> Bool {
    guard index > 0 else { return false }
    return messages[index - 1].isUser == messages[index].isUser
  }

  private func scrollToEnd(_ proxy: ScrollViewProxy) {
    withAnimation(.easeOut(duration: 0.25)) {
      proxy.scrollTo(messages.last?.id, anchor: .bottom)
    }
  }

  // MARK: - Input

  private var inputBar: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("companion.placeholder", text: $input, axis: .vertical)
        .font(.body)
        .foregroundStyle(AppTheme.textPrimary)
        .focused($isFocused)
        .lineLimit(1...5)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
          Capsule()
            .fill(.ultraThinMaterial)
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke, lineWidth: 1) }
        }

      Button {
        send()
      } label: {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: 30))
          .foregroundStyle(canSend ? AppTheme.adorationPurple : AppTheme.textTertiary.opacity(0.4))
          .frame(width: 44, height: 44)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(!canSend)
      .accessibilityLabel(String(localized: "companion.send"))
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
  }

  private var canSend: Bool {
    !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
  }

  // MARK: - Send

  private func send() {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, !isThinking else { return }
    withAnimation(.easeOut(duration: 0.2)) {
      messages.append(CompanionMessage(isUser: true, text: text))
    }
    input = ""
    isThinking = true
    Task {
      defer { isThinking = false }
      do {
        let reply = try await session.respond(to: text).content
        withAnimation(.easeOut(duration: 0.2)) {
          messages.append(CompanionMessage(isUser: false, text: reply))
        }
      } catch {
        messages.append(
          CompanionMessage(isUser: false, text: String(localized: "companion.error")))
      }
    }
  }
}

// MARK: - Typing indicator

private struct TypingDots: View {
  @State private var animating = false

  var body: some View {
    HStack(spacing: 5) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(AppTheme.textTertiary)
          .frame(width: 7, height: 7)
          .scaleEffect(animating ? 1 : 0.5)
          .opacity(animating ? 1 : 0.4)
          .animation(
            .easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2),
            value: animating
          )
      }
    }
    .onAppear { animating = true }
  }
}

private struct CompanionMessage: Identifiable {
  let id = UUID()
  let isUser: Bool
  let text: String
}
