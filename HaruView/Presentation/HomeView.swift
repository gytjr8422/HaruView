//
//  HomeView.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI

struct HomeView<VM: HomeViewModelProtocol>: View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.di) private var di
    @StateObject private var vm: VM
    
    @State private var showEventSheet: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var showAddSheet: Bool = false
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    dateView
                    addButton
                }
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(hexCode: "FFFCF5"))
                .sheet(isPresented: $showEventSheet) {
                    EventListSheet(vm: di.makeEventListVM())
                        .presentationDetents([.fraction(0.75), .fraction(1.0)])
                }
                .sheet(isPresented: $showReminderSheet) {
                    ReminderListSheet(vm: di.makeReminderListVM())
                        .presentationDetents([.fraction(0.75), .fraction(1.0)])
                }
                .sheet(isPresented: $showAddSheet) {
                    AddSheet(vm: di.makeAddSheetVM())
                        .onDisappear { vm.refresh(.storeChange) }
                        .presentationDetents([.fraction(0.6)])
                }
        }
        .task { vm.load() }
        .onChange(of: phase) {
            if phase == .active { vm.refresh(.storeChange) }
        }
        .refreshable { vm.refresh(.userTap) }
        
////        .onAppear {
//            for family in UIFont.familyNames {
//                print("Family: \(family)")
//                for name in UIFont.fontNames(forFamilyName: family) {
//                    print("    Font name: \(name)")
//                }
//            }
//        }
    }
    
    @ViewBuilder
    private var content: some View {
        if vm.state.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.state.error {
            VStack {
                Text("오류: \(error.localizedDescription)")
                Button("다시 시도") { vm.load() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                VStack {
                    WeatherCard(weather: vm.state.overview.weather)
                        .padding(.bottom, 16)
                    
                    HStack {
                        Text("오늘의 일정")
                            .font(.pretendardBold(size: 17))
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        if vm.state.overview.events.count > 2 {
                            Button {
                                showEventSheet.toggle()
                            } label: {
                                Text("전체 보기")
                                    .font(.jakartaRegular(size: 14))
                                    .foregroundStyle(Color(hexCode: "A76545"))
                            }
                        }
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(vm.state.overview.events.prefix(5)) { EventCard(event: $0)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    HStack {
                        Text("할 일")
                            .font(.pretendardBold(size: 17))
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        if vm.state.overview.reminders.count > 3 {
                            Button {
                                showReminderSheet.toggle()
                            } label: {
                                Text("전체 보기")
                                    .font(.jakartaRegular(size: 14))
                                    .foregroundStyle(Color(hexCode: "A76545"))
                            }
                        }
                    }
                    
                    VStack(spacing: 0) {
                        ForEach(vm.state.overview.reminders.prefix(5)) { rem in
                            ReminderCard(reminder: rem) {
                                Task { await vm.toggleReminder(id: rem.id) }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hexCode: "C2966B").opacity(0.09))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hexCode: "C2966B").opacity(0.5),
                                       lineWidth: 1)
                    )
                    
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showAddSheet.toggle() }) {
                Image(systemName: "plus")
                    .foregroundStyle(Color(hexCode: "A76545"))
                    .font(.pretendardSemiBold(size: 15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 3)
                    .overlay {
                        Capsule()
                            .stroke(Color(hexCode: "A76545").opacity(1),
                                   lineWidth: 2)
                    }
            }
            .padding(.trailing, 12)
        }
    }
    
    
    private var dateView: some ToolbarContent {
        let dateStr = DateFormatterFactory.koreanDateWithDayFormatter().string(from: vm.today)
        
        return ToolbarItem(placement: .principal) {
            HStack {
                Text(dateStr)
                    .font(.museumBold(size: 18))
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
}


struct EventCard: View {
    let event: Event
    private var isPast: Bool { event.end < Date() }
    
    var body: some View {
        HStack {
            Text(event.title)
                .lineLimit(1)
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(Color(hexCode: "40392B"))
                .strikethrough(isPast)
                .opacity(isPast ? 0.5 : 1)
            
            Spacer()
            
            // 조건부로 시간 표시
            if let timeText {
                Text(timeText)
                    .lineLimit(1)
                    .font(.jakartaRegular(size: 15))
                    .foregroundStyle(Color(hexCode: "2E2514").opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hexCode: "FFFCF5"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
        )
        
    }
    
    /// 세 가지 조건에 따라 출력할 문자열을 반환합니다.
    private var timeText: String? {
        let start = event.start
        let end   = event.end
        let startStr = formatted(start)
        let endStr   = formatted(end)
        
        // 1) 하루 종일 이벤트 (00:00–23:59) 감지
        let compsStart = Calendar.current.dateComponents([.hour, .minute], from: start)
        let compsEnd   = Calendar.current.dateComponents([.hour, .minute], from: end)
        let isFullDay = compsStart.hour == 0 && compsStart.minute == 0
                     && compsEnd.hour   == 23 && compsEnd.minute   == 59
        if isFullDay {
            return nil
        }
        
        // 2) 시작 == 종료 (분 단위) → 한 번만
        if Calendar.current.isDate(start, equalTo: end, toGranularity: .minute) {
            return startStr
        }
        
        // 3) 그 외 → "시작 – 종료"
        return "\(startStr) - \(endStr)"
    }
    
    private func formatted(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    let onToggle: () -> Void
    
    var priorityColor: Color {
        switch reminder.priority {
        case 1:
            return Color(hexCode: "FF5722")
        case 5:
            return Color(hexCode: "FFC107")
        case 9:
            return Color(hexCode: "4CAF50")
        default:
            return .secondary
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(reminder.isCompleted ? Color(hexCode: "A76545") : .secondary)
                .font(.custom("", size: 22))
                .onTapGesture { onToggle() }
                .animation(.smooth, value: 1)
                .padding(.trailing, 2)
            
            if reminder.priority > 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(priorityColor)
                    .opacity(reminder.isCompleted ? 0.5 : 1)
            }
            
            Text(reminder.title)
                .lineLimit(1)
                .font(.pretendardRegular(size: 17))
                .strikethrough(reminder.isCompleted)
                .opacity(reminder.isCompleted ? 0.5 : 1)
            Spacer()
            
            if let due = reminder.due {
                Text(DateFormatter.localizedString(from: due, dateStyle: .none, timeStyle: .short))
                    .lineLimit(1)
                    .font(.jakartaRegular(size: 15))
                    .foregroundStyle(Color(hexCode: "2E2514").opacity(0.8))
            }
        }
        .padding()
    }
}

private struct WeatherCard: View {
    let weather: Weather
    
    var body: some View {
        HStack {
            Image(systemName: iconName(for: weather.condition))
            Text("\(weather.temperature.value, specifier: "%.0f")°C – \(weather.condition.rawValue)")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
    
    private func iconName(for condition: Weather.Condition) -> String {
        switch condition { case .clear: "sun.max.fill"; case .cloudy: "cloud.fill"; case .rain: "cloud.rain.fill"; case .snow: "snow"; case .thunder: "cloud.bolt.rain.fill" }
    }
}

// MARK: - Previews with Mock ViewModel
#if DEBUG
final class MockHomeVM: HomeViewModelProtocol {
    
    @Published var state: HomeState = {
        var st = HomeState()
        st.overview = TodayOverview.placeholder
        return st
    }()
    var today: Date = Date()
    
    func load() {}
    func refresh(_ kind: RefreshKind) {}
    func toggleReminder(id: String) async { }
}

#Preview {
    HomeView(vm: MockHomeVM())
}

#endif
