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
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        
        ScrollView {
            
            
            VStack(spacing: 15) {
                
                HStack {
                    Text("Add New Round")
                        .font(.title)
                        .bold()
                        .padding(.top, 50)
                    Spacer()
                }
                
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
                }
                .padding(.top, 20)
                .frame(width: 300)
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Select any recent dates you have completed this habit")
                }
                .foregroundStyle(.gray)
                
                MonthView(selectedDate: Date(), habit: newHabit)
                
                
                
                Button {
                    if newHabit.name.isEmpty {
                        newHabitError.toggle()
                    } else {
                        // save habit
                        let habitToInsert = Habit(name: newHabit.name, dates: newHabit.dates)
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
                } label: {
                    Text("Add")
                        .padding(5)
                }
                .padding(.top, 5)
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .alert("Please add habit name", isPresented: $newHabitError) {
                    Button("OK") {
                        newHabitError.toggle()
                    }
                }
                Spacer()
            }
            
            .padding(.horizontal, 50)
        }
        /*
         .onAppear {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
         textFieldFocused = true
         }
         }*/
        
        .toolbar {
            ToolbarItem {
                Button {
                    habitEditorShowing.toggle()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .navigationTitle("Create Habit")
         
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
