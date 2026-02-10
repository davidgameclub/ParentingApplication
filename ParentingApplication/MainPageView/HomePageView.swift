//
//  HomePageView.swift
//  ParentingApplication_second
//
//  Created by Assistant on [Current Date].
//

import SwiftUI
import Foundation
import SwiftData
import Observation

// 全域顏色常數
let appDeepGray = Color(red: 0.12, green: 0.12, blue: 0.14)

// 全域狀態管理類別 (Global State Class)
@Observable
class AppState {
    var currentDate: Date
    
    init() {
        // 初始化為今天的 00:00
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.currentDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: today)!
    }
}

//Command Object Class================================================================================

@Model
class WakeupActivity {
    var timestamp: Date
    var note: String

    init(timestamp : Date, note : String) {
        self.timestamp = timestamp
        self.note = note
    }
}

@Model
class SleepActivity {
    var timestamp: Date
    var note: String

    init(timestamp : Date, note : String) {
        self.timestamp = timestamp
        self.note = note
    }
}

@Model
class FeedingBottleActivity {
    var timestamp: Date
    var note: String
    
    var volume: Int
    
    init(timestamp : Date, note : String, volume : Int) {
        self.timestamp = timestamp
        self.note = note
        self.volume = volume
    }
}

//================================================================================

// 1. 數據模型
struct TimelineEvent: Identifiable {
    let id = UUID()
    let hour: Int // 0 to 23
    let date: Date
    var description: String
}


// 2. 輔助視圖：單個小時的時間軸行
struct TimelineRowView: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top) {
            // 時間標籤 (左側)
            Text("\(event.hour):00")
                .font(.caption)
                .frame(width: 50, alignment: .trailing)
                .foregroundColor(.gray) // 改為淺灰色
                .padding(.trailing, 5)
            
            // 時間線和活動區 (右側)
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.15)) // 線條改為白色透明
                    .frame(height: 1)
                
                // 模擬活動內容區塊
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.white) // 文字改為白色
                    .padding(4)
                    .background(Color.green.opacity(0.3)) // 增加背景對比度
                    .cornerRadius(4)
                    .opacity(event.hour % 3 == 0 ? 1.0 : 0.0)
            }
        }
        .padding(.vertical, 5)
        .frame(height: 50)
    }
}

// 日期選擇器表單視圖
struct TimelineDatePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var tempDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消") { isPresented = false }
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("今天") { tempDate = Date() }
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button("確認") {
                    appState.currentDate = tempDate
                    isPresented = false
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .padding()
            
            DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
                .padding()
                .layoutPriority(1)
        }
        .background(appDeepGray.ignoresSafeArea()) // 設定深灰色背景
        .preferredColorScheme(.dark) // 強制深色模式，使選擇器變為白色文字
        .onAppear {
            tempDate = appState.currentDate
        }
    }
}

// 3. 複雜的時間軸視圖
struct DailyTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var showDatePicker = false
    @State private var slideEdge: Edge = .trailing
    
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            return TimelineEvent(hour: hour, date: specificDate, description: "Activity Log for \(hour):00")
        }
    }
    
    private func updateDate(offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: offset, to: appState.currentDate) {
            slideEdge = offset < 0 ? .leading : .trailing
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.currentDate = calendar.startOfDay(for: newDate)
            }
        }
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let initialTime = 5
        //let targetHour = calendar.component(.hour, from: Date())
        if let initialTime = calendar.date(bySettingHour: initialTime, minute: 0, second: 0, of: appState.currentDate) {
            proxy.scrollTo(initialTime, anchor: .top)
        }
    }
    
    private var formattedDateString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: appState.currentDate)
        let month = calendar.component(.month, from: appState.currentDate)
        let day = calendar.component(.day, from: appState.currentDate)
        let weekday = calendar.component(.weekday, from: appState.currentDate)
        let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
        return "\(year)年\(month)月\(day)日 \(weekdays[(weekday - 1) % 7])"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { updateDate(offset: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.leading)
                
                Button(action: { showDatePicker = true }) {
                    Text(formattedDateString)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                }
                .sheet(isPresented: $showDatePicker) {
                    TimelineDatePickerSheet(isPresented: $showDatePicker)
                        .presentationDetents([.height(350), .medium])
                        .presentationDragIndicator(.visible)
                }
                
                Button(action: { updateDate(offset: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 10)
            
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(eventsForCurrentDate) { event in
                                TimelineRowView(event: event)
                                    .id(event.date)
                            }
                        }
                    }
                    .background(Color.clear)
                    .onAppear {
                        scrollToCurrentTime(proxy: proxy)
                    }
                }
                .id(appState.currentDate)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge),
                    removal: .move(edge: slideEdge == .leading ? .trailing : .leading)
                ))
            }
            .clipped()
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50 
                        if value.translation.width > threshold { updateDate(offset: -1) }
                        else if value.translation.width < -threshold { updateDate(offset: 1) }
                    }
            )
        }
    }
}


