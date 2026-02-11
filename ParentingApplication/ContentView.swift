//
//  ContentView.swift
//  ParentingApplication_second
//
//  Created by Michael on 2026/2/8.
//

import SwiftUI
import SwiftData

// 1. SwiftData 模型
@Model
final class UserProfile {
    var name: String
    var gender: String
    var birthDate: Date
    var createdAt: Date
    
    init(name: String, gender: String, birthDate: Date) {
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.createdAt = Date()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    
    @State private var name: String = ""
    @State private var navigateToGender = false
    @State private var showCelebration = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                
                Group {
                    if let profile = profiles.first {
                        List {
                            Section("寶寶資料") {
                                LabeledContent("暱稱", value: profile.name)
                                LabeledContent("性別", value: profile.gender)
                                // 使用指定的 Locale 確保日期顯示為「年月日」中文格式
                                LabeledContent("生日", value: profile.birthDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                            }
                            
                            Section {
                                NavigationLink {
                                    MainMenuView()
                                } label: {
                                    Text("進入主選單")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            Section {
                                Button(role: .destructive) {
                                    deleteProfile(profile)
                                } label: {
                                    Text("刪除並重新建立")
                                        .frame(maxWidth: .infinity)
                                }
                            } footer: {
                                Text("若要修改資料，您必須先刪除目前的檔案。")
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        VStack(spacing: 0) {
                            // 頂部灰色色塊
                            HStack {
                                Spacer()
                                Text("設定寶寶資料")
                                    .font(.title)
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            
                            Spacer()

                            VStack(spacing: 36) {
                                Text("寶寶暱稱")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 12) {
                                    TextField("輸入", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.name)
                                        .multilineTextAlignment(.center)
                                        .font(.title3)
                                        .padding(.horizontal, 60)
                                    
                                    Text("請輸入寶寶暱稱或乳名")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Button(action: {
                                    if !name.isEmpty {
                                        navigateToGender = true
                                    }
                                }) {
                                    Text("下一步")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                }
                                .disabled(name.isEmpty)
                                .padding(.horizontal, 120)
                            }
                            
                            Spacer()
                            Spacer()
                        }
                    }
                }
                
                // 慶祝特效層
                if showCelebration {
                    FireworksView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToGender) {
                GenderView(name: name) {
                    name = ""
                    navigateToGender = false
                    
                    // 觸發煙火邏輯
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            showCelebration = true
                        }
                        // 持續時間改為 1.0 秒
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showCelebration = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteProfile(_ profile: UserProfile) {
        modelContext.delete(profile)
    }
}

struct GenderView: View {
    let name: String
    var onComplete: () -> Void
    
    @State private var selectedGender: String = ""
    @State private var navigateToBirth = false
    let genders = ["男生", "女生"]
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("歡迎，\(name)")
                    .font(.title2)
                    .bold()
                
                Text("請選擇寶寶性別")
                    .foregroundColor(.secondary)
                
                Picker("Gender", selection: $selectedGender) {
                    Text("請選擇").tag("")
                    ForEach(genders, id: \.self) { gender in
                        Text(gender).tag(gender)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button(action: { navigateToBirth = true }) {
                    Text("下一步")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedGender.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedGender.isEmpty)
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("性別設定")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToBirth) {
            BirthView(name: name, gender: selectedGender, onComplete: onComplete)
        }
    }
}

struct BirthView: View {
    let name: String
    let gender: String
    var onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var birthDate = Date()
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("寶寶什麼時候出生的？")
                    .font(.title2)
                    .bold()
                
                DatePicker(
                    "Birthday",
                    selection: $birthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
                .frame(height: 200)
                
                Button(action: saveProfile) {
                    Text("完成設定")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("出生日期")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveProfile() {
        let newProfile = UserProfile(name: name, gender: gender, birthDate: birthDate)
        modelContext.insert(newProfile)
        onComplete()
    }
}

// 修改為「由下往上」發射的特效
struct FireworksView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + 10)
        emitter.emitterShape = .point
        emitter.emitterSize = CGSize(width: 1, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemYellow, .systemGreen, .systemPink, .systemPurple, .systemOrange]
        
        let cells = colors.map { color -> CAEmitterCell in
            let cell = CAEmitterCell()
            cell.birthRate = 60
            cell.lifetime = 1.5
            cell.velocity = CGFloat.random(in: 400...600)
            cell.velocityRange = 50
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = 2.0
            cell.spin = 1
            cell.spinRange = 5
            cell.scale = 0.05
            cell.scaleRange = 0.1
            cell.alphaSpeed = -0.3
            cell.color = color.cgColor
            cell.contents = createConfettiImage()?.cgImage
            return cell
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func createConfettiImage() -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
