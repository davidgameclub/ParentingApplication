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
                            Section("Profile Details") {
                                LabeledContent("Name", value: profile.name)
                                LabeledContent("Gender", value: profile.gender)
                                LabeledContent("Birthday", value: profile.birthDate.formatted(date: .long, time: .omitted))
                            }
                            
                            // --- New Button Added Here ---
                            Section {
                                NavigationLink {
                                    MainMenuView()
                                } label: {
                                    Text("Go to Main Menu")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            Section {
                                Button(role: .destructive) {
                                    deleteProfile(profile)
                                } label: {
                                    Text("Delete and Create New")
                                        .frame(maxWidth: .infinity)
                                }
                            } footer: {
                                Text("To change your information, you must delete the current profile.")
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        VStack {
                            Spacer()
                            VStack(spacing: 24) {
                                Text("寶寶的名字是啥呢？")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 12) {
                                    TextField("Enter name", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.name)
                                        .multilineTextAlignment(.center)
                                        .font(.title3)
                                        .padding(.horizontal, 40)
                                    
                                    Text("寫寶寶的乳名也可以喔")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Button(action: {
                                    if !name.isEmpty {
                                        navigateToGender = true
                                    }
                                }) {
                                    Text("Next")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .disabled(name.isEmpty)
                                .padding(.horizontal, 40)
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
            .navigationTitle("Profile")
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
    
    @State private var selectedGender: String = "Select"
    @State private var navigateToBirth = false
    let genders = ["Select", "Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("Welcome, \(name)")
                    .font(.title2)
                    .bold()
                
                Text("Please select your gender")
                    .foregroundColor(.secondary)
                
                Picker("Gender", selection: $selectedGender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button(action: { navigateToBirth = true }) {
                    Text("Next")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedGender == "Select" ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedGender == "Select")
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("Gender")
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
                Text("When were you born?")
                    .font(.title2)
                    .bold()
                
                DatePicker(
                    "Birthday",
                    selection: $birthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 200)
                
                Button(action: saveProfile) {
                    Text("Complete Profile")
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
        .navigationTitle("Birthday")
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
        // 設定在螢幕底部中央
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + 10)
        emitter.emitterShape = .point // 使用點發射，然後用 emissionRange 控制發散角度
        emitter.emitterSize = CGSize(width: 1, height: 1) // 設置為點
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemYellow, .systemGreen, .systemPink, .systemPurple, .systemOrange]
        
        let cells = colors.map { color -> CAEmitterCell in
            let cell = CAEmitterCell()
            cell.birthRate = 60 // 增加總量，讓一秒內看起來足夠多
            cell.lifetime = 1.5 // 縮短生命週期，讓效果更集中在短時間內 (配合 1.0s 總顯示時間)
            cell.velocity = CGFloat.random(in: 400...600) // 速度適中
            cell.velocityRange = 50
            
            // 關鍵調整：指向正上方 (-.pi / 2)，並設定較大的發散角度 (emissionRange = 2.0 徑度) 以向兩側擴散
            cell.emissionLongitude = -.pi / 2 // 正上方
            cell.emissionRange = 2.0 // 寬廣的發散角度 (約 114.6 度)
            
            cell.spin = 1
            cell.spinRange = 5
            cell.scale = 0.05
            cell.scaleRange = 0.1
            cell.alphaSpeed = -0.3 // 讓淡出更快一些
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
        
        // 為了模擬碎片，我們在中央繪製一個小方塊
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
