// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// The scroll view's own coordinate space, which doesn't scroll with the panels. Drags are measured in it.
let macosDashboardGridSpace = "macosDashboardGrid"

/// What the grid gives a panel so dragging its header moves it
struct macosDashboardMoveHandle {
  /// False in a narrow window, where the panels are stacked
  var isEnabled: Bool
  /// This panel is the one being moved
  var isMoving: Bool
  var onChanged: (DragGesture.Value) -> Void
  var onEnded: () -> Void

  var gesture: some Gesture {
    DragGesture(minimumDistance: 3, coordinateSpace: .named(macosDashboardGridSpace))
      .onChanged(onChanged)
      .onEnded { _ in onEnded() }
  }
}

/// The dashboard's panels on a grid of 12 columns. In edit mode, drag a panel's header to move it, or its right
/// edge, bottom edge or corner to resize it: the other panels make way as it goes, and rise to fill any gap. The new
/// layout is handed to `onCommit` when it's let go. Esc puts everything back mid-drag, and otherwise ends edit mode.
struct macosDashboardGridView<Panel: View>: View {
  var panels: [DashboardPanel]
  var isEditing: Bool
  var onCommit: (DashboardLayout.Frames) -> Void
  /// Esc pressed in edit mode, away from a drag
  var onDoneEditing: () -> Void
  @ViewBuilder var panel: (DashboardPanel, macosDashboardMoveHandle) -> Panel

  /// A move or resize in progress
  struct Interaction {
    enum Mode: Equatable {
      case move
      case resize(right: Bool, bottom: Bool)
    }

    let id: UUID
    let mode: Mode
    /// The layout as it was when the drag started. Every step works from this, so nothing drifts.
    let original: DashboardLayout.Frames
    let start: DashboardGridFrame
    var translation: CGSize = .zero
    /// The pointer, in the scroll view's space
    var location: CGPoint = .zero
    /// How far the panels have scrolled since the drag started
    var scrolled: CGFloat = 0
    /// Esc was pressed: the rest of the drag is ignored
    var cancelled = false
  }

  @State private var interaction: Interaction? = nil
  @State private var scroller = macosDashboardScroller()
  @State private var keyMonitor: Any? = nil
  @State private var autoScroll: Task<Void, Never>? = nil
  @State private var viewportHeight: CGFloat = 0

  private var frames: DashboardLayout.Frames {
    Dictionary(panels.map { ($0.id, $0.frame) }, uniquingKeysWith: { first, _ in first })
  }

  var body: some View {
    GeometryReader { outer in
      ScrollView {
        GeometryReader { geometry in
          canvas(metrics: DashboardGridMetrics(width: geometry.size.width))
        }
        .frame(height: canvasHeight(width: outer.size.width))
        .background(macosDashboardScrollFinder(scroller: scroller))
        .padding(.bottom, 10)
      }
      .coordinateSpace(name: macosDashboardGridSpace)
      .onAppear { viewportHeight = outer.size.height }
      .onChange(of: outer.size.height) { newValue in viewportHeight = newValue }
    }
    .onAppear { watchForEscape(isEditing) }
    .onChange(of: isEditing) { newValue in
      watchForEscape(newValue)
      if !newValue {
        interaction = nil
      }
    }
    .onDisappear {
      endInteraction()
      watchForEscape(false)
    }
  }

  // MARK: - Layout

  /// Where each panel is shown: the layout being dragged towards, or as saved, or stacked in a narrow window
  private func shownFrames(metrics: DashboardGridMetrics) -> DashboardLayout.Frames {
    if metrics.isNarrow {
      return DashboardGridMetrics.stacked(panels)
    }
    guard let interaction = interaction, !interaction.cancelled else { return frames }
    return preview(interaction, metrics: metrics)
  }

