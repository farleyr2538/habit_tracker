//
//  EditHabitSheet.swift
//  Habit Tracker
//
//  Created by Rob Farley on 25/01/2026.
//

import SwiftUI

struct EditHabitSheet: View {
    
    @Environment(\.modelContext) private var context
    
    @Environment(NavigationCoordinator.self) private var coordinator

    @Bindable var habit : Habit
    
    @Binding var hasJustDeleted : Bool
    
    @State var habitName : String = ""
    @State var habitColor : Color = .green
    @State var startingDate : Date = Date()
    
    @State private var deleteAlertShowing : Bool = false
    @State private var editAlertShowing : Bool = false
        
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 20) {
                
                HStack {
                    Text("Edit \(habit.name)")
                        .font(.title)
                    Spacer()
                }
                
                Divider()
                    //.padding(.bottom)
                
                HStack {
                    Text("Habit name")
                    Spacer()
                    TextField("Habit name", text: $habitName)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 175)
                }
                
                DatePicker("Starting date", selection: $startingDate, displayedComponents: .date)
                    .datePickerStyle(.automatic)
                
                CustomColorPicker(selectedColor: $habitColor)
                            
                Button(role: .destructive) {
                    deleteAlertShowing.toggle()
                } label: {
                    Text("Delete habit")
                        .padding(5)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                Spacer()
                
            }
            //.navigationTitle("Edit \(habit.name)")
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            
            .background(Color.white)
            .cornerRadius(15.0)
            
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
            
            .onAppear {
                // set state variables to match given habit's variables
                habitName = habit.name
                
                startingDate = habit.startFrom
                
                // if habit has a colorHex...
                if let colorHex = habit.colorHash {

                    habitColor = Color(hex: colorHex)
                } else {
                    habitColor = .green
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // quit without saving
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // save and close sheet
                        
                        // re-assign values
                        habit.name = habitName
                        
                        if let newColorHex = habitColor.toHex() {
                            habit.colorHash = newColorHex
                        }
                        
                        habit.startFrom = startingDate
                        
                        // try to save
                        try? context.save()
                        
                        dismiss()
                        
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            .alert("Delete Habit?", isPresented: $deleteAlertShowing) {
                Button("Delete", role: .destructive) {
                    // dismiss sheet
                    dismiss()
                    
                    // navigate back out of HabitView
                    coordinator.goBack()
                    
                    // delete habit
                    context.delete(habit)
                    
                    // save
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            }
            
            .alert("Rename Habit", isPresented: $editAlertShowing) {
                TextField("New Name", text: $habitName)
                Button("Cancel", role: .cancel) {}
                Button("Confirm") {
                    
                    habit.name = habitName
                    habitName = ""
                    
                    try? context.save()
                }
                .disabled(habitName.isEmpty)
            } message: {
                Text("Please enter a new name")
            }
        }
        .background(Color.background)
    }
}

#Preview {
    NavigationStack {
        EditHabitSheet(habit: Habit.sampleData.first!, hasJustDeleted: .constant(false))
    }
    .modelContainer(for: Habit.self)
    .environmentObject(ViewModel())
    .environment(NavigationCoordinator())
}
