//
//  MessageComposeView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import MessageUI
import Contacts

struct MessageComposeView: UIViewControllerRepresentable {
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            parent.result = result
        }
        
        var parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
    }
    
    let contact: CNContact?
    let message: String?
    @Binding var result: MessageComposeResult?
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        if let contact = contact {
            if contact.phoneNumbers.count > 0 {
                controller.recipients = [contact.phoneNumbers[0].value.stringValue]
            } else if contact.emailAddresses.count > 0 {
                controller.recipients = [contact.emailAddresses[0].value as String]
            }
        }
        if message != nil {
            controller.body = message
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

struct MessageComposeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            
        }.sheet(isPresented: .constant(true)) {
            MessageComposeView(contact: nil, message: "", result: .constant(MessageComposeResult(rawValue: 1)!))
        }
    }
}
