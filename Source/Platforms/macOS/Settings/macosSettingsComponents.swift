// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

// Building blocks for the Settings page. They use the same named colours as the API and Manage
// views: cards on Button, with rows, inner sections and buttons on the darker BackgroundAlt

struct macosSettingsCard<Content: View>: View {
  var title: String? = nil
  var subtitle: String? = nil
  var badge: macosSettingsBadge? = nil
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      // A card without a title skips the header, for content whose rows label themselves
      if let title = title {
        HStack(alignment: .top, spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.system(size: 14, weight: .semibold))
              .foregroundColor(Color("TextColor"))
            if let subtitle = subtitle {
              Text(subtitle)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Spacer(minLength: 8)

          if let badge = badge {
            badge
          }
        }
      }

      content
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
  }
}

struct macosSettingsBadge: View {
  enum Tone {
    case neutral, positive, accent
  }

  let text: String
  var tone: Tone = .neutral

  var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .foregroundColor(tone == .neutral ? Color("TextSecondary") : .white)
      .background(RoundedRectangle(cornerRadius: 5).fill(fill))
  }

  private var fill: Color {
    switch tone {
    case .neutral: return Color("BackgroundFixedShadow")
    case .positive: return Color("PositiveButton")
    case .accent: return Color("ButtonHighlighted")
    }
  }
}

// A setting with its title and explanation on the left and its control on the right
struct macosSettingsRow<Accessory: View>: View {
  let title: String
  let description: String
  @ViewBuilder var accessory: Accessory

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(Color("TextColor"))
        Text(description)
          .font(.system(size: 11))
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 12)
      accessory
    }
  }
}

// A label and value pair, eg. in Build Details, with room for a trailing control such as a copy button
struct macosKeyValueRow<Accessory: View>: View {
  let label: String
  let value: String
  @ViewBuilder var accessory: Accessory

  var body: some View {
    HStack(spacing: 6) {
      Text(label)
        .font(.system(size: 12))
      Spacer(minLength: 8)
      Text(value)
        .font(.system(size: 12, weight: .medium).monospacedDigit())
        .foregroundColor(Color("TextColor"))
        .lineLimit(1)
        .truncationMode(.middle)
        .textSelection(.enabled)
      accessory
    }
    .padding(.vertical, 7)
  }
}

extension macosKeyValueRow where Accessory == EmptyView {
  init(label: String, value: String) {
    self.init(label: label, value: value) { EmptyView() }
  }
}

// A row that opens a link outside the app, with a pointing hand cursor on hover
struct macosLinkRow: View {
  let icon: String
  let title: String
  var subtitle: String? = nil
  var actionLabel: String? = nil
  let destination: URL

  @State private var hovering = false

  var body: some View {
    Link(destination: destination) {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 13))
          .frame(width: 18)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color("TextColor"))
          if let subtitle = subtitle {
            Text(subtitle)
              .font(.system(size: 11))
          }
        }
        .lineLimit(1)
        // Keep the address or handle whole, the action label gives way first
        .layoutPriority(1)

        Spacer(minLength: 8)

        if let actionLabel = actionLabel {
          Text(actionLabel)
            .font(.system(size: 11))
            .lineLimit(1)
        }
        Image(systemName: "arrow.up.right")
          .font(.system(size: 10, weight: .semibold))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
      .background(RoundedRectangle(cornerRadius: 5).fill(Color(hovering ? "Background" : "BackgroundAlt")))
    }
    .buttonStyle(.plain)
    .help(destination.absoluteString)
    .onHover { inside in
      hovering = inside
      if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
    }
  }
}

// A small button, lighter on hover and when pressed, which turns green while `confirmed` is set, eg. "Saved"
struct macosSettingsButtonStyle: ButtonStyle {
  var confirmed = false

  func makeBody(configuration: Configuration) -> some View {
    macosSettingsButton(configuration: configuration, confirmed: confirmed)
  }
}

// The body of macosSettingsButtonStyle, a view of its own so it can track the pointer
private struct macosSettingsButton: View {
  let configuration: ButtonStyleConfiguration
  let confirmed: Bool

  @Environment(\.isEnabled) private var isEnabled
  @State private var hovering = false

  private var fill: Color {
    if confirmed { return Color("PositiveButton") }
    guard isEnabled else { return Color("BackgroundAlt") }
    if configuration.isPressed { return Color("ButtonHighlighted") }
    return Color(hovering ? "Background" : "BackgroundAlt")
  }

  var body: some View {
    configuration.label
      .font(.system(size: 12))
      .padding(.horizontal, 10)
      .frame(minHeight: 28)
      .foregroundColor(confirmed ? .white : Color("TextColor"))
      .background(RoundedRectangle(cornerRadius: 5).fill(fill))
      .contentShape(Rectangle())
      .onHover { hovering = $0 }
      .animation(.easeInOut(duration: 0.15), value: hovering)
      .animation(.easeInOut(duration: 0.3), value: confirmed)
  }
}

