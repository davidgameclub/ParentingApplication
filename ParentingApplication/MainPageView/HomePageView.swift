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

// 用於包裝不同活動的 Identifiable 類型，方便編輯時查找
enum ActivityItem: Identifiable {
    case wakeup(WakeupActivity)
    case sleep(SleepActivity)
    
    var id: PersistentIdentifier {
        switch self {
        case .wakeup(let a): return a.persistentModelID
        case .sleep(let a): return a.persistentModelID
        }
    }
    
    var timestamp: Date {
        switch self {
        case .wakeup(let a): return a.timestamp
        case .sleep(let a): return a.timestamp
        }
    }
    
    var note: String {
        switch self {
        case .wakeup(let a): return a.note
        case .sleep(let a): return a.note
        }
    }
    
    var typeTitle: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺"
        }
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

// 2. 輔助視圖：單個小時的時間軸行 (僅包含格線與文字)
struct TimelineRowView: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // A. 時間標籤
            Text("\(event.hour):00")
                .font(.caption2)
                .frame(width: 45, alignment: .trailing)
                .foregroundColor(.gray)
                .padding(.trailing, 5)
                .offset(y: -7)
            
            // B. 右側內容區與橫線
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                
                Spacer()
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(4)
                        .padding(.leading, 10)
                }
                
                Spacer()
            }
        }
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
        .background(appDeepGray.ignoresSafeArea()) 
        .preferredColorScheme(.dark) 
        .onAppear { tempDate = appState.currentDate }
    }
}

