import DotMind
import SwiftUI

struct LiveStage: View {
    let look: Look
    @StateObject private var turn = AgentTurn()

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            DotMindView(tracker: turn.tracker, size: 56, look: look)
                .dotMindTheme(DotMindTheme(fontSize: 24))
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "What the dots showed")
                Trail(labels: turn.trail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Palette.rule, lineWidth: 1)
                )
        )
        .task { await turn.play() }
    }
}

private struct Trail: View {
    let labels: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Text(label.uppercased())
                    .font(.mono(11))
                    .tracking(0.7)
                    .foregroundStyle(index == labels.count - 1 ? Palette.ink : Palette.inkDim)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(index == labels.count - 1 ? Palette.chipActive : Palette.chip)
                    )
            }
        }
        .frame(minHeight: 25, alignment: .topLeading)
        .animation(.easeOut(duration: 0.2), value: labels)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let next = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if next > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
