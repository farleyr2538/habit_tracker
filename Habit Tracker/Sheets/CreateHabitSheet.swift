//
//  CreateHabitSheet.swift
//  Practice
//
//  Created by Robert Farley on 20/05/2025.
//

import SwiftUI

struct CreateHabitSheet: View {
    
    @EnvironmentObject var viewModel : ViewModel
    @Environment(\.modelContext) private var context
    
    @State var newHabit : Habit = Habit(name: "", dates: [])
    @Binding var habitEditorShowing : Bool
    @State var newHabitError : Bool = false
    
    @FocusState private var textFieldFocused : Bool
    
    @State var color : Color? = .green
    
    var body: some View {
            
        NavigationStack {
            
            // ScrollView {
                
            Form {
                    
                HStack(alignment: .firstTextBaseline) {
                    
                    Label("Habit name: ", systemImage: "person.fill")
                        .labelStyle(.titleOnly)
                    
                    Spacer()
                    
                    TextField("Knitting", text: $newHabit.name)
                        .textFieldStyle(.roundedBorder)
                    //.background(Color.gray.opacity(0.2))
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
                                
                // color picker
                HStack {
                    Spacer()
                    
                    CustomColorPicker(selectedColor: Binding(
                        get: { color ?? .green },
                        set: { color = $0 }
                        )
                    )
                    
                    Spacer()
                }
                
                VStack {
                    Text("Select any recent dates you have completed this habit")
                        .foregroundStyle(.gray)
                    
                    MultiMonthView(habit: newHabit, color: $color)
                        .frame(height: 300)
                }
                .padding(.vertical)
                                    
            }

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
                        
                        // check for empty habit name
                        if newHabit.name.isEmpty {
                            newHabitError.toggle()
                        } else {
                            
                            // create habit instance
                            let habitToInsert = Habit(
                                name: newHabit.name,
                                dates: newHabit.dates
                            )
                            
                            // try to convert color to color hash/hex...
                            if let hex = Color(color ?? .green).toHex() {
                                // ... and assign it to habit
                                habitToInsert.colorHash = hex
                            } else {
                                print("unable to convert color \(color != nil ? color!.description : Color.green.description) to hex")
                            }
                            
                            // add to context & save
                            context.insert(habitToInsert)
                            do {
                                try context.save()
                            } catch {
                                print("failed to save habit: \(habitToInsert.name)")
                            }
                            
                            // reset 'newHabit' variable
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
