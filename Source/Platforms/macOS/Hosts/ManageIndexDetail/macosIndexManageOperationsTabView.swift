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
  /// Number of concrete indices the name resolves to, more than one means an alias or data stream
  public var targetIndexCount: Int
  // Captured once so an invalidated Realm host is never read during a later render
  private let operationKey: DeleteOperationKey

  // Delete state lives in the tracker so it survives tab switches and navigation
  @ObservedObject private var tracker = IndexDeleteTaskTracker.shared

  // Confirmation state
  @State private var showDeleteAllAlert: Bool = false
  @State private var showDeleteByAgeAlert: Bool = false
  @State private var typedConfirmationKind: DeleteOperationKind? = nil
  @State private var typedConfirmationText: String = ""

  // Delete Documents by Age inputs
  @State private var selectedDateField: String = ""
  @State private var ageValue: Int = 30
  @State private var selectedPeriod: SearchDateTimePeriods = .Days

  public init(
    host: HostDetails,
    indexName: String,
    dateFields: [DateFieldInfo],
    currentDocCount: Int?,
    targetIndexCount: Int = 1
  ) {
    self.host = host
    self.indexName = indexName
    self.dateFields = dateFields
    self.currentDocCount = currentDocCount
    self.targetIndexCount = targetIndexCount
    self.operationKey = IndexDeleteTaskTracker.key(host: host, index: indexName)
  }

  private static let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  private let availablePeriods: [SearchDateTimePeriods] = [
    .Hours, .Days, .Weeks, .Months, .Years
  ]

  private var currentOperation: DeleteOperation? {
    tracker.operations[operationKey]
  }

  private var isOperationActive: Bool {
    currentOperation?.state.isActive == true
  }

  private func operation(for kind: DeleteOperationKind) -> DeleteOperation? {
    guard let op = currentOperation, op.kind == kind else { return nil }
    return op
  }

  private var requiresTypedConfirmation: Bool {
    indexName.hasPrefix(".") || targetIndexCount > 1
  }

  private var typedConfirmationReason: String {
    if targetIndexCount > 1 {
      return "'\(indexName)' resolves to \(targetIndexCount) indices. Documents will be deleted from all of them."
    }
    return "'\(indexName)' is a hidden or system index. Deleting its documents can break the features that depend on it."
  }

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

  private var deleteAllConfirmationMessage: String {
    "Are you sure you want to permanently delete ALL documents from '\(indexName)'? The index mappings and settings will be preserved, but this operation cannot be undone."
  }

  private var deleteByAgeConfirmationMessage: String {
    "Are you sure you want to permanently delete documents where '\(selectedDateField)' is older than \(ageValue) \(selectedPeriod.rawValue.lowercased()) (before ~\(formattedCutoffDate)) from '\(indexName)'? This operation cannot be undone."
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        deleteAllDocumentsCard
        deleteDocumentsByAgeCard
      }
      .padding(.bottom, 8)
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
      Text(deleteAllConfirmationMessage)
    }
    .alert("Delete Documents by Age?", isPresented: $showDeleteByAgeAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Delete Documents", role: .destructive) {
        executeDeleteByAge()
      }
    } message: {
      Text(deleteByAgeConfirmationMessage)
    }
    .sheet(item: $typedConfirmationKind) { kind in
      typedConfirmationSheet(kind)
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

      if let op = operation(for: .all) {
        operationStatusView(op, activeLabel: "Deleting all documents")
      }

      if operation(for: .all)?.state.isActive != true {
        Button(action: {
          requestConfirmation(.all)
        }) {
          HStack(spacing: 6) {
            Image(systemName: "trash")
            Text("Delete All Documents")
          }
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Color("DeleteButtonText"))
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color("DeleteButtonRed"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isOperationActive)
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
            .labelsHidden()
            .frame(maxWidth: 300, alignment: .leading)
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
            .labelsHidden()
            .frame(width: 120, alignment: .leading)
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

          if operation(for: .byAge)?.state.isActive != true {
            Button(action: {
              requestConfirmation(.byAge)
            }) {
              HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete Documents by Age")
              }
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(Color("DeleteButtonText"))
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color("DeleteButtonAmber"))
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isOperationActive || selectedDateField.isEmpty || ageValue <= 0)
          }
        }
      }

      // Shown outside the inputs so a running delete stays visible even if the mapping changes
      if let op = operation(for: .byAge) {
        operationStatusView(op, activeLabel: "Deleting documents by age")
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  // MARK: - Operation Status

  @ViewBuilder
  private func operationStatusView(_ op: DeleteOperation, activeLabel: String) -> some View {
    switch op.state {
    case .submitting:
      HStack(spacing: 8) {
        ProgressView()
          .scaleEffect(0.7)
        Text("Starting delete...")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
      }

    case .running(_, let progress), .cancelling(_, let progress):
      let isCancelling: Bool = {
        if case .cancelling = op.state { return true }
        return false
      }()

      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          if let progress = progress, let total = progress.total, total > 0 {
            ProgressView(value: Double(min(progress.deleted ?? 0, total)), total: Double(total))
              .frame(maxWidth: 240)
            Text("Deleted \(formatDocCount(progress.deleted ?? 0)) of \(formatDocCount(total))")
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
          } else {
            ProgressView()
              .scaleEffect(0.7)
            Text("\(activeLabel)...")
              .font(.system(size: 12))
              .foregroundColor(Color("TextSecondary"))
          }

          Button(isCancelling ? "Cancelling..." : "Cancel") {
            tracker.cancel(operationKey)
          }
          .font(.system(size: 12))
          .disabled(isCancelling)
        }

        if let notice = op.notice {
          Text(notice)
            .font(.system(size: 11))
            .foregroundColor(.orange)
        }
      }

    case .finished(let result):
      resultRow(message: resultMessage(result), isError: !result.isSuccess)

    case .untracked(_, let message):
      resultRow(message: message, isError: true)
    }
  }

  private func resultRow(message: String, isError: Bool) -> some View {
    HStack(spacing: 6) {
      Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
        .foregroundColor(isError ? .orange : .green)
      Text(message)
        .font(.system(size: 12))
        .foregroundColor(isError ? .orange : .green)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }

  private func resultMessage(_ result: DeleteByQueryResult) -> String {
    guard result.isSuccess else {
      return result.errorMessage ?? "Failed to delete documents."
    }
    let tookStr = result.took.map { " in \($0)ms" } ?? ""
    return "Successfully deleted \(formatDocCount(result.deleted ?? 0)) documents\(tookStr)."
  }

  // MARK: - Typed Confirmation

  private func typedConfirmationSheet(_ kind: DeleteOperationKind) -> some View {
    let isMatch = typedConfirmationText == indexName

    return VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.red)
        Text(kind == .all ? "Delete All Documents?" : "Delete Documents by Age?")
          .font(.system(size: 15, weight: .semibold))
      }

      Text(kind == .all ? deleteAllConfirmationMessage : deleteByAgeConfirmationMessage)
        .font(.system(size: 12))
        .fixedSize(horizontal: false, vertical: true)

      Text(typedConfirmationReason)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.orange)
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading, spacing: 6) {
        Text("Type \(indexName) to confirm:")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
        TextField(indexName, text: $typedConfirmationText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 12, design: .monospaced))
          .disableAutocorrection(true)
      }

      HStack {
        Spacer()
        Button("Cancel") {
          typedConfirmationKind = nil
        }
        .keyboardShortcut(.cancelAction)

        Button(kind == .all ? "Delete All Documents" : "Delete Documents") {
          typedConfirmationKind = nil
          switch kind {
          case .all:
            executeDeleteAll()
          case .byAge:
            executeDeleteByAge()
          }
        }
        .foregroundColor(.red)
        .disabled(!isMatch)
      }
    }
    .padding(20)
    .frame(width: 440)
  }

  // MARK: - Actions

  private func requestConfirmation(_ kind: DeleteOperationKind) {
    guard !isOperationActive else { return }
    tracker.clear(operationKey)

    if requiresTypedConfirmation {
      typedConfirmationText = ""
      typedConfirmationKind = kind
      return
    }

    switch kind {
    case .all:
      showDeleteAllAlert = true
    case .byAge:
      showDeleteByAgeAlert = true
    }
  }

  private func executeDeleteAll() {
    let index = indexName
    tracker.start(kind: .all, host: host, index: index) { detachedHost in
      await IndexManagementService.deleteAllDocuments(serverDetails: detachedHost, index: index)
    }
  }

  private func executeDeleteByAge() {
    guard !selectedDateField.isEmpty else { return }

    let index = indexName
    let dateField = selectedDateField
    let expr = dateMathExpression
    tracker.start(kind: .byAge, host: host, index: index) { detachedHost in
      await IndexManagementService.deleteDocumentsByAge(
        serverDetails: detachedHost,
        index: index,
        dateField: dateField,
        dateMathExpression: expr
      )
    }
  }

  private func formatDocCount(_ count: Int) -> String {
    Self.decimalFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
  }
}
#endif
