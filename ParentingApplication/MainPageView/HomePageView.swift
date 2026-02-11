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

// 用於計算位置的輔助結構
struct PositionedActivityItem: Identifiable {
    let id: PersistentIdentifier
    let item: ActivityItem
    let y: CGFloat
}

// 用於包裝不同活動的 Identifiable 類型
enum ActivityItem: Identifiable {
    case wakeup(WakeupActivity)
    case sleep(SleepActivity)
    case custom(CustomActivity)
    case feeding(FeedingBottleActivity)
    case diaper(DiaperActivity)
    
    var id: PersistentIdentifier {
        switch self {
        case .wakeup(let a): return a.persistentModelID
        case .sleep(let a): return a.persistentModelID
        case .custom(let a): return a.persistentModelID
        case .feeding(let a): return a.persistentModelID
        case .diaper(let a): return a.persistentModelID
        }
    }
    
    var timestamp: Date {
        switch self {
        case .wakeup(let a): return a.timestamp
        case .sleep(let a): return a.timestamp
        case .custom(let a): return a.timestamp
        case .feeding(let a): return a.timestamp
        case .diaper(let a): return a.timestamp
        }
    }
    
    var note: String {
        switch self {
        case .wakeup(let a): return a.note
        case .sleep(let a): return a.note
        case .custom(let a): return a.note
        case .feeding(let a): return a.note
        case .diaper(let a): return a.note
        }
    }
    
    var typeTitle: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺"
        case .custom(let a): return a.isStart ? "開始" : "結束"
        case .feeding: return "瓶餵"
        case .diaper: return "尿布"
        }
    }

    var buttonCase: HomePageButtonCase {
        switch self {
        case .wakeup: return .wakeup
        case .sleep: return .sleep
        case .custom: return .customActivity
        case .feeding: return .feeding
        case .diaper: return .diaper
        }
    }

    var attributeValue: String? {
        switch self {
        case .feeding(let a): return "\(a.volume)ml"
        case .diaper(let a): return a.type
        default: return nil
        }
    }

    var isDetailInstruction: Bool {
        switch self {
        case .feeding, .diaper: return true
        default: return false
        }
    }
    
    // 定義該項目在時間軸上的高度，用於計算碰撞
    var height: CGFloat {
        return isDetailInstruction ? 24 : 16
    }
}

//Command Object Class================================================================================

@Model
class WakeupActivity {
    var timestamp: Date
    var note: String
    init(timestamp : Date, note : String) { self.timestamp = timestamp; self.note = note }
}

@Model
class SleepActivity {
    var timestamp: Date
    var note: String
    init(timestamp : Date, note : String) { self.timestamp = timestamp; self.note = note }
}

@Model
class CustomActivity {
    var timestamp: Date
    var note: String
    var isStart: Bool
    init(timestamp : Date, note : String, isStart: Bool) { self.timestamp = timestamp; self.note = note; self.isStart = isStart }
}

@Model
class FeedingBottleActivity {
    var timestamp: Date
    var note: String
    var volume: Int
    init(timestamp : Date, note : String, volume : Int) { self.timestamp = timestamp; self.note = note; self.volume = volume }
}

@Model
class DiaperActivity {
    var timestamp: Date
    var note: String
    var type: String 
    init(timestamp : Date, note : String, type : String) { self.timestamp = timestamp; self.note = note; self.type = type }
}

//================================================================================

struct TimelineEvent: Identifiable {
    let id = UUID()
    let hour: Int
    let date: Date
    var description: String
}

struct TimelineRowView: View {
    let event: TimelineEvent
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(event.hour):00")
                .font(.caption2)
                .frame(width: 45, alignment: .trailing)
                .foregroundColor(.gray)
                .padding(.trailing, 5)
                .offset(y: -7)
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                Spacer()
            }
        }
        .frame(height: 50)
    }
}

struct ActivityDetailCard: View {
    let item: ActivityItem
    
    // 強制 24 小時制的格式化方法
    private var timeString: String {
        item.timestamp.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_GB")) // 使用英國 Locale 強制 24 小時制
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle().fill(item.buttonCase.color)
                Image(systemName: item.buttonCase.iconName).font(.system(size: 10)).foregroundColor(.white)
            }
            .frame(width: 24, height: 24)
            
