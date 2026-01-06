//
//  CreateHabitSheet.swift
//  Practice
//
//  Created by Robert Farley on 20/05/2025.
//

import SwiftUI

struct CreateHabitSheet: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var newHabit : Habit = Habit(name: "", dates: [])
    @Binding var habitEditorShowing : Bool
    @State var newHabitError : Bool = false
    @FocusState private var textFieldFocused : Bool
    
    let colors : [Color] = [.blue, .red, .orange, .yellow]
    
    @State var color : Color = .accentColor
        
    @Environment(\.modelContext) private var context
    
    var body: some View {
            
        NavigationStack {
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    HStack(alignment: .firstTextBaseline) {
                        
                        Label("Habit name: ", systemImage: "person.fill")
                            .labelStyle(.titleOnly)
                        
                        Spacer()
                        
                        TextField("Knitting", text: $newHabit.name)
                            .textFieldStyle(.roundedBorder)
                        //.background(Color.gray.opacity(0.2))
                            .padding(.bottom)
                            .focused($textFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textContentType(.none)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        textFieldFocused = false
                                    }
                                }
                            }
                    }
                    .padding(.top, 20)
                    // .frame(width: 300)
                    
                    // color picker
                    // ColorPicker("Colour", selection: $color)
                    
                    Text("Select any recent dates you have completed this habit")
                    .foregroundStyle(.gray)
                    
                    MonthView(selectedDate: Date(), habit: newHabit)
                    
                    Spacer()
                }
                
                .padding(.horizontal, 50)
            }
            .scrollContentBackground(.hidden)
            .alert("Please add habit name", isPresented: $newHabitError) {
                Button("OK") {
                    newHabitError.toggle()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        habitEditorShowing = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if newHabit.name.isEmpty {
                            newHabitError.toggle()
                        } else {
                            // save habit
                            let habitToInsert = Habit(name: newHabit.name, dates: newHabit.dates)
                            
                            // convert color to color hash/hex and assign it to habit
                            
                            // add to context & save
                            context.insert(habitToInsert)
                            do {
                                try context.save()
                            } catch {
                                print("failed to save habit: \(habitToInsert.name)")
                            }
                            
                            // reset 'newHabit'
                            newHabit.name = ""
                            newHabit.dates = []
                            
                            // hide sheet
                            habitEditorShowing.toggle()
                        }
                    } label : {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                    
                }
            }
            .navigationTitle("Create Habit")
            .navigationBarTitleDisplayMode(.inline)
            //.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            textFieldFocused = true
        }
    }
}

#Preview {
    CreateHabitSheet(
        newHabit: Habit(name: "", dates: []),
        habitEditorShowing: .constant(true)
    )
    .environmentObject(ViewModel())
    .modelContainer(for: Habit.self, inMemory: true)
}