  /// The layout if the drag ended now
  private func preview(_ interaction: Interaction, metrics: DashboardGridMetrics) -> DashboardLayout.Frames {
    let start = metrics.rect(interaction.start)
    switch interaction.mode {
    case .move:
      let cell = metrics.cell(nearest: CGPoint(x: start.minX + interaction.translation.width,
                                               y: start.minY + interaction.translation.height + interaction.scrolled))
      return DashboardLayout.move(interaction.original, id: interaction.id,
                                  to: DashboardGridFrame(x: cell.x, y: cell.y, w: interaction.start.w, h: interaction.start.h))
    case .resize:
      let size = resizedSize(interaction, metrics: metrics)
      let cells = metrics.cells(nearest: size)
      return DashboardLayout.resize(interaction.original, id: interaction.id,
                                    to: DashboardGridFrame(x: 0, y: 0, w: cells.w, h: cells.h))
    }
  }

  /// The size a panel being resized follows the pointer to, no smaller than the smallest panel and no wider than
  /// the grid
  private func resizedSize(_ interaction: Interaction, metrics: DashboardGridMetrics) -> CGSize {
    guard case .resize(let right, let bottom) = interaction.mode else { return .zero }
    let start = metrics.rect(interaction.start)
    let smallest = metrics.rect(DashboardGridFrame(x: 0, y: 0, w: DashboardLayout.minWidth, h: DashboardLayout.minHeight))
    let widest = CGFloat(metrics.width) - start.minX
    let tallest = CGFloat(DashboardLayout.height(rows: DashboardLayout.maxHeight))
    let width = right ? start.width + interaction.translation.width : start.width
    let height = bottom ? start.height + interaction.translation.height + interaction.scrolled : start.height
    return CGSize(width: min(max(width, smallest.width), widest),
                  height: min(max(height, smallest.height), tallest))
  }

  /// Tall enough for every panel, and while dragging some room below them to drag into
  private func canvasHeight(width: CGFloat) -> CGFloat {
    let metrics = DashboardGridMetrics(width: Double(width))
    var height = CGFloat(metrics.height(shownFrames(metrics: metrics)))
    if let interaction = interaction, !interaction.cancelled {
      height += CGFloat(DashboardLayout.height(rows: interaction.start.h)) + CGFloat(DashboardLayout.spacing)
    }
    return height
  }

  private func canvas(metrics: DashboardGridMetrics) -> some View {
    let shown = shownFrames(metrics: metrics)
    let active = interaction.flatMap { $0.cancelled ? nil : $0 }
    return ZStack(alignment: .topLeading) {
      // Where the panel being dragged will go when it's let go
      if let active = active, let target = shown[active.id] {
        let rect = metrics.rect(target)
        RoundedRectangle(cornerRadius: 5)
          .fill(Color("BackgroundAlt"))
          .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5))
          .frame(width: rect.width, height: rect.height)
          .offset(x: rect.minX, y: rect.minY)
          .allowsHitTesting(false)
          .animation(.easeOut(duration: 0.18), value: rect)
      }

