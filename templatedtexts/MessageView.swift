//
//  MessageView.swift
//  templatedtexts
//
//  Created by Jeffrey Sisson on 8/14/24.
//

import Foundation
import SwiftUI
import MessageUI
import PhotosUI

func getURL(item: PhotosPickerItem, completionHandler: @escaping (_ result: Result<URL, Error>) -> Void) {
    // Step 1: Load as Data object.
    item.loadTransferable(type: Data.self) { result in
        switch result {
        case .success(let data):
            if let contentType = item.supportedContentTypes.first {
                // Step 2: make the URL file name and a get a file extention.
                let url = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
                if let data = data {
                    do {
                        // Step 3: write to temp App file directory and return in completionHandler
                        try data.write(to: url)
                        completionHandler(.success(url))
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            }
        case .failure(let failure):
            completionHandler(.failure(failure))
        }
    }
}

func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
}


struct MessageView: UIViewControllerRepresentable {
    var recipient: String
    var body: String
    var image: PhotosPickerItem?

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var completion: () -> Void
        init(completion: @escaping ()->Void) {
            self.completion = completion
        }
        
        // delegate method
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                   didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true, completion: nil)
            completion()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator() {} // not using completion handler
    }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = [recipient]
        vc.body = body
        Task {
            guard let img = image else { return }
            getURL(item: img)  { result in
                switch result {
                case .success(let url):
                    vc.addAttachmentURL(url, withAlternateFilename: nil)
                case .failure(let failure):
                    print("error:\(failure)")
                    return
                }
            }
        }

        vc.messageComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    typealias UIViewControllerType = MFMessageComposeViewController
}
