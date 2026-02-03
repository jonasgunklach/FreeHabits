//
//  ProgressHeaderView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI

struct ProgressHeaderView: View {
    let completed: Int
    let total: Int
    let date: Date

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .orange }
        return .accentColor
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                if completed == total && total > 0 {
                    Text("All done! 🎉")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                } else if total == 0 {
                    Text("No habits today")
                        .font(.title2.bold())
                } else {
                    Text("\(completed) of \(total)")
                        .font(.title2.bold()) +
                    Text(" done")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress)
                    .tint(progressColor)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)
                    .padding(.top, 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completed)
            }

            Spacer()

            // Large ring
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor.gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completed)
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color(.label).opacity(0.06), radius: 8, y: 2)
    }
}
