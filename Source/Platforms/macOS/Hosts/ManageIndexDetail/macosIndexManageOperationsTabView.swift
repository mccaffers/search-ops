// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(macOS)

public struct macosIndexManageOperationsTabView: View {
  public var host: HostDetails
  public var indexName: String
  public var dateFields: [DateFieldInfo]
  public var currentDocCount: Int?
  public var onStatsUpdated: () -> Void

  // Operation 1: Delete All Documents state
  @State private var showDeleteAllAlert: Bool = false
  @State private var isDeletingAll: Bool = false
  @State private var deleteAllResultMessage: String? = nil
  @State private var deleteAllIsError: Bool = false

  // Operation 2: Delete Documents by Age state
  @State private var selectedDateField: String = ""
  @State private var ageValue: Int = 30
  @State private var selectedPeriod: SearchDateTimePeriods = .Days
  @State private var showDeleteByAgeAlert: Bool = false
  @State private var isDeletingByAge: Bool = false
  @State private var deleteByAgeResultMessage: String? = nil
  @State private var deleteByAgeIsError: Bool = false

  public init(
    host: HostDetails,
    indexName: String,
    dateFields: [DateFieldInfo],
    currentDocCount: Int?,
    onStatsUpdated: @escaping () -> Void
  ) {
    self.host = host
    self.indexName = indexName
    self.dateFields = dateFields
    self.currentDocCount = currentDocCount
    self.onStatsUpdated = onStatsUpdated
  }

  private let availablePeriods: [SearchDateTimePeriods] = [
    .Hours, .Days, .Weeks, .Months, .Years
  ]

  private var dateMathExpression: String {
    IndexAgeHelper.dateMathExpression(value: ageValue, period: selectedPeriod)
  }

  private var approximateCutoffDate: Date {
    IndexAgeHelper.calculateCutoffDate(value: ageValue, period: selectedPeriod)
  }

  private var formattedCutoffDate: String {
    IndexAgeHelper.formatCutoffDate(approximateCutoffDate)
  }