// 3. 複雜的時間軸視圖
struct DailyTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var showDatePicker = false
    @State private var slideEdge: Edge = .trailing
    
    @Query private var wakeups: [WakeupActivity]
    @Query private var sleeps: [SleepActivity]
    
    // 用於開啟編輯視圖的狀態
    @State private var editingActivity: ActivityItem?
    
    private let hourHeight: CGFloat = 50.0
    private let timeLabelWidth: CGFloat = 50.0
    
    // 計算特定時間在 y 軸上的偏移量
    private func yOffset(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: date))
        let minute = CGFloat(calendar.component(.minute, from: date))
        return (hour * hourHeight) + (minute / 60.0 * hourHeight)
    }
    
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            return TimelineEvent(hour: hour, date: specificDate, description: "")
        }
    }

    // 計算當天的活動狀態區塊
    private var statusBlocks: [(start: CGFloat, end: CGFloat, color: Color)] {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(appState.currentDate, inSameDayAs: now)
        let nowY = yOffset(for: now)
        
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let todayWakeups = wakeups.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let todaySleeps = sleeps.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        
        let sorted = (todayWakeups.map { (t: $0.timestamp, s: "wakeup") } +
                      todaySleeps.map { (t: $0.timestamp, s: "sleep") })
                     .sorted { $0.t < $1.t }
        
        if sorted.isEmpty { return [] }
        
        var blocks: [(start: CGFloat, end: CGFloat, color: Color)] = []
        
        // 第一區塊：從 00:00 到第一個活動
        if let first = sorted.first {
            let startY = 0.0
            var endY = yOffset(for: first.t)
            
            // 如果是今天，不超過現在時間
            if isToday {
                endY = min(endY, nowY)
            }
            
            let color = (first.s == "wakeup") ? Color.white : Color.yellow
            if startY < endY {
                blocks.append((startY, endY, color))
            }
        }
        
        // 中間與結尾區塊
        for i in 0..<sorted.count {
            let current = sorted[i]
            let startY = yOffset(for: current.t)
            
            // 如果起始時間已經超過現在時間（且是今天），就不再畫色塊
            if isToday && startY >= nowY { break }
            
            var endY: CGFloat
            if i < sorted.count - 1 {
                endY = yOffset(for: sorted[i+1].t)
            } else {
                endY = 24 * hourHeight
            }
            
            // 如果是今天，結束時間不超過現在時間
            if isToday {
                endY = min(endY, nowY)
            }
            
            let color = (current.s == "wakeup") ? Color.yellow : Color.white
            if startY < endY {
                blocks.append((startY, endY, color))
            }
        }
        
        return blocks
    }

    // 取得當天具體的活動對象 (包含原始 Model 引用)
    private var todayActivityItems: [ActivityItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let w = wakeups.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.wakeup($0) }
        let s = sleeps.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.sleep($0) }

        return (w + s).sorted { $0.timestamp < $1.timestamp }
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
        let initialTime = calendar.component(.hour, from: Date())
        if let targetDate = calendar.date(bySettingHour: max(0, initialTime - 2), minute: 0, second: 0, of: appState.currentDate) {
            proxy.scrollTo(targetDate, anchor: .top)
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
                Button(action: { updateDate(offset: -1) }) { Image(systemName: "chevron.left").font(.title2) }
                .padding(.leading)
                
                Button(action: { showDatePicker = true }) {
                    Text(formattedDateString).font(.title2).bold().foregroundColor(.blue).frame(maxWidth: .infinity)
                }
                .sheet(isPresented: $showDatePicker) {
                    TimelineDatePickerSheet(isPresented: $showDatePicker)
                        .presentationDetents([.height(350), .medium])
                }
                
                Button(action: { updateDate(offset: 1) }) { Image(systemName: "chevron.right").font(.title2) }
                .padding(.trailing)
            }
            .padding(.vertical, 10)
            
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            let columnWidth = UIScreen.main.bounds.width / 4 - 10
                            
                            // 第一層：背景色塊
                            ForEach(0..<statusBlocks.count, id: \.self) { index in
                                let block = statusBlocks[index]
                                Rectangle()
                                    .fill(block.color.opacity(0.25))
                                    .frame(width: columnWidth, height: block.end - block.start)
                                    .offset(x: timeLabelWidth, y: block.start)
                            }

                            // 第二層：起床/睡覺方形按鈕標籤
                            ForEach(todayActivityItems) { item in
                                let isWakeup: Bool = {
                                    if case .wakeup = item { return true }
                                    return false
                                }()
                                
                                Button(action: {
                                    editingActivity = item
                                }) {
                                    Text(item.typeTitle)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(isWakeup ? Color.orange : Color.indigo)
                                        .classCornerRadius(4)
                                }
                                .offset(x: timeLabelWidth + (columnWidth / 2) - 15, y: yOffset(for: item.timestamp) - 10)
                            }

                            // 第三層：時間軸格線與活動
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(eventsForCurrentDate) { event in
                                    TimelineRowView(event: event)
                                        .id(event.date)
                                }
                            }
                            
                            // 第四層：NOW 指示線
                            if Calendar.current.isDate(appState.currentDate, inSameDayAs: Date()) {
                                HStack(spacing: 0) {
                                    ZStack(alignment: .trailing) {
                                        HStack(spacing: 2) {
                                            Text("NOW").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                                            Circle().fill(.red).frame(width: 6, height: 6)
                                        }
                                        .padding(.trailing, 2)
                                    }
                                    .frame(width: timeLabelWidth, alignment: .trailing)
                                    
                                    Rectangle().fill(Color.red.opacity(0.6)).frame(height: 2)
                                }
                                .offset(y: yOffset(for: Date()))
                            }
                        }
                    }
                    .background(Color.clear)
                    .onAppear { scrollToCurrentTime(proxy: proxy) }
                }
                .id(appState.currentDate)
                .transition(.asymmetric(insertion: .move(edge: slideEdge), removal: .move(edge: slideEdge == .leading ? .trailing : .leading)))
            }
            .clipped()
            .gesture(
                DragGesture().onEnded { value in
                    if value.translation.width > 50 { updateDate(offset: -1) }
                    else if value.translation.width < -50 { updateDate(offset: 1) }
                }
            )
        }
        .sheet(item: $editingActivity) { item in
            ActivityEditView(item: item) {
                editingActivity = nil
            }
            .presentationDetents([.medium])
        }
    }
}

// 指令編輯與刪除畫面
struct ActivityEditView: View {
    let item: ActivityItem
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var selectedTime: Date
    @State private var note: String
    
    init(item: ActivityItem, onDismiss: @escaping () -> Void) {
        self.item = item
        self.onDismiss = onDismiss
        // 初始化 State 為目前的資料內容
        _selectedTime = State(initialValue: item.timestamp)
        _note = State(initialValue: item.note)
    }
    
