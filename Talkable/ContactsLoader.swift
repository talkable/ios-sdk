//
//  ContactsLoader.swift
//  TalkableSDK
//
//  Created by Илья Костюкевич on 16.01.2020.
//  Copyright © 2020 Talkable. All rights reserved.
//

import UIKit
import Contacts

@objc
public class ContactsLoader: NSObject {
    private enum ContactKeys: String {
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case email = "email"
        case phoneNumber = "phone_number"
    }

    private let contactsStore = CNContactStore()
    
    @objc
    public func loadContactsWithComplition(_ completion: @escaping (_ contacts: [[String: Any]]) -> Void) {
        requestForAccessWithComplition {[weak self] (granted) in
            if let strongSelf = self {
                if granted {
                    let contacts = strongSelf.grabContacts()
                    
                    DispatchQueue.main.async {
                        completion(contacts)
                    }
                } else {
                    DispatchQueue.main.async {
                        strongSelf.presentPermissionAlert()
                    }
                }
            }
        }
    }
    
    private func presentPermissionAlert() {
        guard let topController = Helper.getTopViewController() else {
            Helper.print("unable to find current view controller")
            
            return
        }
        
        let alertVC = UIAlertController.init(title: nil,
                                             message: Helper.localizedString("This app requires access to your contacts to function properly. Please visit to the Privacy section in the Settings app."),
                                             preferredStyle: .alert)
        
        let action = UIAlertAction(title: Helper.localizedString("OK"), style: .default) { _ in
            alertVC.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(action)
        
        topController.present(alertVC, animated: true, completion: nil)
    }
    
    private func grabContacts() -> [[String: Any]] {
        var contacts = [[String: Any]]()
        
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactPhoneNumbersKey,
                    CNContactEmailAddressesKey] as [Any]
        
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try contactsStore.enumerateContacts(with: request){ (contact, _) in
                let separator = " "
                
                let firstName = contact.givenName
                let lastName = contact.familyName
                let fullName = [firstName, lastName].compactMap { (name) -> String? in
                    return name.isEmpty ? nil : name
                }.joined(separator: separator)
                
                let emailAddresses = contact.emailAddresses.compactMap { (emailAddress) -> String? in
                    return emailAddress.value as String
                }
                
                let phoneNumbers = contact.phoneNumbers.compactMap { (phoneNumber) -> String? in
                    return phoneNumber.value.stringValue
                }
                
                contacts.append([
                    ContactKeys.firstName.rawValue: firstName.isEmpty ? NSNull() : firstName,
                    ContactKeys.lastName.rawValue: lastName.isEmpty ? NSNull() : lastName,
                    ContactKeys.fullName.rawValue: fullName == separator ?  NSNull() : fullName,
                    ContactKeys.email.rawValue: emailAddresses,
                    ContactKeys.phoneNumber.rawValue: phoneNumbers,
                ])
            }
        } catch let error {
            Helper.print("error while loading contacts - \(error.localizedDescription)")
        }
        
        return contacts
    }

    private func requestForAccessWithComplition(_ completion: @escaping (_ accessGranted: Bool) -> Void) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
     
        switch status {
        case .authorized:
            completion(true)
        case .denied, .notDetermined, .restricted:
            contactsStore.requestAccess(for: .contacts) { (granted, error) in
                if let error = error  {
                    Helper.print("error while loading contacts - \(error.localizedDescription)")
                }
                
                completion(granted)
            }
        default:
            completion(false)
        }
    }
}
