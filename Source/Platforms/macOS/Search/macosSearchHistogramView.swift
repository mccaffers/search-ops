// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import Charts

#if os(macOS)

/// Bar chart of the search's document counts over its time period, shown above the results.
struct macosSearchHistogramView: View {
  var histogram: SearchHistogram
  var searchIndicator: Bool
  /// Called with the window dragged across the bars, snapped to whole bars
  var onSelectRange: (Date, Date) -> Void = { _, _ in }
  /// The time period before the last zoom, shown as a button that goes back to it
  var backTitle: String? = nil
  var onBack: () -> Void = {}

  @AppStorage("macosSearchHistogramCollapsed") private var collapsed = false
  @State private var hoveredBucket: HistogramBucket?
  @State private var dragStart: Date?
  @State private var dragEnd: Date?
  @State private var escapeMonitor: Any?
  /// Set by Esc, ignores the rest of the drag until the mouse is released
  @State private var dragCancelled = false
  /// The window just released, kept on screen until its search comes back
  @State private var pendingSelection: HistogramSelection?

  /// The window being dragged, snapped to whole bars
  var dragSelection: HistogramSelection? {
    guard let dragStart = dragStart, let dragEnd = dragEnd else { return nil }
    return histogram.selection(from: dragStart, to: dragEnd)
  }

  /// The window being dragged, or the one being searched
  var shownSelection: HistogramSelection? {
    dragSelection ?? pendingSelection
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      header

      if !collapsed {
        chart
          .frame(height: 110)
          .opacity(searchIndicator ? 0.7 : 1)

        Text("\(histogram.field) per \(histogram.interval.title)")
          .font(.system(size: 11))
          .foregroundStyle(Color("TextSecondary"))
          .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color("BackgroundAlt"))
    .clipShape(.rect(cornerRadius: 5))
    .onDisappear {
      stopEscapeMonitor()
    }
    .onChange(of: searchIndicator) { searching in
      if !searching {
        pendingSelection = nil
      }
    }
    .onChange(of: histogram) { _ in
      pendingSelection = nil
    }
  }

  var header: some View {
    HStack(spacing: 6) {
      Button {
        collapsed.toggle()
      } label: {
        Image(systemName: collapsed ? "chevron.right" : "chevron.down")
          .font(.system(size: 10, weight: .semibold))
          .frame(width: 14, height: 14)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .help(collapsed ? "Show chart" : "Hide chart")

      Text(Self.rangeTitle(from: histogram.from, to: histogram.to))
        .font(.system(size: 11))
        .foregroundStyle(Color("TextSecondary"))

      if let backTitle = backTitle {
        Button {
          onBack()
        } label: {
          Label(backTitle, systemImage: "arrow.uturn.backward")
            .font(.system(size: 11))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(searchIndicator)
        .help("Go back to \(backTitle)")
      }

      Spacer()

      if searchIndicator {
        ProgressView()
          .controlSize(.mini)
      }

      if let selection = shownSelection {
        Text("\(Self.rangeTitle(from: selection.from, to: selection.to)): \(Self.countTitle(selection.count))")
          .font(.system(size: 11))
          .monospacedDigit()
      } else if let bucket = hoveredBucket {
        Text("\(Self.bucketTitle(bucket, interval: histogram.interval)): \(Self.countTitle(bucket.count))")
          .font(.system(size: 11))
          .monospacedDigit()
      } else {
        Text(Self.countTitle(histogram.totalCount))
          .font(.system(size: 11))
          .monospacedDigit()
      }
    }
  }

  var chart: some View {
    Chart(histogram.buckets) { bucket in
      bar(bucket)
    }
    .chartXScale(domain: chartDomain)
    .chartYAxis {
      AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
        AxisGridLine()
        AxisValueLabel {
          if let count = value.as(Double.self) {
            Text(SearchHistogram.shortCount(count))
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 6)) {
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: Self.axisFormat(span: histogram.to.timeIntervalSince(histogram.from),
                                               interval: histogram.interval))
      }
    }
    .chartOverlay { proxy in
      GeometryReader { geometry in
        let plotFrame = geometry[proxy.plotAreaFrame]
        ZStack(alignment: .topLeading) {
          if let selection = shownSelection,
             let startX = proxy.position(forX: selection.from),
             let endX = proxy.position(forX: selection.to) {
            Rectangle()
              .fill(Color.white.opacity(0.12))
              .overlay(
                Rectangle().stroke(Color.white.opacity(0.5), lineWidth: 1)
              )
              .frame(width: max(endX - startX, 1), height: plotFrame.height)
              .offset(x: plotFrame.minX + startX, y: plotFrame.minY)
              .allowsHitTesting(false)
          }

          Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
              switch phase {
              case .active(let location):
                guard dragStart == nil else { return }
                if let date = date(at: location.x, proxy: proxy, plotFrame: plotFrame) {
                  hoveredBucket = histogram.buckets.first { $0.start <= date && date < $0.end }
                } else {
                  hoveredBucket = nil
                }
              case .ended:
                hoveredBucket = nil
              }
            }
            .onHover { inside in
              if inside {
                NSCursor.crosshair.push()
              } else {
                NSCursor.pop()
              }
            }
            .gesture(
              DragGesture(minimumDistance: 4)
                .onChanged { value in
                  guard !searchIndicator, !dragCancelled else { return }
                  if dragStart == nil {
                    dragStart = date(at: value.startLocation.x, proxy: proxy, plotFrame: plotFrame)
                    hoveredBucket = nil
                    startEscapeMonitor()
                  }
                  dragEnd = date(at: value.location.x, proxy: proxy, plotFrame: plotFrame)
                }
                .onEnded { _ in
                  let selection = dragSelection
                  let cancelled = dragCancelled
                  endDrag()
                  dragCancelled = false
                  guard !cancelled, !searchIndicator, let selection = selection,
                        selection.from != histogram.from || selection.to != histogram.to else { return }
                  pendingSelection = selection
                  onSelectRange(selection.from, selection.to)
                }
            )
        }
      }
    }
  }