            HStack(spacing: 8) {
                Text(item.typeTitle).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                if let attr = item.attributeValue {
                    Text(attr).font(.system(size: 10)).foregroundColor(.gray)
                }
                Spacer()
                
                // 顯示 24 小時制時間
                Text(timeString)
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color.white.opacity(0.1))
        }
        .cornerRadius(4)
        .frame(width: 150)
    }
}

struct TimelineDatePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var tempDate: Date = Date()
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消") { isPresented = false }.foregroundColor(.red)
                Spacer()
                Button("今天") { tempDate = Date() }.foregroundColor(.blue)
                Spacer()
                Button("確認") { appState.currentDate = tempDate; isPresented = false }.fontWeight(.bold).foregroundColor(.blue)
            }
            .padding()
            DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                .datePickerStyle(.wheel).labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW")).padding().layoutPriority(1)
        }
        .background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark)
        .onAppear { tempDate = appState.currentDate }
    }
}

struct DailyTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var showDatePicker = false
    @State private var slideEdge: Edge = .trailing
    
    @Query private var wakeups: [WakeupActivity]
    @Query private var sleeps: [SleepActivity]
    @Query private var customActivities: [CustomActivity]
    @Query private var feedings: [FeedingBottleActivity]
    @Query private var diapers: [DiaperActivity]
    
    @State private var editingActivity: ActivityItem?
    
    private let hourHeight: CGFloat = 50.0
    private let timeLabelWidth: CGFloat = 50.0
    
    private func yOffset(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: date))
        let minute = CGFloat(calendar.component(.minute, from: date))
        return (hour * hourHeight) + (minute / 60.0 * hourHeight)
    }

    // 計算並防止重疊的核心邏輯
    private var positionedActivityItems: [PositionedActivityItem] {
        let sortedItems = todayActivityItems
        var positioned: [PositionedActivityItem] = []
        
        // 分別追蹤三欄的最後底部位置 (Status, Custom, Instruction)
        var lastStatusBottom: CGFloat = -100
        var lastCustomBottom: CGFloat = -100
        var lastInstructionBottom: CGFloat = -100
        
        for item in sortedItems {
            let idealY = yOffset(for: item.timestamp)
            let h = item.height
            var finalY = idealY - (h / 2) // 預設以時間線為中心
            
            // 判斷屬於哪一欄並檢查碰撞，若疊到則往後推移
            if case .custom = item {
                if finalY < lastCustomBottom + 2 { finalY = lastCustomBottom + 2 }
                lastCustomBottom = finalY + h
            } else if item.isDetailInstruction {
                if finalY < lastInstructionBottom + 2 { finalY = lastInstructionBottom + 2 }
                lastInstructionBottom = finalY + h
            } else {
                if finalY < lastStatusBottom + 2 { finalY = lastStatusBottom + 2 }
                lastStatusBottom = finalY + h
            }
            
            positioned.append(PositionedActivityItem(id: item.id, item: item, y: finalY))
        }
        
        return positioned
    }
    
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            return TimelineEvent(hour: hour, date: specificDate, description: "")
        }
    }

    private var statusBlocks: [(start: CGFloat, end: CGFloat, color: Color)] {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(appState.currentDate, inSameDayAs: now)
        let nowY = yOffset(for: now)
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let todayWakeups = wakeups.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let todaySleeps = sleeps.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
        let sorted = (todayWakeups.map { (t: $0.timestamp, s: "wakeup") } + todaySleeps.map { (t: $0.timestamp, s: "sleep") }).sorted { $0.t < $1.t }
        if sorted.isEmpty { return [] }
        var blocks: [(start: CGFloat, end: CGFloat, color: Color)] = []
        if let first = sorted.first {
            let startY = 0.0
            var endY = yOffset(for: first.t)
            if isToday { endY = min(endY, nowY) }
            let color = (first.s == "wakeup") ? Color.white : Color.yellow
            if startY < endY { blocks.append((startY, endY, color)) }
        }
        for i in 0..<sorted.count {
            let current = sorted[i]
            let startY = yOffset(for: current.t)
            if isToday && startY >= nowY { break }
            var endY: CGFloat = (i < sorted.count - 1) ? yOffset(for: sorted[i+1].t) : 24 * hourHeight
            if isToday { endY = min(endY, nowY) }
            let color = (current.s == "wakeup") ? Color.yellow : Color.white
            if startY < endY { blocks.append((startY, endY, color)) }
        }
        return blocks
    }
    
    private var customActivityBlocks: [(start: CGFloat, end: CGFloat, color: Color)] {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(appState.currentDate, inSameDayAs: now)
        let nowY = yOffset(for: now)
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let todayCustom = customActivities.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.sorted { $0.timestamp < $1.timestamp }
        if todayCustom.isEmpty { return [] }
        var blocks: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var activeStart: CGFloat? = nil
        for activity in todayCustom {
            let currentY = yOffset(for: activity.timestamp)
            if activity.isStart { activeStart = currentY }
            else if let start = activeStart {
                var endY = currentY
                if isToday { endY = min(endY, nowY) }
                if start < endY { blocks.append((start, endY, Color.blue.opacity(0.3))) }
                activeStart = nil
            }
            if isToday && currentY >= nowY { break }
        }
        if let start = activeStart {
            var endY = 24 * hourHeight
            if isToday { endY = min(endY, nowY) }
            if start < endY { blocks.append((start, endY, Color.blue.opacity(0.3))) }
        }
        return blocks
    }

    private var todayActivityItems: [ActivityItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let w = wakeups.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.wakeup($0) }
        let s = sleeps.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.sleep($0) }
        let c = customActivities.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.custom($0) }
        let f = feedings.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.feeding($0) }
        let d = diapers.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }.map { ActivityItem.diaper($0) }
        return (w + s + c + f + d).sorted { $0.timestamp < $1.timestamp }
    }
    
    private func updateDate(offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: offset, to: appState.currentDate) {
            slideEdge = offset < 0 ? .leading : .trailing
            withAnimation(.easeInOut(duration: 0.3)) { appState.currentDate = calendar.startOfDay(for: newDate) }
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
        let year = calendar.component(.year, from: appState.currentDate), month = calendar.component(.month, from: appState.currentDate), day = calendar.component(.day, from: appState.currentDate), weekday = calendar.component(.weekday, from: appState.currentDate)
        let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
        return "\(year)年\(month)月\(day)日 \(weekdays[(weekday - 1) % 7])"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { updateDate(offset: -1) }) { Image(systemName: "chevron.left").font(.title2) }.padding(.leading)
                Button(action: { showDatePicker = true }) { Text(formattedDateString).font(.title2).bold().foregroundColor(.blue).frame(maxWidth: .infinity) }
                .sheet(isPresented: $showDatePicker) { TimelineDatePickerSheet(isPresented: $showDatePicker).presentationDetents([.height(350), .medium]) }
                Button(action: { updateDate(offset: 1) }) { Image(systemName: "chevron.right").font(.title2) }.padding(.trailing)
            }
            .padding(.vertical, 10)
            
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            let columnWidth = UIScreen.main.bounds.width / 4 - 10
                            let customBlockWidth = columnWidth * 0.6 // 修改處：將 3/4 改為 3/5
                            
                            // 第一層：背景區塊
                            ForEach(0..<statusBlocks.count, id: \.self) { index in
                                let block = statusBlocks[index]
                                Rectangle().fill(block.color.opacity(0.25)).frame(width: columnWidth, height: block.end - block.start).offset(x: timeLabelWidth, y: block.start)
                            }
                            ForEach(0..<customActivityBlocks.count, id: \.self) { index in
                                let block = customActivityBlocks[index]
                                Rectangle().fill(block.color).frame(width: customBlockWidth, height: block.end - block.start).offset(x: timeLabelWidth + columnWidth, y: block.start)
                            }

                            // 第二層：已計算好位置的活動項目
                            ForEach(positionedActivityItems) { pos in
                                let item = pos.item
                                let isInstruction = item.isDetailInstruction
                                let labelX: CGFloat = {
                                    if case .custom = item { return timeLabelWidth + columnWidth + (customBlockWidth / 2) - 15 }
                                    if isInstruction { return timeLabelWidth + columnWidth + customBlockWidth + 10 }
                                    return timeLabelWidth + (columnWidth / 2) - 15
                                }()
                                
                                Button(action: { editingActivity = item }) {
                                    if isInstruction {
                                        ActivityDetailCard(item: item)
                                    } else {
                                        Text(item.typeTitle).font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(item.buttonCase.color).classCornerRadius(4)
                                    }
                                }
                                .offset(x: labelX, y: pos.y)
                            }

                            // 第三層：格線
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(eventsForCurrentDate) { event in
                                    TimelineRowView(event: event).id(event.date)
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
            .gesture(DragGesture().onEnded { value in
                if value.translation.width > 50 { updateDate(offset: -1) }
                else if value.translation.width < -50 { updateDate(offset: 1) }
            })
        }
        .sheet(item: $editingActivity) { item in
            ActivityEditView(item: item) { editingActivity = nil }.presentationDetents([.medium])
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
    @State private var isStart: Bool = true
    @State private var volume: Int = 50 
    @State private var diaperType: String = "濕" 
    
    init(item: ActivityItem, onDismiss: @escaping () -> Void) {
        self.item = item
        self.onDismiss = onDismiss
        _selectedTime = State(initialValue: item.timestamp)
        _note = State(initialValue: item.note)
        switch item {
        case .custom(let activity): _isStart = State(initialValue: activity.isStart)
        case .feeding(let activity): _volume = State(initialValue: activity.volume)
        case .diaper(let activity): _diaperType = State(initialValue: activity.type)
        default: break
        }
    }
    
    private func saveChanges() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var combined = DateComponents()
        combined.year = dateComponents.year; combined.month = dateComponents.month; combined.day = dateComponents.day; combined.hour = timeComponents.hour; combined.minute = timeComponents.minute
        let finalDate = calendar.date(from: combined) ?? selectedTime
        
        switch item {
        case .wakeup(let activity): activity.timestamp = finalDate; activity.note = note
        case .sleep(let activity): activity.timestamp = finalDate; activity.note = note
        case .custom(let activity): activity.timestamp = finalDate; activity.note = note; activity.isStart = isStart
        case .feeding(let activity): activity.timestamp = finalDate; activity.note = note; activity.volume = volume
        case .diaper(let activity): activity.timestamp = finalDate; activity.note = note; activity.type = diaperType
        }
        try? modelContext.save(); onDismiss()
    }
    
    private func deleteActivity() {
        switch item {
        case .wakeup(let activity): modelContext.delete(activity)
        case .sleep(let activity): modelContext.delete(activity)
        case .custom(let activity): modelContext.delete(activity)
        case .feeding(let activity): modelContext.delete(activity)
        case .diaper(let activity): modelContext.delete(activity)
        }
        try? modelContext.save(); onDismiss()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("編輯紀錄").font(.headline).padding(.top)
                DatePicker("時間", selection: $selectedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden()
                if case .custom = item {
                    Toggle("活動狀態：\(isStart ? "開始" : "結束")", isOn: $isStart).padding(.horizontal).padding(.vertical, 8).background(Color.white.opacity(0.05)).cornerRadius(8).padding(.horizontal)
                }
                if case .feeding = item {
                    VStack(alignment: .leading) {
                        Text("餵奶量：\(volume) ml").font(.subheadline).bold()
                        Slider(value: Binding(get: { Double(volume) }, set: { volume = Int($0) }), in: 0...400, step: 5)
                    }.padding(.horizontal)
                }
                if case .diaper = item {
                    VStack(alignment: .leading) {
                        Text("尿布類型").font(.subheadline).bold().padding(.leading)
                        Picker("Diaper Type", selection: $diaperType) { Text("濕").tag("濕"); Text("髒").tag("髒"); Text("混合").tag("混合") }.pickerStyle(.segmented).padding(.horizontal)
                    }
                }
                TextField("備註", text: $note).textFieldStyle(.roundedBorder).padding(.horizontal)
                Spacer()
                Button(role: .destructive, action: deleteActivity) {
                    HStack { Image(systemName: "trash"); Text("刪除此紀錄") }.frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).cornerRadius(10)
                }.padding(.horizontal)
            }
            .padding(.bottom).background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { onDismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("儲存") { saveChanges() }.fontWeight(.bold) }
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
    @State private var isStart: Bool = true 
    @State private var volume: Int = 50 
    @State private var diaperType: String = "濕"

    private func _ToAppDate(time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combined = DateComponents()
        combined.year = dateComponents.year; combined.month = dateComponents.month; combined.day = dateComponents.day; combined.hour = timeComponents.hour; combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? Date()
    }

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text("新增\(buttonCase.title)").font(.headline)
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden()
                if buttonCase == .customActivity {
                    Toggle(isOn: $isStart) { Text(isStart ? "標記為：開始" : "標記為：結束").fontWeight(.bold) }.toggleStyle(.button).tint(isStart ? .green : .red).padding(.bottom, 10)
                }
                if buttonCase == .feeding {
                    VStack(alignment: .leading) {
                        Text("奶量：\(volume) ml").font(.headline).foregroundColor(.white)
                        Slider(value: Binding(get: { Double(volume) }, set: { volume = Int($0) }), in: 0...400, step: 5).accentColor(.pink)
                    }.padding(.horizontal)
                }
                if buttonCase == .diaper {
                    VStack(alignment: .leading) {
                        Text("類型").font(.headline).foregroundColor(.white).padding(.leading)
                        Picker("Diaper Type", selection: $diaperType) { Text("濕").tag("濕"); Text("髒").tag("髒"); Text("混合").tag("混合") }.pickerStyle(.segmented).padding(.horizontal)
                    }
                }
                TextField("輸入備註...", text: $note).textFieldStyle(.roundedBorder).padding(.horizontal)
            }
            .padding()
            Spacer()
            HStack {
                Button("Cancel") { onDismiss() }.buttonStyle(.bordered).tint(.gray)
                Button("Confirm") {
                    let finalDate = _ToAppDate(time: selectedTime)
                    switch buttonCase {
                    case .wakeup: modelContext.insert(WakeupActivity(timestamp: finalDate, note: note))
                    case .sleep: modelContext.insert(SleepActivity(timestamp: finalDate, note: note))
                    case .customActivity: modelContext.insert(CustomActivity(timestamp: finalDate, note: note, isStart: isStart))
                    case .feeding: modelContext.insert(FeedingBottleActivity(timestamp: finalDate, note: note, volume: volume))
                    case .diaper: modelContext.insert(DiaperActivity(timestamp: finalDate, note: note, type: diaperType))
                    }
                    try? modelContext.save(); onDismiss()
                }.buttonStyle(.borderedProminent)
            }.padding()
        }
        .background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark) 
    }
}

