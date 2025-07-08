//
//  CalendarView.swift
//  HaruView
//
//  Created by 김효석 on 7/7/25.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.di) private var di
    @StateObject private var vm: CalendarViewModel
    @State private var showDayDetail = false
    @State private var selectedDayForDetail: CalendarDay?
    @State private var showAddSheet = false
    @State private var quickAddDate: Date?
    @State private var isDataReady = false
    
    init() {
        _vm = StateObject(wrappedValue: DIContainer.shared.makeCalendarViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexCode: "FFFCF5")
                    .ignoresSafeArea()
                
                if vm.isLoading && vm.currentMonthData == nil {
                    loadingView
                } else if let error = vm.error, vm.currentMonthData == nil {
                    errorView(error)
                } else if let monthData = vm.currentMonthData {
                    calendarContent(monthData)
                        .onAppear {
                            isDataReady = true
                        }
                } else {
                    emptyStateView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("달력")
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let dayData = selectedDayForDetail {
                if dayData.hasItems {
                    DayDetailSheet(calendarDay: dayData)
                } else {
                    EmptyView()
                        .onAppear {
                            print("빈 데이터 감지, Sheet 닫기")
                            showDayDetail = false
                            selectedDayForDetail = nil
                        }
                }
            } else {
                EmptyView()
                    .onAppear {
                        print("selectedDayForDetail이 nil, Sheet 닫기")
                        showDayDetail = false
                    }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let date = quickAddDate {
                QuickAddSheet(date: date) {
                    vm.refresh()
                }
            }
        }
    }
    
    @ViewBuilder
    private func calendarContent(_ monthData: CalendarMonth) -> some View {
        VStack(spacing: 0) {
            CalendarHeaderView(
                monthDisplayText: vm.monthDisplayText,
                onPreviousMonth: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.moveToPreviousMonth()
                    }
                },
                onNextMonth: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.moveToNextMonth()
                    }
                },
                onToday: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.moveToToday()
                    }
                }
            )
            
            WeekdayHeaderView()
            
            ScrollView {
                VStack(spacing: 0) {
                    CalendarGridView(
                        monthData: monthData,
                        selectedDate: vm.selectedDate,
                        onDateTap: { date in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.selectDate(date)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showDayDetailIfNeeded(for: date)
                            }
                        },
                        onDateLongPress: { date in
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            quickAddDate = date
                            showAddSheet = true
                        }
                    )
                    .transition(.opacity)
                    
                    Spacer(minLength: 20)
                }
            }
            .refreshable {
                vm.refresh()
            }
            
            if vm.isLoading && vm.currentMonthData != nil {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("업데이트 중...")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .transition(.opacity)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("달력을 불러오는 중...")
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(Color(hexCode: "6E5C49"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: TodayBoardError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("달력을 불러올 수 없습니다")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
            
            Text(error.description)
                .font(.pretendardRegular(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("다시 시도") {
                vm.refresh()
            }
            .font(.pretendardSemiBold(size: 16))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hexCode: "A76545"))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundStyle(Color(hexCode: "A76545"))
            
            Text("달력 데이터가 없습니다")
                .font(.pretendardSemiBold(size: 18))
                .foregroundStyle(Color(hexCode: "40392B"))
            
            Button("새로고침") {
                vm.loadCurrentMonth()
            }
            .font(.pretendardRegular(size: 16))
            .foregroundStyle(Color(hexCode: "A76545"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func showDayDetailIfNeeded(for date: Date) {
        guard vm.hasInitialDataLoaded,
              !vm.isLoading,
              let monthData = vm.currentMonthData,
              let calendarDay = monthData.day(for: date) else {
            print("데이터 조건 불충족")
            return
        }
        
        let eventCount = calendarDay.events.count
        let reminderCount = calendarDay.reminders.count
        let totalCount = eventCount + reminderCount
        
        print("날짜: \(date), 이벤트: \(eventCount)개, 리마인더: \(reminderCount)개, 총: \(totalCount)개")
        
        if totalCount > 0 {
            selectedDayForDetail = calendarDay
            showDayDetail = true
            print("Sheet 표시함")
        } else {
            print("일정 없음, Sheet 표시 안 함")
        }
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let calendarDay: CalendarDay
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            if calendarDay.events.isEmpty && calendarDay.reminders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hexCode: "A76545").opacity(0.5))
                    
                    Text("이 날에는 일정이 없습니다")
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hexCode: "FFFCF5"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            dismiss()
                        }
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(dateFormatter.string(from: calendarDay.date))
                            .font(.pretendardBold(size: 20))
                            .foregroundStyle(Color(hexCode: "40392B"))
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        if !calendarDay.events.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("일정")
                                    .font(.pretendardSemiBold(size: 18))
                                    .foregroundStyle(Color(hexCode: "40392B"))
                                    .padding(.horizontal, 20)
                                
                                ForEach(calendarDay.events, id: \.id) { event in
                                    EventDetailRow(event: event)
                                }
                            }
                        }
                        
                        if !calendarDay.reminders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("할일")
                                    .font(.pretendardSemiBold(size: 18))
                                    .foregroundStyle(Color(hexCode: "40392B"))
                                    .padding(.horizontal, 20)
                                
                                ForEach(calendarDay.reminders, id: \.id) { reminder in
                                    ReminderDetailRow(reminder: reminder)
                                }
                            }
                        }
                    }
                }
                .background(Color(hexCode: "FFFCF5"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            dismiss()
                        }
                        .font(.pretendardRegular(size: 16))
                        .foregroundStyle(Color(hexCode: "A76545"))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Event Detail Row
struct EventDetailRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(event.calendarColor))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "40392B"))
                
                if let timeText = event.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if event.isAllDay {
                    Text("하루 종일")
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if event.hasAlarms {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(event.calendarColor).opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Reminder Detail Row
struct ReminderDetailRow: View {
    let reminder: CalendarReminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .strikethrough(reminder.isCompleted)
                
                if let timeText = reminder.timeDisplayText {
                    Text(timeText)
                        .font(.pretendardRegular(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if reminder.priority > 0 {
                    HStack(spacing: 4) {
                        if let priorityColor = reminder.priorityColor {
                            Circle()
                                .fill(Color(priorityColor))
                                .frame(width: 8, height: 8)
                        }
                        Text(priorityText(reminder.priority))
                            .font(.pretendardRegular(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hexCode: "C2966B").opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 1: return "높은 우선순위"
        case 5: return "보통 우선순위"
        case 9: return "낮은 우선순위"
        default: return ""
        }
    }
}

// MARK: - Quick Add Sheet
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    let date: Date
    let onSave: () -> Void
    
    @State private var selectedType: QuickAddType = .event
    @State private var title: String = ""
    @State private var showFullAddSheet = false
    
    enum QuickAddType: String, CaseIterable {
        case event = "일정"
        case reminder = "할일"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(dateFormatter.string(from: date))
                    .font(.pretendardBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .padding(.top, 10)
                
                Picker("타입", selection: $selectedType) {
                    ForEach(QuickAddType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("제목")
                        .font(.pretendardSemiBold(size: 16))
                        .foregroundStyle(Color(hexCode: "40392B"))
                    
                    TextField("제목을 입력하세요", text: $title)
                        .font(.pretendardRegular(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("빠른 저장") {
                        saveQuickItem()
                    }
                    .font(.pretendardSemiBold(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hexCode: "A76545"))
                    .cornerRadius(8)
                    .disabled(title.isEmpty)
                    
                    Button("자세한 설정") {
                        showFullAddSheet = true
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hexCode: "A76545"), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(hexCode: "FFFCF5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("빠른 추가")
                        .font(.pretendardSemiBold(size: 18))
                        .foregroundStyle(Color(hexCode: "40392B"))
                }
            }
        }
        .sheet(isPresented: $showFullAddSheet) {
            AddSheet(vm: makePrefilledAddSheetVM()) {
                onSave()
                dismiss()
            }
        }
    }
    
    private func saveQuickItem() {
        Task {
            if selectedType == .event {
                await saveQuickEvent()
            } else {
                await saveQuickReminder()
            }
            
            await MainActor.run {
                onSave()
                dismiss()
            }
        }
    }
    
    private func saveQuickEvent() async {
        let startDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        
        let input = EventInput(
            title: title,
            start: startDate,
            end: endDate,
            location: nil,
            notes: nil,
            url: nil,
            alarms: [],
            recurrenceRule: nil,
            calendarId: nil
        )
        
        let addEventUseCase = di.makeAddEventUseCase()
        _ = await addEventUseCase(input)
    }
    
    private func saveQuickReminder() async {
        let input = ReminderInput(
            title: title,
            due: date,
            includesTime: false,
            priority: 0,
            notes: nil,
            url: nil,
            location: nil,
            alarms: [],
            calendarId: nil
        )
        
        let addReminderUseCase = di.makeAddReminderUseCase()
        _ = await addReminderUseCase(input)
    }
    
    private func makePrefilledAddSheetVM() -> AddSheetViewModel {
        let vm = di.makeAddSheetVM()
        vm.mode = selectedType == .event ? .event : .reminder
        vm.currentTitle = title
        
        if selectedType == .event {
            vm.startDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            vm.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: vm.startDate) ?? vm.startDate
        } else {
            vm.dueDate = date
        }
        
        return vm
    }
}

#Preview {
    CalendarView()
        .environment(\.di, .shared)
}
