//
//  ContentView.swift
//  templatedtexts
//
//  Created by Jeffrey Sisson on 8/12/24.
//

import SwiftUI
import SwiftData
import Contacts
import MessageUI


struct PickerView: View {
    var allGroups: [CNGroup] = []
    @Binding var selectedGroupID: String?
    
    var nilTag: String? {
        if allGroups.isEmpty {
            return selectedGroupID
        }
        return nil
    }
    
    var body: some View {
        Picker("Group", selection: $selectedGroupID) {
            Text("None selected").tag(nilTag as String?)
            ForEach(allGroups, id: \.self) { group in
                Text(group.name).tag(group.identifier as String?)
            }
        }
    }
}

struct ContentView: View {
    @State var allGroups: [CNGroup] = []
    @State var contactsForGroup: [CNContact] = []
    @Bindable var text: TextMessage
    @State private var contactIndex: Int? = nil
    @State private var isShowingMessages = false
    @State private var needsContactsPermissions = false

    var currentGroup: CNGroup? {
        if let i = allGroups.firstIndex(where: { $0.identifier == $text.groupID.wrappedValue }) {
            return allGroups[i]
        }
        return nil
    }
    
    var currentContact: CNContact? {
        guard let index = contactIndex else {
            return nil
        }
        if !contactsForGroup.indices.contains(index) {
            return nil
        }
        return contactsForGroup[index]
    }
    
    var sampleContact: CNContact {
        let c = CNMutableContact()
        c.givenName = "Charles"
        c.familyName = "Mingus"
        if !contactsForGroup.isEmpty {
            guard let maybeContact = contactsForGroup.first else {
                return c
            }
            return maybeContact
        }
        return c
    }

    func interpolateText(input: String, contact: CNContact) -> String {
        let fullName: String = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        var text = input
        text.replace("$name", with: fullName)
        text.replace("$familyName", with: contact.familyName)
        text.replace("$givenName", with: contact.givenName)
        return text
    }
    
    
    var previewText: String {
        interpolateText(input: $text.text.wrappedValue, contact: sampleContact)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PickerView(allGroups: allGroups, selectedGroupID: $text.groupID)
                }
                .onChange(of: $allGroups.wrappedValue) {
                    needsContactsPermissions = false
                }
                .onChange(of: $contactsForGroup.wrappedValue) {
                    needsContactsPermissions = false
                }
                .onChange(of: $text.groupID.wrappedValue) {
                    updateContacts()
                }
                .onChange(of: $contactIndex.wrappedValue) {
                    if $contactIndex.wrappedValue != nil {
                        isShowingMessages = true
                    } else {
                        isShowingMessages = false
                    }
                }
                Section(header: Text("Text Message"), footer: Text("Available tokens: $name, $givenName, $familyName")) {
                    AttributedTextEditor(text: $text.text)
                        .frame(minHeight: 90)
                }
                Section(header: Text("Preview")) {
                    Text(previewText)
                }
            }
            .onAppear {
                fetchGroups()
                checkAuthorization()
            }
            .toolbar(content: {
                if needsContactsPermissions {
                    ToolbarItem(id: "permissions", content: {
                        Button(action: seekContactsAuthorization, label: {
                            Label("Change contacts access", systemImage:"key")
                                .labelStyle(.titleAndIcon)
                        })
                        .buttonStyle(.borderedProminent)
                    })
                }
                ToolbarItem(id: "send", content: {
                    Button(action: onNext, label: {
                        Label("Send", systemImage:"paperplane")
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!MFMessageComposeViewController.canSendText() || contactsForGroup.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $isShowingMessages, onDismiss: onNext) {
                        if let currentContact {
                            MessageView(
                                recipient: phoneNumber(contact: currentContact),
                                body: interpolateText(input: $text.text.wrappedValue, contact: currentContact)
                            )
                                .edgesIgnoringSafeArea(.bottom)
                        } else {
                            Text(contactIndex.debugDescription)
                        }
                    }
                })
            })
        }
    }
    
    func phoneNumber(contact: CNContact) -> String  {
        let number = contact.phoneNumbers.first?.value.stringValue
        return number ?? ""
    }

    func seekContactsAuthorization() {
        if let bundleId = Bundle.main.bundleIdentifier,
            let url = URL(string: "\(UIApplication.openSettingsURLString)&path=APPNAME/\(bundleId)")
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func checkAuthorization() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return
        default:
            needsContactsPermissions = true
        }
    }
    
    func fetchGroups() {
        Task {
            if !allGroups.isEmpty {
                return
            }
            let contactStore = CNContactStore()
            guard let groups = try? contactStore.groups(matching: nil) else {
                print("Failed to fetch groups from contact store")
                return
            }
            if !groups.isEmpty {
                allGroups = groups
                updateContacts()
            }
        }
    }
    
    func updateContacts() {
        guard let group = currentGroup else {
            return
        }
        let contacts = fetchContacts(in: group)
        contactsForGroup = contacts
    }

    func fetchContacts(in group: CNGroup) -> [CNContact] {
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
        do {
            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName) as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ] as [CNKeyDescriptor]
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        } catch {
            print("Error fetching contacts: \(error)")
        }
        return contacts
    }

    func onNext() {
        if contactsForGroup.isEmpty {
            contactIndex = nil
            return
        }
        var nextIndex: Int =  0
        if contactIndex != nil {
            nextIndex = contactIndex! + 1
            if nextIndex >= contactsForGroup.count {
                contactIndex = nil
                return
            }
        }
        for (index, contact) in contactsForGroup[nextIndex...].enumerated() {
            // if there's no phone number, we attempt to find the next available contact
            if phoneNumber(contact: contact).count == 0 {
                continue
            }
            contactIndex = index + nextIndex
            return
        }
        // if we've reaced this point, we ran out of contacts,
        // and should be done
        contactIndex = nil
    }
}

struct Example : PreviewProvider {
    static var groups: [CNGroup] {
        let g = CNMutableGroup()
        g.name = "Haha"
        return [g]
    }
    static var previews: some View {
        ContentView(allGroups: groups,text:TextMessage(text: "Hey $name how is it going?\nThis is a multi-line\nText", groupID: nil))
    }
}
