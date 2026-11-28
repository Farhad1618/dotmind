import DotMind
import SwiftUI

struct ContentView: View {
    @State private var look: Look = .classic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                header
                LookPicker(look: $look)
                LiveStage(look: look)
                PageSection(
                    title: "Every state",
                    detail: "The tool's name decides the picture: web_search sweeps, run_sql lights disks, bash types between brackets."
                ) {
                    Gallery(items: GalleryItem.states, look: look)
                }
                PageSection(
                    title: "Icons",
                    detail: "look: .icons draws small pictures with a soft aura in the scene's colour."
                ) {
                    Gallery(items: GalleryItem.icons)
                }
                PageSection(
                    title: "Pixel",
                    detail: "look: .pixel swaps round dots for square pixels and plays little 8-bit scenes."
                ) {
                    Gallery(items: GalleryItem.pixels)
                }
                PageSection(
                    title: "The original eight",
                    detail: "Fixed scenes for when you only need a nice loader. Pass scene to pick one."
                ) {
                    Gallery(items: GalleryItem.scenes)
                }
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 56)
            .frame(maxWidth: .infinity)
        }
        .background(background)
        .foregroundStyle(Palette.ink)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "dotmind · SwiftUI")
            Text("The dots know what the model is doing")
                .font(.system(size: 30, weight: .semibold))
                .tracking(-0.8)
                .fixedSize(horizontal: false, vertical: true)
            Text("An 8 × 8 dot matrix follows the model's stream: a slow drift while it reasons, a radar sweep while it searches, a filling page while it writes.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.inkDim)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var background: some View {
        RadialGradient(
            colors: [Palette.stageHighlight, Palette.stage],
            center: UnitPoint(x: 0.2, y: 0),
            startRadius: 0,
            endRadius: 520
        )
        .background(Palette.stage)
        .ignoresSafeArea()
    }
}

private struct LookPicker: View {
    @Binding var look: Look

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Look")
            Picker("Look", selection: $look) {
                ForEach(Look.allCases, id: \.self) { look in
                    Text(look.rawValue.capitalized).tag(look)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
        }
    }
}

struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.mono(11))
            .tracking(2)
            .foregroundStyle(Palette.inkFaint)
    }
}

private struct PageSection<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.inkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
    }
}