// 按鈕列舉
enum HomePageButtonCase: Int, Identifiable, CaseIterable{
    case wakeup = 1
    case sleep = 2 // 修改：原本是 feeding，現在改為 sleep
    case diaper = 3
    case growth = 5
    case setting = 6
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺" // 修改標題
        case .diaper: return "尿布"
        case .growth: return "成長"
        case .setting: return "設定"
        }
    }
    
    var iconName: String {
        switch self {
        case .wakeup: return "sun.max.fill"
        case .sleep: return "moon.zzz.fill" // 修改圖示
        case .diaper: return "water.waves"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .setting: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .wakeup: return .orange
        case .sleep: return .indigo // 修改顏色以符合睡覺氛圍
        case .diaper: return .green
        case .growth: return .pink
        case .setting: return .gray
        }
    }
}

// 按鈕功能輸入頁面
@MainActor
struct ButtonDestinationView: View {
    let buttonCase: HomePageButtonCase
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedTime = Date()
    @State private var note: String = ""

    private func _ToAppDate(time: Date) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.timeZone = .current
        return calendar.date(from: combinedComponents)
    }

    private func saveWakeupAction() {
        let timestamp = _ToAppDate(time: selectedTime) ?? selectedTime
        let newActivity = WakeupActivity(timestamp: timestamp, note: note)
        modelContext.insert(newActivity)
        try? modelContext.save()
    }

    // 新增：睡覺活動的儲存函式
    private func saveSleepAction() {
        let timestamp = _ToAppDate(time: selectedTime) ?? selectedTime
        let newActivity = SleepActivity(timestamp: timestamp, note: note)
        modelContext.insert(newActivity)
        try? modelContext.save()
    }

    var body: some View {
        VStack {
            // 起床與睡覺共用相同的輸入 UI
            if buttonCase == .wakeup || buttonCase == .sleep {
                VStack(spacing: 20) {
                    Text(buttonCase == .wakeup ? "起床時間" : "睡覺時間")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    
                    TextField("輸入備註...", text: $note)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                Text("This is the detail page for \(buttonCase.title)")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
            
            Spacer()

            HStack {
                Button("Cancel") { onDismiss() }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                Button("Confirm") {
                    if buttonCase == .wakeup {
                        saveWakeupAction()
                    } else if buttonCase == .sleep {
                        saveSleepAction() // 呼叫睡覺儲存邏輯
                    }
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(appDeepGray.ignoresSafeArea()) // 設定深灰色背景
        .preferredColorScheme(.dark) // 確保輸入元件變為深色模式
    }
}


struct HomePageView: View {
    @State private var appState = AppState()
    @State private var activeSheet: HomePageButtonCase? = nil 

    var body: some View {
        VStack(spacing: 0) {
            DailyTimelineView()
                .frame(height: 600) 

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 25) {
                    ForEach(HomePageButtonCase.allCases, id: \.id) { caseItem in
                        VStack(spacing: 8) {
                            Button(action: { activeSheet = caseItem }) {
                                ZStack {
                                    Circle()
                                        .fill(caseItem.color)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: caseItem.iconName)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Text(caseItem.title)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20) 
            }
            .frame(height: 120) 
        }
        .navigationTitle("Home")
        .background(appDeepGray.ignoresSafeArea()) // 設定深灰色背景
        .preferredColorScheme(.dark) // 強制全域深色樣式
        .environment(appState)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(
                buttonCase: caseItem,
                onDismiss: { activeSheet = nil }
            )
            .environment(appState)
            .presentationDetents([.medium, .large]) 
            .presentationDragIndicator(.visible)
        }
    }
}