      ForEach(panels) { item in
        let rect = displayRect(item, shown: shown, active: active, metrics: metrics)
        let isActive = active?.id == item.id
        panel(item, moveHandle(item, metrics: metrics))
          .frame(width: rect.width, height: rect.height)
          .overlay(alignment: .topLeading) {
            if isEditing && !metrics.isNarrow {
              resizeHandles(item, size: rect.size, metrics: metrics)
            }
          }
          .shadow(color: .black.opacity(isActive ? 0.25 : 0), radius: 8, y: 3)
          .offset(x: rect.minX, y: rect.minY)
          // The others glide out of the way; the one being dragged follows the pointer exactly
          .animation(isActive ? nil : .easeOut(duration: 0.18), value: rect)
          .zIndex(isActive ? 1 : 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// Where a panel is drawn. The one being moved follows the pointer and the one being resized follows it in size;
  /// the rest sit in their cells.
  private func displayRect(_ item: DashboardPanel,
                           shown: DashboardLayout.Frames,
                           active: Interaction?,
                           metrics: DashboardGridMetrics) -> CGRect {
    let frame = shown[item.id] ?? item.frame
    guard let active = active, active.id == item.id else { return metrics.rect(frame) }
    let start = metrics.rect(active.start)
    switch active.mode {
    case .move:
      return CGRect(x: start.minX + active.translation.width,
                    y: start.minY + active.translation.height + active.scrolled,
                    width: start.width, height: start.height)
    case .resize:
      return CGRect(origin: metrics.rect(frame).origin, size: resizedSize(active, metrics: metrics))
    }
  }

  // MARK: - Handles

  private func moveHandle(_ item: DashboardPanel, metrics: DashboardGridMetrics) -> macosDashboardMoveHandle {
    macosDashboardMoveHandle(isEnabled: isEditing && !metrics.isNarrow,
                             isMoving: interaction?.id == item.id && interaction?.mode == .move,
                             onChanged: { value in drag(item, mode: .move, value: value) },
                             onEnded: { end(metrics: metrics) })
  }

  /// The right edge, bottom edge and bottom right corner, which resize the panel when dragged
  private func resizeHandles(_ item: DashboardPanel, size: CGSize, metrics: DashboardGridMetrics) -> some View {
    let thickness: CGFloat = 8
    return ZStack(alignment: .topLeading) {
      macosDashboardResizeHandle(cursor: .resizeLeftRight)
        .frame(width: thickness, height: max(size.height - 2 * thickness, 0))
        .offset(x: size.width - thickness / 2, y: thickness)
        .gesture(resizeGesture(item, right: true, bottom: false, metrics: metrics))
      macosDashboardResizeHandle(cursor: .resizeUpDown)
        .frame(width: max(size.width - 2 * thickness, 0), height: thickness)
        .offset(x: thickness, y: size.height - thickness / 2)
        .gesture(resizeGesture(item, right: false, bottom: true, metrics: metrics))
      macosDashboardResizeHandle(cursor: macosDashboardResizeHandle.cornerCursor)
        .frame(width: 16, height: 16)
        .offset(x: size.width - 14, y: size.height - 14)
        .gesture(resizeGesture(item, right: true, bottom: true, metrics: metrics))
      // The arrows, level with the panel's footer and in line with its right edge
      macosDashboardResizeHandle(cursor: macosDashboardResizeHandle.cornerCursor, showsGrip: true)
        .frame(width: 20, height: 20)
        .offset(x: size.width - macosDashboardPanelView.padding - 15,
                y: size.height - macosDashboardPanelView.padding - macosDashboardPanelView.footerHeight / 2 - 10)
        .gesture(resizeGesture(item, right: true, bottom: true, metrics: metrics))
    }
  }

  private func resizeGesture(_ item: DashboardPanel, right: Bool, bottom: Bool,
                             metrics: DashboardGridMetrics) -> some Gesture {
    DragGesture(minimumDistance: 1, coordinateSpace: .named(macosDashboardGridSpace))
      .onChanged { value in drag(item, mode: .resize(right: right, bottom: bottom), value: value) }
      .onEnded { _ in end(metrics: metrics) }
  }

  // MARK: - Dragging

  private func drag(_ item: DashboardPanel, mode: Interaction.Mode, value: DragGesture.Value) {
    guard isEditing else { return }
    if interaction == nil {
      interaction = Interaction(id: item.id, mode: mode, original: frames, start: item.frame)
      scroller.startDrag()
      startAutoScroll()
    }
    guard var current = interaction, current.id == item.id, !current.cancelled else { return }
    current.translation = value.translation
    current.location = value.location
    interaction = current
  }

  private func end(metrics: DashboardGridMetrics) {
    defer { endInteraction() }
    guard let interaction = interaction, !interaction.cancelled else { return }
    let result = preview(interaction, metrics: metrics)
    if result != frames {
      onCommit(result)
    }
  }

  private func endInteraction() {
    withAnimation(.easeOut(duration: 0.18)) {
      interaction = nil
    }
    autoScroll?.cancel()
    autoScroll = nil
  }

  /// While editing, Esc puts every panel back mid-drag, or else ends edit mode
  private func watchForEscape(_ watching: Bool) {
    if let keyMonitor = keyMonitor {
      NSEvent.removeMonitor(keyMonitor)
      self.keyMonitor = nil
    }
    guard watching else { return }
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      // Esc in the dashboard's own window, not a popover such as Add Search, and not typing
      guard event.keyCode == 53,
            let window = event.window, window.isKeyWindow,
            !window.className.contains("Popover"),
            !(window.firstResponder is NSTextView) else { return event }
      if let current = interaction {
        if !current.cancelled {
          withAnimation(.easeOut(duration: 0.18)) {
            interaction?.cancelled = true
          }
        }
      } else {
        withAnimation(.easeOut(duration: 0.18)) {
          onDoneEditing()
        }
      }
      return nil
    }
  }

  /// Scrolls while the pointer is held near the top or bottom of the visible panels
  private func startAutoScroll() {
    autoScroll?.cancel()
    autoScroll = Task { @MainActor in
      let edge: CGFloat = 40
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 16_000_000)
        guard let current = interaction, !current.cancelled else { continue }
        let y = current.location.y
        var step: CGFloat = 0
        if y < edge {
          step = -min(edge - y, edge) / 2
        } else if y > viewportHeight - edge {
          step = min(y - (viewportHeight - edge), edge) / 2
        }
        if step != 0, let scrolled = scroller.scroll(by: step) {
          interaction?.scrolled = scrolled
        }
      }
    }
  }
}

