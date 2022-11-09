//
//  ContactPicker.swift
//  Heath
//
//  Created by Dylan Hu on 11/8/22.
//

import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            picker.dismiss(animated: true)
            self.parent.contact = contact
        }
    }
    
    @Binding var contact: CNContact?
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

struct ContactPicker_Previews: PreviewProvider {
   static var previews: some View {
       ContactPicker(contact: .constant(nil))
   }
}