    private func saveChanges() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        let finalDate = calendar.date(from: combined) ?? selectedTime
        
        switch item {
        case .wakeup(let activity):
            activity.timestamp = finalDate
            activity.note = note
        case .sleep(let activity):
            activity.timestamp = finalDate
            activity.note = note
        }
        
        try? modelContext.save()
        onDismiss()
    }
    
    private func deleteActivity() {
        switch item {
        case .wakeup(let activity):
            modelContext.delete(activity)
        case .sleep(let activity):
            modelContext.delete(activity)
        }
        try? modelContext.save()
        onDismiss()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("編輯\(item.typeTitle)行程").font(.headline).padding(.top)
                
                DatePicker("時間", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                TextField("備註", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(role: .destructive, action: deleteActivity) {
                    HStack {
                        Image(systemName: "trash")
                        Text("刪除此紀錄")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .background(appDeepGray.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveChanges() }.fontWeight(.bold)
                }
            }
        }
    }
}

// 按鈕功能輸入頁面 (新增用)
@MainActor
struct ButtonDestinationView: View {
    let buttonCase: HomePageButtonCase
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedTime = Date()
    @State private var note: String = ""

    private func _ToAppDate(time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? Date()
    }

    var body: some View {
        VStack {
            if buttonCase == .wakeup || buttonCase == .sleep {
                VStack(spacing: 20) {
                    Text(buttonCase == .wakeup ? "新增起床時間" : "新增睡覺時間").font(.headline)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel).labelsHidden()
                    TextField("輸入備註...", text: $note).textFieldStyle(.roundedBorder).padding(.horizontal)
                }
                .padding()
            } else {
                Text("Detail for \(buttonCase.title)").padding()
            }
            
            Spacer()

            HStack {
                Button("Cancel") { onDismiss() }.buttonStyle(.bordered).tint(.gray)
                Button("Confirm") {
                    let finalDate = _ToAppDate(time: selectedTime)
                    if buttonCase == .wakeup {
                        modelContext.insert(WakeupActivity(timestamp: finalDate, note: note))
                    } else if buttonCase == .sleep {
                        modelContext.insert(SleepActivity(timestamp: finalDate, note: note))
                    }
                    try? modelContext.save()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(appDeepGray.ignoresSafeArea()) 
        .preferredColorScheme(.dark) 
    }
}

enum HomePageButtonCase: Int, Identifiable, CaseIterable{
    case wakeup = 1, sleep = 2, diaper = 3, growth = 5, setting = 6
    var id: Int { self.rawValue }
    var title: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺"
        case .diaper: return "尿布"
        case .growth: return "成長"
        case .setting: return "設定"
        }
    }
    var iconName: String {
        switch self {
        case .wakeup: return "sun.max.fill"
        case .sleep: return "moon.zzz.fill" 
        case .diaper: return "water.waves"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .setting: return "gearshape.fill"
        }
    }
    var color: Color {
        switch self {
        case .wakeup: return .orange
        case .sleep: return .indigo
        case .diaper: return .green
        case .growth: return .pink
        case .setting: return .gray
        }
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
                                    Ellipse()
                                        .fill(caseItem.color)
                                        .frame(width: 40, height: 12)
                                        .blur(radius: 8)
                                        .opacity(0.4)
                                        .offset(y: 25)
                                    
                                    Circle()
                                        .fill(caseItem.color)
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: caseItem.iconName)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            Text(caseItem.title).font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20) 
                .padding(.bottom, 20)
            }
            .frame(height: 140) 
        }
        .navigationTitle("Home")
        .background(appDeepGray.ignoresSafeArea()) 
        .preferredColorScheme(.dark) 
        .environment(appState)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(buttonCase: caseItem, onDismiss: { activeSheet = nil })
            .environment(appState)
            .presentationDetents([.medium, .large]) 
            .presentationDragIndicator(.visible)
        }
    }
}

// 輔助擴充以避免編譯警告
extension View {
    func classCornerRadius(_ radius: CGFloat) -> some View {
        self.cornerRadius(radius)
    }
}
