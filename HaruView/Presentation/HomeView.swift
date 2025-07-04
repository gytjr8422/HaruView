//
//  HomeView.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI
import CoreLocation

struct HomeView<VM: HomeViewModelProtocol>: View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.di) private var di
    @AppStorage("didShowDeleteHint") private var didShowHint = false
    @State private var showHint = false
    
    @StateObject private var vm: VM
    @StateObject private var permission = CalendarPermissionStore()
    
    @State private var showEventSheet: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var editingEvent: Event?
    @State private var editingReminder: Reminder?
    @State private var showToast: Bool = false
    @State private var adHeight: CGFloat = 0
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainContent
                toastOverlay
                if permission.isAllGranted {
                    deleteHintOverlay()
                }
            }
            .animation(.easeInOut, value: showHint)
        }
        .onAppear {
            if !didShowHint {
                showHint = true
            }
        }
        .modifier(DeletionUIViewModifier(vm: vm)) // 직접 modifier 사용
        .modifier(SheetsViewModifier(
            showEventSheet: $showEventSheet,
            showReminderSheet: $showReminderSheet,
            showAddSheet: $showAddSheet,
            editingEvent: $editingEvent,
            editingReminder: $editingReminder,
            showToast: $showToast,
            vm: vm,
            di: di
        ))
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        content
            .toolbar {
                dateView
                if permission.eventState == .granted && permission.reminderState == .granted {
                    addButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(hexCode: "FFFCF5"))
            .refreshable { vm.refresh(.userTap) }
            .task {
                await requestPermissions()
            }
            .onChange(of: phase) {
                if phase == .active { vm.refresh(.storeChange) }
            }
            .onChange(of: permission.isAllGranted) { _, isGranted in
                if isGranted {
                    vm.refresh(.storeChange)
                }
            }
            .animation(.easeInOut, value: permission.isAllGranted)
    }
    
    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        Group {
            if showToast {
                ToastView()
                    .animation(.easeInOut, value: showToast)
                    .transition(.opacity)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        ZStack {
            if vm.state.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            ScrollView(showsIndicators: false) {
                VStack {
                    if let tw = vm.weather {
                        WeatherCard(snapshot: tw.snapshot, place: tw.placeName)
                            .padding(.top, 5)
                    } else {
                        WeatherCard(snapshot: WeatherSnapshot(
                            temperature: 0,           // 섭씨 23.5도
                            humidity: 0,              // 65% 습도
                            precipitation: 0.0,          // 강수량 0mm
                            windSpeed: 0,              // 초속 3.2m 바람
                            condition: .mostlyClear,     // 대체로 맑음
                            symbolName: "sun.max",       // SF Symbol 이름
                            updatedAt: Date(),           // 현재 시간
                            hourlies: [],
                            tempMax: 0,
                            tempMin: 0
                        ), place: "로딩 중..")
                        .overlay {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                            
                    }
                    
                    weatherAttributionView
                    
                    if permission.isAllGranted {
                        eventListView
                        reminderListView
                    } else {
                        accessDeniedView
                    }
                    
                    if !showAddSheet {
                        // 네이티브 광고
                        NativeAdBanner(height: $adHeight)
                            .frame(maxWidth: .infinity)
                            .frame(height: adHeight == 0 ? 200 : adHeight)   // 로드 전엔 임시 높이
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
                            )
                            .padding(.top, 10)
                    }
                    
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private var eventListView: some View {
        
        HStack {
            Text("오늘의 일정")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.events.count > 4 {
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
            if vm.state.overview.events.isEmpty {
                emptyEventView
            } else {
                ForEach(vm.state.overview.events.prefix(5)) { event in
                    EventCard(event: event)
                        .contextMenu {
                             Button {
                                 if let root = UIApplication.shared.connectedScenes
                                     .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                                     .first?.rootViewController {
                                     AdManager.shared.show(from: root) {
                                         editingEvent = event
                                     }
                                 } else {
                                     editingEvent = event
                                 }
                             } label: {
                                 Label {
                                     Text("편집").font(Font.pretendardRegular(size: 14))
                                 } icon: {
                                     Image(systemName: "pencil")
                                 }
                             }
                             Button(role: .destructive) {
                                 vm.requestEventDeletion(event) // 새로운 스마트 삭제 메서드 사용
                             } label: {
                                 Label {
                                     Text("삭제").font(Font.pretendardRegular(size: 14))
                                 } icon: {
                                     Image(systemName: "trash")
                                 }
                             }
                         }
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var reminderListView: some View {
        HStack {
            Text("할 일")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.reminders.count > 5 {
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
            if vm.state.overview.reminders.isEmpty {
                emptyReminderView
            } else {
                ForEach(vm.state.overview.reminders.prefix(5)) { rem in
                    ReminderCard(reminder: rem) {
                        Task { await vm.toggleReminder(id: rem.id) }
                    }
                    .contextMenu {
                        Button {
                            editingReminder = rem
                        } label: {
                            Label {
                                Text("편집")
                                    .font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        Button(role: .destructive) {
                            Task {
                                await vm.deleteObject(.reminder(rem.id))
                            }
                        } label: {
                            Label {
                                Text("삭제")
                                    .font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "trash")
                            }

                        }
                    }
                    
                    if vm.state.overview.reminders.prefix(5).last != rem {
                        Divider()
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.1))
                    }
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
    
    private var weatherAttributionView: some View {
        HStack {
            Spacer()
            HStack(spacing: 5) {
                Link(" 날씨", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                    .font(.pretendardSemiBold (size: 11))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
            .padding([.bottom, .trailing], 8)
        }
    }
    
    
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if vm.state.error == nil {
                Button {
                    // 1) 광고가 있으면 먼저 보여주고
                    if let root = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first?.rootViewController {
                        AdManager.shared.show(from: root) {
                            // 2) 광고 닫힌 뒤 AddSheet 열기
                            showAddSheet = true
                        }
                    } else {
                        showAddSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color(hexCode: "A76545"))
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 25)
                        .padding(.vertical, 4)
                        .background(Color(hexCode: "C2966B").opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hexCode: "C2966B").opacity(0.09),
                                        lineWidth: 1)
                                .shadow(radius: 10)
                        }
                }
                .padding(.trailing, 6)
            }
        }
    }

    
    private var dateView: some ToolbarContent {
        let formatter = Locale.current.language.languageCode?.identifier == "ko"
        ? DateFormatterFactory.koreanDateWithDayFormatter()
        : DateFormatterFactory.englishDateWithDayFormatter()
        let dateStr = formatter.string(from: vm.today)
        
        return ToolbarItem(placement: .principal) {
            HStack {
                Text(dateStr)
                    .font(Locale.current.language.languageCode?.identifier == "ko" ? .museumMedium(size: 19) : .robotoSerifBold(size: 19))
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
    
    
    // MARK: - EmptyView
    private var emptyEventView: some View {
        HStack {
            Spacer()
            Text("오늘 일정이 없습니다.")
                .font(.pretendardSemiBold(size: 17))
                .padding(.vertical, 16)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hexCode: "FFFCF5"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
        )
    }
    
    private var emptyReminderView: some View {
        HStack {
            Spacer()
            Text("오늘 할 일이 없습니다.")
                .font(.pretendardSemiBold(size: 17))
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var accessDeniedView: some View {
        HStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                
                Text("오늘의 일정과 할 일을 보려면")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Text("캘린더와 미리알림 모두 접근 권한이 필요해요.")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Button("설정에서 권한 허용하기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func deleteHintOverlay() -> some View {
        if showHint {
            Color.black.opacity(0.55)       // Dim background
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                        Text("항목을 **길게 눌러** 수정/삭제할 수 있어요!")
                            .multilineTextAlignment(.center)
                            .font(.pretendardBold(size: 18))
                            .foregroundStyle(.white)
                        Button("확인") {
                            withAnimation { showHint = false; didShowHint = true }
                        }
                        .padding(.horizontal,32).padding(.vertical,10)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                    }
                )
                .transition(.opacity.combined(with: .scale))
        }
    }
    
    private func requestPermissions() async {
        // 1. 캘린더 권한 요청
        await permission.requestEvents()
        // 2. 미리알림 권한 요청
        await permission.requestReminders()
        
        // 권한이 모두 부여되었는지 확인
        if permission.isAllGranted {
            // 데이터 로드
            vm.load()
        }
    }
}

private struct ToastView: View {
    var body: some View {
        Text("저장이 완료되었습니다.")
            .font(.pretendardSemiBold(size: 14))
            .foregroundStyle(Color.white)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .opacity(0.85)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - ViewModifiers

private struct DeletionUIViewModifier<VM: HomeViewModelProtocol>: ViewModifier {
    @ObservedObject var vm: VM
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "반복 일정 삭제",
                isPresented: $vm.showRecurringDeletionOptions,
                titleVisibility: .visible
            ) {
                if vm.currentDeletingEvent != nil {
                    Button("이 이벤트만 삭제", role: .destructive) {
                        vm.deleteEventWithSpan(.thisEventOnly)
                    }
                    
                    Button("이후 모든 이벤트 삭제", role: .destructive) {
                        vm.deleteEventWithSpan(.futureEvents)
                    }
                    
                    Button("취소", role: .cancel) {
                        vm.cancelEventDeletion()
                    }
                }
            } message: {
                if let event = vm.currentDeletingEvent {
                    Text("'\(event.title)'은(는) 반복 일정입니다. 어떻게 삭제하시겠습니까?")
                }
            }
            .overlay {
                if vm.isDeletingEvent {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("삭제 중...")
                                .font(.pretendardSemiBold(size: 16))
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .transition(.opacity)
                }
            }
            .alert("삭제 오류", isPresented: .constant(vm.deletionError != nil)) {
                Button("확인") {
                    vm.deletionError = nil
                }
            } message: {
                if let error = vm.deletionError {
                    Text(error.description)
                }
            }
    }
}

private struct SheetsViewModifier<VM: HomeViewModelProtocol>: ViewModifier {
    @Binding var showEventSheet: Bool
    @Binding var showReminderSheet: Bool
    @Binding var showAddSheet: Bool
    @Binding var editingEvent: Event?
    @Binding var editingReminder: Reminder?
    @Binding var showToast: Bool
    
    @ObservedObject var vm: VM
    let di: DIContainer
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showEventSheet) {
                EventListSheet(vm: di.makeEventListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(isPresented: $showReminderSheet) {
                ReminderListSheet(vm: di.makeReminderListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(isPresented: $showAddSheet) {
                AddSheet(vm: di.makeAddSheetVM()) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                }
                .onDisappear { vm.refresh(.storeChange) }
            }
            .sheet(item: $editingEvent) { event in
                AddSheet(vm: di.makeEditSheetVM(event: event)) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    vm.refresh(.storeChange)
                }
            }
            .sheet(item: $editingReminder) { rem in
                AddSheet(vm: di.makeEditSheetVM(reminder: rem)) {
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    vm.refresh(.storeChange)
                }
            }
    }
}

// MARK: - Previews with Mock ViewModel
//#if DEBUG
//final class MockHomeVM: HomeViewModelProtocol {
//    
//    var weather: TodayWeather?
//    var weatherError: TodayBoardError?
//    
//    @Published var state: HomeState = {
//         var st = HomeState()
//         
//         // 테스트용 캘린더 정보
//         let testCalendar = EventCalendar(
//             id: "test-calendar",
//             title: "내 캘린더",
//             color: CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
//             type: .local,
//             isReadOnly: false,
//             allowsContentModifications: true,
//             source: EventCalendar.CalendarSource(
//                 title: "로컬",
//                 type: .local
//             )
//         )
//         
//         st.overview = TodayOverview(
//             events: [
//                 Event(
//                     id: "1111",
//                     title: "WWDC 컨퍼런스 참석",
//                     start: Calendar.current.startOfDay(for: Date()),
//                     end: Date.at(hour: 23, minute: 59)!,
//                     calendarTitle: "집",
//                     calendarColor: CGColor(gray: 0.9, alpha: 0.9),
//                     location: "Apple Campus",
//                     notes: "컨퍼런스 참석 및 네트워킹",
//                     url: URL(string: "https://developer.apple.com/wwdc"),
//                     hasAlarms: true,
//                     alarms: [
//                         EventAlarm(
//                             relativeOffset: -15 * 60, // 15분 전
//                             absoluteDate: nil,
//                             type: .display
//                         ),
//                         EventAlarm(
//                             relativeOffset: -60 * 60, // 1시간 전
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     hasRecurrence: false,
//                     recurrenceRule: nil,
//                     calendar: testCalendar,
//                     structuredLocation: EventStructuredLocation(
//                         title: "Apple Park",
//                         geoLocation: EventStructuredLocation.GeoLocation(
//                             latitude: 37.3349,
//                             longitude: -122.0090
//                         ),
//                         radius: 100.0
//                     )
//                 ),
//                 
//                 Event(
//                     id: "1113",
//                     title: "운동",
//                     start: Date(),
//                     end: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
//                     calendarTitle: "운동장",
//                     calendarColor: CGColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
//                     location: "헬스장",
//                     notes: nil,
//                     url: nil,
//                     hasAlarms: true,
//                     alarms: [
//                         EventAlarm(
//                             relativeOffset: -30 * 60, // 30분 전
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     hasRecurrence: true,
//                     recurrenceRule: EventRecurrenceRule(
//                         frequency: .weekly,
//                         interval: 1,
//                         endDate: nil,
//                         occurrenceCount: nil,
//                         daysOfWeek: [
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 2, weekNumber: nil), // 월
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 4, weekNumber: nil), // 수
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 6, weekNumber: nil)  // 금
//                         ],
//                         daysOfMonth: nil,
//                         weeksOfYear: nil,
//                         monthsOfYear: nil,
//                         setPositions: nil
//                     ),
//                     calendar: testCalendar,
//                     structuredLocation: nil
//                 ),
//                 
//                 Event(
//                     id: "1115",
//                     title: "코딩",
//                     start: Date(),
//                     end: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
//                     calendarTitle: "집",
//                     calendarColor: CGColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0),
//                     location: "집",
//                     notes: "SwiftUI 프로젝트 개발",
//                     url: URL(string: "https://github.com/myproject"),
//                     hasAlarms: false,
//                     alarms: [],
//                     hasRecurrence: true,
//                     recurrenceRule: EventRecurrenceRule(
//                         frequency: .daily,
//                         interval: 1,
//                         endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
//                         occurrenceCount: nil,
//                         daysOfWeek: nil,
//                         daysOfMonth: nil,
//                         weeksOfYear: nil,
//                         monthsOfYear: nil,
//                         setPositions: nil
//                     ),
//                     calendar: testCalendar,
//                     structuredLocation: nil
//                 ),
//                 
//                 Event(
//                     id: "1116",
//                     title: "공부하기",
//                     start: Date(),
//                     end: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
//                     calendarTitle: "집",
//                     calendarColor: CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0),
//                     location: "도서관",
//                     notes: "iOS 개발 서적 읽기",
//                     url: nil,
//                     hasAlarms: true,
//                     alarms: [
//                         EventAlarm(
//                             relativeOffset: -10 * 60, // 10분 전
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     hasRecurrence: false,
//                     recurrenceRule: nil,
//                     calendar: testCalendar,
//                     structuredLocation: EventStructuredLocation(
//                         title: "시립도서관",
//                         geoLocation: nil,
//                         radius: nil
//                     )
//                 ),
//                 
//                 Event(
//                     id: "1117",
//                     title: "친구 만나기",
//                     start: Date(),
//                     end: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
//                     calendarTitle: "카페",
//                     calendarColor: CGColor(red: 0.9, green: 0.4, blue: 0.9, alpha: 1.0),
//                     location: "스타벅스 강남점",
//                     notes: "오랜만에 만나는 대학 친구들",
//                     url: nil,
//                     hasAlarms: true,
//                     alarms: [
//                         EventAlarm(
//                             relativeOffset: -20 * 60, // 20분 전
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     hasRecurrence: false,
//                     recurrenceRule: nil,
//                     calendar: testCalendar,
//                     structuredLocation: EventStructuredLocation(
//                         title: "스타벅스 강남점",
//                         geoLocation: EventStructuredLocation.GeoLocation(
//                             latitude: 37.4979,
//                             longitude: 127.0276
//                         ),
//                         radius: 50.0
//                     )
//                 ),
//                 
//                 Event(
//                     id: "1118",
//                     title: "재택근무",
//                     start: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
//                     end: Calendar.current.date(byAdding: .hour, value: 6, to: Date())!,
//                     calendarTitle: "집",
//                     calendarColor: CGColor(red: 0.4, green: 0.4, blue: 0.8, alpha: 1.0),
//                     location: "집",
//                     notes: "프로젝트 회의 및 개발 업무",
//                     url: URL(string: "https://zoom.us/meeting/123456"),
//                     hasAlarms: true,
//                     alarms: [
//                         EventAlarm(
//                             relativeOffset: 0, // 시작 시간
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     hasRecurrence: true,
//                     recurrenceRule: EventRecurrenceRule(
//                         frequency: .weekly,
//                         interval: 1,
//                         endDate: nil,
//                         occurrenceCount: nil,
//                         daysOfWeek: [
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 2, weekNumber: nil), // 월
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 3, weekNumber: nil), // 화
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 4, weekNumber: nil), // 수
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 5, weekNumber: nil), // 목
//                             EventRecurrenceRule.RecurrenceWeekday(dayOfWeek: 6, weekNumber: nil)  // 금
//                         ],
//                         daysOfMonth: nil,
//                         weeksOfYear: nil,
//                         monthsOfYear: nil,
//                         setPositions: nil
//                     ),
//                     calendar: testCalendar,
//                     structuredLocation: nil
//                 )
//             ],
//             reminders: [
//                 Reminder(
//                     id: "1112",
//                     title: "원두 주문하기",
//                     due: nil,
//                     isCompleted: false,
//                     priority: 0,
//                     notes: nil,
//                     url: nil,
//                     location: nil,
//                     hasAlarms: false,
//                     alarms: [],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 ),
//                 Reminder(
//                     id: "1114",
//                     title: "약국 가기",
//                     due: Date(),
//                     isCompleted: true,
//                     priority: 1,
//                     notes: "처방전 가져가기",
//                     url: nil,
//                     location: "우리동네약국",
//                     hasAlarms: true,
//                     alarms: [
//                         ReminderAlarm(
//                             relativeOffset: -30 * 60,
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 ),
//                 Reminder(
//                     id: "1119",
//                     title: "미리보기",
//                     due: Date(),
//                     isCompleted: false,
//                     priority: 9,
//                     notes: "낮은 우선순위 작업",
//                     url: URL(string: "https://example.com"),
//                     location: nil,
//                     hasAlarms: false,
//                     alarms: [],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 ),
//                 Reminder(
//                     id: "1120",
//                     title: "책 읽기",
//                     due: nil,
//                     isCompleted: false,
//                     priority: 0,
//                     notes: "SwiftUI 관련 서적",
//                     url: nil,
//                     location: "도서관",
//                     hasAlarms: false,
//                     alarms: [],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 ),
//                 Reminder(
//                     id: "1121",
//                     title: "병원 가기",
//                     due: Date(),
//                     isCompleted: false,
//                     priority: 5,
//                     notes: "정기 검진 예약",
//                     url: nil,
//                     location: "서울대병원",
//                     hasAlarms: true,
//                     alarms: [
//                         ReminderAlarm(
//                             relativeOffset: -60 * 60,
//                             absoluteDate: nil,
//                             type: .display
//                         ),
//                         ReminderAlarm(
//                             relativeOffset: -24 * 60 * 60,
//                             absoluteDate: nil,
//                             type: .display
//                         )
//                     ],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 ),
//                 Reminder(
//                     id: "1122",
//                     title: "설거지 하기",
//                     due: nil,
//                     isCompleted: false,
//                     priority: 0,
//                     notes: nil,
//                     url: nil,
//                     location: "집",
//                     hasAlarms: false,
//                     alarms: [],
//                     calendar: ReminderCalendar(
//                        id: "test-reminder-calendar",
//                        title: "내 리마인더",
//                        color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
//                        type: .local,
//                        isReadOnly: false,
//                        allowsContentModifications: true,
//                        source: ReminderCalendar.CalendarSource(
//                            title: "로컬",
//                            type: .local
//                        )
//                    )
//                 )
//             ]
//        )
//        return st
//    }()
//    
//    var today: Date = Date()
//    
//    func load() {}
//    func refresh(_ kind: RefreshKind) {}
//    func toggleReminder(id: String) async { }
//    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async { }
//    func requestEventDeletion(_ event: Event) { }
//}
//
//private class MockEventRepository: EventRepositoryProtocol {
//    func fetchEvent() async -> Result<[Event], TodayBoardError> { .success([]) }
//    func add(_ input: EventInput) async -> Result<Void, TodayBoardError> { .success(()) }
//    func update(_ edit: EventEdit) async -> Result<Void, TodayBoardError> { .success(()) }
//    func deleteEvent(id: String) async -> Result<Void, TodayBoardError> { .success(()) }
//    func deleteEvent(id: String, span: EventDeletionSpan) async -> Result<Void, TodayBoardError> { .success(()) }
//}
//
//private class MockReminderRepository: ReminderRepositoryProtocol {
//    func fetchReminder() async -> Result<[Reminder], TodayBoardError> { .success([]) }
//    func add(_ input: ReminderInput) async -> Result<Void, TodayBoardError> { .success(()) }
//    func update(_ edit: ReminderEdit) async -> Result<Void, TodayBoardError> { .success(()) }
//    func toggle(id: String) async -> Result<Void, TodayBoardError> { .success(()) }
//    func deleteReminder(id: String) async -> Result<Void, TodayBoardError> { .success(()) }
//}
//
//#Preview {
//    HomeView(vm: MockHomeVM())
//}
//
//#endif