  private var rangeQueryPreview: String {
    IndexAgeHelper.buildRangeDeleteQuery(dateField: selectedDateField, dateMathExpression: dateMathExpression)
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        deleteAllDocumentsCard
        deleteDocumentsByAgeCard
      }
      .padding(.vertical, 8)
    }
    .onAppear {
      if selectedDateField.isEmpty, let firstField = dateFields.first {
        selectedDateField = firstField.name
      }
    }
    .onChange(of: dateFields) { newFields in
      if selectedDateField.isEmpty || !newFields.contains(where: { $0.name == selectedDateField }) {
        selectedDateField = newFields.first?.name ?? ""
      }
    }
    .alert("Delete All Documents?", isPresented: $showDeleteAllAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Delete All Documents", role: .destructive) {
        executeDeleteAll()
      }
    } message: {
      Text("Are you sure you want to permanently delete ALL documents from '\(indexName)'? The index mappings and settings will be preserved, but this operation cannot be undone.")
    }
    .alert("Delete Documents by Age?", isPresented: $showDeleteByAgeAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Delete Documents", role: .destructive) {
        executeDeleteByAge()
      }
    } message: {
      Text("Are you sure you want to permanently delete documents where '\(selectedDateField)' is older than \(ageValue) \(selectedPeriod.rawValue.lowercased()) (before ~\(formattedCutoffDate)) from '\(indexName)'? This operation cannot be undone.")
    }
  }

  // MARK: - Card 1: Delete All Documents

  @ViewBuilder
  private var deleteAllDocumentsCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "trash")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.red)
        Text("Delete All Documents")
          .font(.system(size: 15, weight: .medium))
        Spacer()
      }

      Text("Permanently deletes all documents from this index using _delete_by_query with a match_all query. Mappings, aliases, and settings remain untouched.")
        .font(.system(size: 12))
        .foregroundColor(Color("TextSecondary"))
        .fixedSize(horizontal: false, vertical: true)

      if let count = currentDocCount {
        HStack(spacing: 6) {
          Text("Current Documents:")
            .font(.system(size: 12))
            .foregroundColor(Color("TextSecondary"))
          Text(formatDocCount(count))
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
      }

      if let msg = deleteAllResultMessage {
        HStack(spacing: 6) {
          Image(systemName: deleteAllIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            .foregroundColor(deleteAllIsError ? .orange : .green)
          Text(msg)
            .font(.system(size: 12))
            .foregroundColor(deleteAllIsError ? .orange : .green)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
      }

      HStack {
        if isDeletingAll {
          HStack(spacing: 8) {
            ProgressView()
              .scaleEffect(0.7)
            Text("Deleting all documents...")
              .font(.system(size: 12))
              .foregroundColor(Color("TextSecondary"))
          }
        } else {
          Button(action: {
            deleteAllResultMessage = nil
            showDeleteAllAlert = true
          }) {
            HStack(spacing: 6) {
              Image(systemName: "trash")
              Text("Delete All Documents...")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
              RoundedRectangle(cornerRadius: 5)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(isDeletingAll || isDeletingByAge)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  // MARK: - Card 2: Delete Documents by Age

  @ViewBuilder
  private var deleteDocumentsByAgeCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        Image(systemName: "clock.arrow.circlepath")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.orange)
        Text("Delete Documents by Age")
          .font(.system(size: 15, weight: .medium))
        Spacer()
      }

      Text("Deletes documents where a specified date field is older than the configured cutoff window using Elasticsearch date math.")
        .font(.system(size: 12))
        .foregroundColor(Color("TextSecondary"))
        .fixedSize(horizontal: false, vertical: true)

      if dateFields.isEmpty {
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: "info.circle")
            .foregroundColor(Color("TextSecondary"))
            .font(.system(size: 14))
          Text("Index has no date fields. Document deletion by age requires at least one date or date_nanos field in the index mapping.")
            .font(.system(size: 12))
            .foregroundColor(Color("TextSecondary"))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
      } else {
        VStack(alignment: .leading, spacing: 12) {
          // Date Field Picker
          HStack(spacing: 10) {
            Text("Date Field:")
              .font(.system(size: 12, weight: .medium))
              .frame(width: 85, alignment: .leading)
            SwiftUI.Picker("", selection: $selectedDateField) {
              ForEach(dateFields, id: \.name) { df in
                HStack {
                  Text(df.name)
                  if df.isNanos {
                    Text("(nanos)")
                      .foregroundColor(Color("TextSecondary"))
                  }
                }
                .tag(df.name)
              }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 300)
          }

          // Age and Period Selection
          HStack(spacing: 10) {
            Text("Older than:")
              .font(.system(size: 12, weight: .medium))
              .frame(width: 85, alignment: .leading)

            HStack(spacing: 6) {
              TextField("Value", value: $ageValue, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12, design: .monospaced))
                .padding(4)
                .frame(width: 60)
                .background(Color("BackgroundFixedShadow"))
                .clipShape(RoundedRectangle(cornerRadius: 4))

              Stepper("", value: $ageValue, in: 1...9999)
                .labelsHidden()
            }

            SwiftUI.Picker("", selection: $selectedPeriod) {
              ForEach(availablePeriods, id: \.self) { p in
                Text(p.rawValue).tag(p)
              }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 120)
          }

          // Live Preview Box
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
              Image(systemName: "calendar")
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
              Text("Deletes documents older than ~\(formattedCutoffDate)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
            }

            HStack(spacing: 6) {
              Text("Date Math:")
                .font(.system(size: 10))
                .foregroundColor(Color("TextSecondary"))
              Text("lt: \(dateMathExpression)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
            }

            Text(rangeQueryPreview)
              .font(.system(size: 10, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(2)
              .padding(6)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color("Button"))
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }
          .padding(10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color("BackgroundFixedShadow"))
          .clipShape(RoundedRectangle(cornerRadius: 5))

          if let msg = deleteByAgeResultMessage {
            HStack(spacing: 6) {
              Image(systemName: deleteByAgeIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(deleteByAgeIsError ? .orange : .green)
              Text(msg)
                .font(.system(size: 12))
                .foregroundColor(deleteByAgeIsError ? .orange : .green)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("BackgroundFixedShadow"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
          }

          // Action Button
          HStack {
            if isDeletingByAge {
              HStack(spacing: 8) {
                ProgressView()
                  .scaleEffect(0.7)
                Text("Deleting documents older than \(ageValue) \(selectedPeriod.rawValue.lowercased())...")
                  .font(.system(size: 12))
                  .foregroundColor(Color("TextSecondary"))
              }
            } else {
              Button(action: {
                deleteByAgeResultMessage = nil
                showDeleteByAgeAlert = true
              }) {
                HStack(spacing: 6) {
                  Image(systemName: "trash")
                  Text("Delete Documents by Age...")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(isDeletingAll || isDeletingByAge || selectedDateField.isEmpty || ageValue <= 0)
            }
          }
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  // MARK: - Actions

  private func executeDeleteAll() {
    isDeletingAll = true
    deleteAllResultMessage = nil
    deleteAllIsError = false

    let detachedHost = host.generateCopy()
    Task {
      let result = await IndexManagementService.deleteAllDocuments(serverDetails: detachedHost, index: indexName)
      await MainActor.run {
        isDeletingAll = false
        if result.isSuccess {
          let formatter = NumberFormatter()
          formatter.numberStyle = .decimal
          let countStr = formatter.string(from: NSNumber(value: result.deleted ?? 0)) ?? "\(result.deleted ?? 0)"
          let tookStr = result.took != nil ? " in \(result.took!)ms" : ""
          deleteAllResultMessage = "Successfully deleted \(countStr) documents\(tookStr)."
          deleteAllIsError = false
          onStatsUpdated()
        } else {
          deleteAllResultMessage = result.errorMessage ?? "Failed to delete documents."
          deleteAllIsError = true
        }
      }
    }
  }

  private func executeDeleteByAge() {
    guard !selectedDateField.isEmpty else { return }
    isDeletingByAge = true
    deleteByAgeResultMessage = nil
    deleteByAgeIsError = false

    let dateField = selectedDateField
    let expr = dateMathExpression
    let detachedHost = host.generateCopy()

    Task {
      let result = await IndexManagementService.deleteDocumentsByAge(
        serverDetails: detachedHost,
        index: indexName,
        dateField: dateField,
        dateMathExpression: expr
      )
      await MainActor.run {
        isDeletingByAge = false
        if result.isSuccess {
          let formatter = NumberFormatter()
          formatter.numberStyle = .decimal
          let countStr = formatter.string(from: NSNumber(value: result.deleted ?? 0)) ?? "\(result.deleted ?? 0)"
          let tookStr = result.took != nil ? " in \(result.took!)ms" : ""
          deleteByAgeResultMessage = "Successfully deleted \(countStr) documents\(tookStr)."
          deleteByAgeIsError = false
          onStatsUpdated()
        } else {
          deleteByAgeResultMessage = result.errorMessage ?? "Failed to delete documents."
          deleteByAgeIsError = true
        }
      }
    }
  }

  private func formatDocCount(_ count: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
  }
}
#endif
