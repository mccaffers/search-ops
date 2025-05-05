// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosCalendarView: View {
  
  private let calendar: Calendar
  private let monthFormatter: DateFormatter
  private let dayFormatter: DateFormatter
  private let weekDayFormatter: DateFormatter
  private let fullFormatter: DateFormatter
  
  @Binding var selectedDate : Date
//  private static var now = Date() // Cache now

  internal init(calendar: Calendar, selectedDate: Binding<Date>) {
    self.calendar = calendar
    self.monthFormatter = DateFormatter(dateFormat: "MMMM YYYY", calendar: calendar)
    self.dayFormatter = DateFormatter(dateFormat: "d", calendar: calendar)
    self.weekDayFormatter = DateFormatter(dateFormat: "EEEEE", calendar: calendar)
    self.fullFormatter = DateFormatter(dateFormat: "MMMM dd, yyyy", calendar: calendar)
    self._selectedDate = selectedDate
  }
  
  var body: some View {
    VStack(spacing:0) {
      CalendarView(
        calendar: calendar,
        date: $selectedDate,
        content: { date in
          Button {
            let selectedHour = Calendar.current.component(.hour, from: selectedDate)
            selectedDate = Calendar.current.date(bySettingHour: selectedHour, minute: 0, second: 0, of: date)!
          } label: {
            Text("00")
              .padding(8)
              .foregroundColor(.clear)
              .background(
                calendar.isDate(date, inSameDayAs: selectedDate) ? Color("CalendarSelection")
                : calendar.isDateInToday(date) ? Color("Button")
                : Color("Button").opacity(0.5)
              )
              .cornerRadius(5)
              .accessibilityHidden(true)
              .overlay(
                Text(dayFormatter.string(from: date))
                  .foregroundColor(.white)
              )
          }.buttonStyle(PlainButtonStyle())
          
        },
        trailing: { date in
          Text(dayFormatter.string(from: date))
            .foregroundColor(.secondary)
        },
        header: { date in
          Text(weekDayFormatter.string(from: date))
        },
        title: { date in
          HStack {
            Button {
              guard let newDate = calendar.date(
                byAdding: .month,
                value: -1,
                to: selectedDate
              ) else {
                return
              }
              selectedDate = newDate
            } label: {
              Image(systemName: "chevron.left")
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(Color("Button").opacity(0.4))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            Text(monthFormatter.string(from: date))
            Spacer()
            
            Button {
              guard let newDate = calendar.date(
                byAdding: .month,
                value: 1,
                to: selectedDate
              ) else {
                return
              }
              selectedDate = newDate
            } label: {
              Image(systemName: "chevron.right")
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(Color("Button").opacity(0.4))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
          }.padding(.bottom, 5)
        }
      )
      .equatable()
    }
  }
}

// MARK: - Component

public struct CalendarView<Day: View, Header: View, Title: View, Trailing: View>: View {
    // Injected dependencies
    private var calendar: Calendar
    @Binding private var date: Date
    private let content: (Date) -> Day
    private let trailing: (Date) -> Trailing
    private let header: (Date) -> Header
    private let title: (Date) -> Title

    // Constants
    private let daysInWeek = 7

    public init(
        calendar: Calendar,
        date: Binding<Date>,
        @ViewBuilder content: @escaping (Date) -> Day,
        @ViewBuilder trailing: @escaping (Date) -> Trailing,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder title: @escaping (Date) -> Title
    ) {
        self.calendar = calendar
        self._date = date
        self.content = content
        self.trailing = trailing
        self.header = header
        self.title = title
    }

    public var body: some View {
        let month = date.startOfMonth(using: calendar)
        let days = makeDays()

      return LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek)) {
            Section(header: title(month)) {
                ForEach(days.prefix(daysInWeek), id: \.self, content: header)
                ForEach(days, id: \.self) { date in
                    if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                      content(date)
                    } else {
                        trailing(date)
                    }
                }
            }
        }
    }
}

// MARK: - Conformances

extension CalendarView: Equatable {
    public static func == (lhs: CalendarView<Day, Header, Title, Trailing>, rhs: CalendarView<Day, Header, Title, Trailing>) -> Bool {
        lhs.calendar == rhs.calendar && lhs.date == rhs.date
    }
}

// MARK: - Helpers

private extension CalendarView {
    func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDays(for: dateInterval)
    }
}

private extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates = [dateInterval.start]

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }

            guard date < dateInterval.end else {
                stop = true
                return
            }

            dates.append(date)
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(
            for: dateInterval,
            matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }
}

private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? self
    }
}

private extension DateFormatter {
    convenience init(dateFormat: String, calendar: Calendar) {
        self.init()
        self.dateFormat = dateFormat
        self.calendar = calendar
    }
}

// MARK: - Previews

//#if DEBUG
//struct CalendarView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {


//            ContentView(calendar: Calendar(identifier: .gregorian))
//            ContentView(calendar: Calendar(identifier: .islamicUmmAlQura))
//            ContentView(calendar: Calendar(identifier: .hebrew))
//            ContentView(calendar: Calendar(identifier: .indian))
//        }
//    }
//}
//#endif