/// An edge or corner of a panel that resizes it, showing the resize pointer on hover
struct macosDashboardResizeHandle: View {
  var cursor: NSCursor
  var showsGrip = false

  /// The diagonal resize pointer where there is one, macOS 15 and later
  static var cornerCursor: NSCursor {
    if #available(macOS 15, *) {
      return NSCursor.frameResize(position: .bottomRight, directions: .all)
    }
    return NSCursor.crosshair
  }

  @State private var hovering = false

  var body: some View {
    ZStack {
      Color.clear
      if showsGrip {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(Color(hovering ? "TextColor" : "TextSecondary"))
      }
    }
    .contentShape(Rectangle())
    .onHover { inside in
      hovering = inside
      if inside { cursor.push() } else { NSCursor.pop() }
    }
  }
}

/// The scroll view the panels are in, so a drag can scroll it
final class macosDashboardScroller {
  weak var scrollView: NSScrollView?
  private var startOffset: CGFloat = 0

  private var offset: CGFloat {
    scrollView?.contentView.bounds.origin.y ?? 0
  }

  func startDrag() {
    startOffset = offset
  }

  /// Scrolls by `step` points, no further than the ends. Returns how far it's scrolled since the drag started.
  func scroll(by step: CGFloat) -> CGFloat? {
    guard let scrollView = scrollView, let document = scrollView.documentView else { return nil }
    let clip = scrollView.contentView
    let limit = max(document.frame.height - clip.bounds.height, 0)
    var origin = clip.bounds.origin
    origin.y = min(max(origin.y + step, 0), limit)
    clip.scroll(to: origin)
    scrollView.reflectScrolledClipView(clip)
    return offset - startOffset
  }
}

/// Finds the scroll view it's placed in
struct macosDashboardScrollFinder: NSViewRepresentable {
  let scroller: macosDashboardScroller

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      scroller.scrollView = view.enclosingScrollView
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    if scroller.scrollView == nil {
      DispatchQueue.main.async {
        scroller.scrollView = nsView.enclosingScrollView
      }
    }
  }
}
#endif
