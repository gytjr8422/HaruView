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
            if phase == .active { vm.load() }
        }
        .refreshable { vm.refresh(.userTap) }
        
//        .onAppear {
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
            if error == .accessDenied {
                accessDeniedView
            } else {
                VStack {
                    Text("오류: \(error.localizedDescription)")
                    Button("다시 시도") { vm.load() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
                                        Button(role: .destructive) {
                                            Task {
                                                await vm.deleteObject(.event(event.id))
                                            }
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
                .padding(.horizontal, 20)
            }
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
    
    
    // MARK: - EmptyView-----------
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
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("캘린더·미리알림 접근 권한이 꺼져 있어\n앱을 사용할 수 없습니다.")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Button("설정에서 권한 허용하기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            Spacer()
        }
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
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async { }
}

#Preview {
    HomeView(vm: MockHomeVM())
}

#endif