  /// The date under an x position in the chart overlay, kept inside the plot area
  func date(at x: CGFloat, proxy: ChartProxy, plotFrame: CGRect) -> Date? {
    let plotX = min(max(x - plotFrame.minX, 0), plotFrame.width)
    return proxy.value(atX: plotX)
  }

  /// Esc cancels a drag. The monitor only lives for the drag and swallows just that key
  func startEscapeMonitor() {
    stopEscapeMonitor()
    escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      guard event.keyCode == 53, dragStart != nil else { return event }
      endDrag()
      dragCancelled = true
      return nil
    }
  }

  func stopEscapeMonitor() {
    if let escapeMonitor = escapeMonitor {
      NSEvent.removeMonitor(escapeMonitor)
    }
    escapeMonitor = nil
  }

  func endDrag() {
    dragStart = nil
    dragEnd = nil
    stopEscapeMonitor()
  }

  func bar(_ bucket: HistogramBucket) -> some ChartContent {
    let gap = histogram.interval.seconds * 0.08
    // BarMark with xStart and xEnd draws a thin band at the count, so each bar is a rectangle up from zero
    return RectangleMark(xStart: .value("Start", bucket.start.addingTimeInterval(gap)),
                         xEnd: .value("End", bucket.end.addingTimeInterval(-gap)),
                         yStart: .value("Count", 0),
                         yEnd: .value("Count", bucket.count))
      .foregroundStyle(Color.accentColor.opacity(isHighlighted(bucket) ? 1 : 0.5))
  }

  /// Bars inside the dragged window, or the hovered bar, stand out from the rest
  func isHighlighted(_ bucket: HistogramBucket) -> Bool {
    if let selection = shownSelection {
      return bucket.end > selection.from && bucket.start < selection.to
    }
    return hoveredBucket == nil || hoveredBucket == bucket
  }

  /// The buckets line up with whole intervals, so the first and last can reach past the time period
  var chartDomain: ClosedRange<Date> {
    let start = min(histogram.buckets.first?.start ?? histogram.from, histogram.from)
    let end = max(histogram.buckets.last?.end ?? histogram.to, histogram.to)
    return start...max(end, start.addingTimeInterval(1))
  }
}

extension macosSearchHistogramView {

  /// The date is left off the end when both ends fall on the same day
  static func rangeTitle(from: Date, to: Date) -> String {
    let format = Date.FormatStyle(date: .abbreviated, time: .shortened)
    if Calendar.current.isDate(from, inSameDayAs: to) {
      return "\(from.formatted(format)) – \(to.formatted(date: .omitted, time: .shortened))"
    }
    return "\(from.formatted(format)) – \(to.formatted(format))"
  }

  static func countTitle(_ count: Int) -> String {
    count == 1 ? "1 hit" : "\(count.formatted()) hits"
  }

  static func bucketTitle(_ bucket: HistogramBucket, interval: HistogramInterval) -> String {
    if interval.seconds >= 86400 {
      return bucket.start.formatted(date: .abbreviated, time: .omitted)
    }
    if interval.seconds < 60 {
      return bucket.start.formatted(.dateTime.month(.abbreviated).day().hour().minute().second())
    }
    return bucket.start.formatted(date: .abbreviated, time: .shortened)
  }

  /// Times for short periods, then days, then months as the period grows
  static func axisFormat(span: TimeInterval, interval: HistogramInterval) -> Date.FormatStyle {
    if interval.seconds < 60 && span <= 3600 {
      return .dateTime.hour().minute().second()
    }
    if span <= 86400 {
      return .dateTime.hour().minute()
    }
    if span <= 3 * 86400 {
      return .dateTime.month(.abbreviated).day().hour()
    }
    if span <= 365 * 86400 {
      return .dateTime.month(.abbreviated).day()
    }
    return .dateTime.month(.abbreviated).year()
  }
}

#endif