// One option in a row of choices, eg. the documents per page presets, filled while selected and on hover
struct macosSettingsSegment: View {
  let title: String
  let selected: Bool
  let action: () -> Void

  @State private var hovering = false

  private var fill: Color {
    if selected { return Color("ButtonHighlighted") }
    return hovering ? Color("Background") : Color.clear
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 12, weight: selected ? .semibold : .regular))
        .padding(.horizontal, 10)
        .frame(minHeight: 24)
        .foregroundColor(selected ? .white : Color(hovering ? "TextColor" : "TextSecondary"))
        .background(RoundedRectangle(cornerRadius: 5).fill(fill))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .animation(.easeInOut(duration: 0.15), value: hovering)
  }
}

// Its subviews side by side when they fit the width offered, otherwise one under another.
// ViewThatFits with an HStack and a VStack does the same, but builds and measures every subview twice
struct macosSettingsWrappingRow: Layout {
  var spacing: CGFloat = 10
  var rowSpacing: CGFloat = 8

  private func idealSizes(_ subviews: Subviews) -> [CGSize] {
    subviews.map { $0.sizeThatFits(.unspecified) }
  }

  private func rowWidth(_ sizes: [CGSize]) -> CGFloat {
    sizes.reduce(0) { $0 + $1.width } + spacing * CGFloat(max(sizes.count - 1, 0))
  }

  private func fitsInRow(_ sizes: [CGSize], width: CGFloat?) -> Bool {
    guard let width = width else { return true }
    return rowWidth(sizes) <= width
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let sizes = idealSizes(subviews)
    if fitsInRow(sizes, width: proposal.width) {
      return CGSize(width: rowWidth(sizes), height: sizes.map(\.height).max() ?? 0)
    }
    let height = sizes.reduce(0) { $0 + $1.height } + rowSpacing * CGFloat(max(sizes.count - 1, 0))
    return CGSize(width: sizes.map(\.width).max() ?? 0, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let sizes = idealSizes(subviews)
    if fitsInRow(sizes, width: bounds.width) {
      var x = bounds.minX
      for (subview, size) in zip(subviews, sizes) {
        subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
    } else {
      var y = bounds.minY
      for (subview, size) in zip(subviews, sizes) {
        subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
        y += size.height + rowSpacing
      }
    }
  }
}

// The Settings page's main and side columns side by side when there's room for both, otherwise the
// side column under the main one at full width. Takes exactly two subviews, the main column first
struct macosSettingsColumns: Layout {
  var mainIdealWidth: CGFloat
  var sideWidth: CGFloat
  var spacing: CGFloat = 16

  private func showsColumns(_ width: CGFloat?) -> Bool {
    guard let width = width else { return true }
    return width >= mainIdealWidth + spacing + sideWidth
  }

  // The width offered to the main column, then the side column
  private func columnWidths(_ width: CGFloat?) -> (main: CGFloat?, side: CGFloat?) {
    guard showsColumns(width) else { return (width, width) }
    return ((width ?? mainIdealWidth + spacing + sideWidth) - spacing - sideWidth, sideWidth)
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard subviews.count == 2 else { return .zero }
    let widths = columnWidths(proposal.width)
    let main = subviews[0].sizeThatFits(ProposedViewSize(width: widths.main, height: nil))
    let side = subviews[1].sizeThatFits(ProposedViewSize(width: widths.side, height: nil))
    if showsColumns(proposal.width) {
      return CGSize(width: main.width + spacing + side.width, height: max(main.height, side.height))
    }
    return CGSize(width: max(main.width, side.width), height: main.height + spacing + side.height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    guard subviews.count == 2 else { return }
    let widths = columnWidths(bounds.width)
    let mainProposal = ProposedViewSize(width: widths.main, height: nil)
    let sideProposal = ProposedViewSize(width: widths.side, height: nil)
    subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: mainProposal)
    if showsColumns(bounds.width) {
      subviews[1].place(at: CGPoint(x: bounds.maxX - sideWidth, y: bounds.minY),
                        anchor: .topLeading, proposal: sideProposal)
    } else {
      let mainHeight = subviews[0].sizeThatFits(mainProposal).height
      subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + mainHeight + spacing),
                        anchor: .topLeading, proposal: sideProposal)
    }
  }
}

// A hairline between rows, in the colour of the surface around it, eg. Button inside a BackgroundAlt section
struct macosSettingsDivider: View {
  var color = Color("BackgroundAlt")

  var body: some View {
    Rectangle()
      .fill(color)
      .frame(height: 1)
  }
}

#endif
