//
//  AttributedTextEditor.swift
//  templatedtexts
//
//  Created by Jeffrey Sisson on 8/14/24.
//

import Foundation
import SwiftUI

struct AttributedTextEditor: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font =  UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.delegate = context.coordinator
        textView.attributedText = NSAttributedString(string: text)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        formatTextInTextView(textView: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final private class UIKitTextView: UITextView {
        override var contentSize: CGSize {
            didSet {
                invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: CGSize {
            // Or use e.g. `min(contentSize.height, 150)` if you want to restrict max height
            CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
        }
    }
    
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedTextEditor

        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText.string
        }
    }
}

func formatTextInTextView(textView: UITextView) {
    textView.isScrollEnabled = false
    let selectedRange = textView.selectedRange
    let text = textView.text ?? ""

    let attributedString = NSMutableAttributedString(string: text, attributes: [
            NSAttributedString.Key.foregroundColor : UIColor.label,
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)
        ]
    )

    let regex = try? NSRegularExpression(pattern: "\\$(givenName|familyName|name)", options: [])
    let matches = regex!.matches(in: text, options: [], range: NSMakeRange(0, text.count))

    for match in matches {
        let matchRange = match.range(at: 0)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: matchRange)
    }

    textView.attributedText = attributedString
    textView.selectedRange = selectedRange
    textView.isScrollEnabled = true
}
