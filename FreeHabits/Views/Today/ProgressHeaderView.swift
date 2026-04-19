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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if completed == total && total > 0 {
                    Text("All done! 🎉")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("\(completed) of \(total) completed")
                        .font(.title3.bold())
                }
                ProgressView(value: progress)
                    .tint(progressColor)
                    .padding(.top, 2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completed)
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completed)
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 56, height: 56)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
