//
//  OnboardingView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "checkmark.seal.fill",
            iconColor: .blue,
            title: "Build Better Habits",
            body: "Track your daily habits, build streaks, and become the person you want to be — one day at a time."
        ),
        OnboardingPage(
            icon: "flame.fill",
            iconColor: .orange,
            title: "Keep Your Streak",
            body: "Every day you complete a habit your streak grows. Don't break the chain!"
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: .purple,
            title: "Get Reminded",
            body: "Set a custom reminder for each habit so you never forget what matters most."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)

            VStack(spacing: 12) {
                if page < pages.count - 1 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        finish()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Button {
                        requestNotificationsAndFinish()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(p.iconColor.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: p.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(p.iconColor)
            }
            VStack(spacing: 12) {
                Text(p.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(p.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func requestNotificationsAndFinish() {
        Task {
            _ = await NotificationManager.shared.requestAuthorization()
            finish()
        }
    }

    private func finish() {
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}