enum HomePageButtonCase: Int, Identifiable, CaseIterable{
    case wakeup = 1, sleep = 2, customActivity = 3, feeding = 5, diaper = 6
    var id: Int { self.rawValue }
    var title: String {
        switch self {
        case .wakeup: return "起床"; case .sleep: return "睡覺"; case .customActivity: return "活動"; case .feeding: return "瓶餵"; case .diaper: return "尿布"
        }
    }
    var iconName: String {
        switch self {
        case .wakeup: return "sun.max.fill"; case .sleep: return "moon.zzz.fill"; case .customActivity: return "figure.run"; case .feeding: return "drop.fill"; case .diaper: return "water.waves"
        }
    }
    var color: Color {
        switch self {
        case .wakeup: return .orange; case .sleep: return .indigo; case .customActivity: return .green; case .feeding: return .pink; case .diaper: return .green
        }
    }
}

struct HomePageView: View {
    @State private var appState = AppState()
    @State private var activeSheet: HomePageButtonCase? = nil 
    var body: some View {
        VStack(spacing: 0) {
            DailyTimelineView().frame(height: 600) 
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(HomePageButtonCase.allCases, id: \.id) { caseItem in
                        VStack(spacing: 8) {
                            Button(action: { activeSheet = caseItem }) {
                                ZStack {
                                    Ellipse().fill(caseItem.color).frame(width: 40, height: 12).blur(radius: 8).opacity(0.4).offset(y: 25)
                                    Circle().fill(caseItem.color).frame(width: 60, height: 60)
                                    Image(systemName: caseItem.iconName).font(.title2).foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            Text(caseItem.title).font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
            .frame(height: 140) 
        }
        .navigationTitle("Home").background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark).environment(appState)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(buttonCase: caseItem, onDismiss: { activeSheet = nil }).environment(appState).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
    }
}

extension View {
    func classCornerRadius(_ radius: CGFloat) -> some View { self.cornerRadius(radius) }
}
