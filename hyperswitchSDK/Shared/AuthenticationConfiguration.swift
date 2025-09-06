//
//  AuthenticationConfiguration.swift
//  hyperswitch
//
//  Created by Shivam Nan on 06/09/25.
//

import Foundation
import UIKit

public extension AuthenticationSession {
    // MARK: - Main UI Customization Class
    class UICustomization {
        var toolbarCustomization: ToolbarCustomization?
        var submitButtonCustomization: ButtonCustomization?
        var resendButtonCustomization: ButtonCustomization?
        var labelCustomization: LabelCustomization?
        var fontCustomization: FontCustomization?
        var textBoxCustomization: TextBoxCustomization?
        var cancelPopupCustomization: CancelPopupCustomization?
        
        init(toolbarCustomization: ToolbarCustomization? = nil,
             submitButtonCustomization: ButtonCustomization? = nil,
             resendButtonCustomization: ButtonCustomization? = nil,
             labelCustomization: LabelCustomization? = nil,
             fontCustomization: FontCustomization? = nil,
             textBoxCustomization: TextBoxCustomization? = nil,
             cancelPopupCustomization: CancelPopupCustomization? = nil) {
            self.toolbarCustomization = toolbarCustomization
            self.submitButtonCustomization = submitButtonCustomization
            self.resendButtonCustomization = resendButtonCustomization
            self.labelCustomization = labelCustomization
            self.fontCustomization = fontCustomization
            self.textBoxCustomization = textBoxCustomization
            self.cancelPopupCustomization = cancelPopupCustomization
        }
    }
    
    // MARK: - Button Customization
    class ButtonCustomization {
        var backgroundColor: String?
        var textColor: String?
        var cornerRadius: NSNumber?
        var fontSize: NSNumber?
        var fontName: String?
        var showCapitalizedText: NSNumber?
        var fontStyle: String?
        
        init(backgroundColor: String? = nil,
             textColor: String? = nil,
             cornerRadius: NSNumber? = nil,
             fontSize: NSNumber? = nil,
             fontName: String? = nil,
             showCapitalizedText: NSNumber? = nil,
             fontStyle: String? = nil) {
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.cornerRadius = cornerRadius
            self.fontSize = fontSize
            self.fontName = fontName
            self.showCapitalizedText = showCapitalizedText
            self.fontStyle = fontStyle
        }
    }
    
    // MARK: - Button Type Enum
    enum ButtonType: Int, CaseIterable {
        case submit = 0
        case `continue` = 1
        case next = 2
        case cancel = 3
        case resend = 4
    }
    
    // MARK: - Text Customization
    class TextCustomization {
        var textColor: String?
        var fontSize: NSNumber?
        var fontStyle: String?
        
        init(textColor: String? = nil,
             fontSize: NSNumber? = nil,
             fontStyle: String? = nil) {
            self.textColor = textColor
            self.fontSize = fontSize
            self.fontStyle = fontStyle
        }
    }
    
    // MARK: - Label Customization
    class LabelCustomization {
        var challengeHeader: TextCustomization?
        var challengeContent: TextCustomization?
        var challengeLabel: TextCustomization?
        
        init(challengeHeader: TextCustomization? = nil,
             challengeContent: TextCustomization? = nil,
             challengeLabel: TextCustomization? = nil) {
            self.challengeHeader = challengeHeader
            self.challengeContent = challengeContent
            self.challengeLabel = challengeLabel
        }
    }
    
    // MARK: - TextBox Customization
    class TextBoxCustomization {
        var textColor: String?
        var textSpacing: NSNumber?
        var fontName: String?
        var borderColor: String?
        var borderWidth: NSNumber?
        var cornerRadius: NSNumber?
        var useBoxedLayout: NSNumber?
        var focusedColor: String?
        var fontSize: NSNumber?
        var hintTextColor: String?
        var useNumericInputField: NSNumber?
        var fontStyle: String?
        
        init(textColor: String? = nil,
             textSpacing: NSNumber? = nil,
             fontName: String? = nil,
             borderColor: String? = nil,
             borderWidth: NSNumber? = nil,
             cornerRadius: NSNumber? = nil,
             useBoxedLayout: NSNumber? = nil,
             focusedColor: String? = nil,
             fontSize: NSNumber? = nil,
             hintTextColor: String? = nil,
             useNumericInputField: NSNumber? = nil,
             fontStyle: String? = nil) {
            self.textColor = textColor
            self.textSpacing = textSpacing
            self.fontName = fontName
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadius = cornerRadius
            self.useBoxedLayout = useBoxedLayout
            self.focusedColor = focusedColor
            self.fontSize = fontSize
            self.hintTextColor = hintTextColor
            self.useNumericInputField = useNumericInputField
            self.fontStyle = fontStyle
        }
    }
    
    // MARK: - Toolbar Customization
    class ToolbarCustomization {
        var headerColor: String?
        var headerText: String?
        var backgroundColor: String?
        var buttonText: String?
        var textFontSize: NSNumber?
        var useCloseIcon: NSNumber?
        var closeIconColor: String?
        var fontStyle: String?
        
        init(headerColor: String? = nil,
             headerText: String? = nil,
             backgroundColor: String? = nil,
             buttonText: String? = nil,
             textFontSize: NSNumber? = nil,
             useCloseIcon: NSNumber? = nil,
             closeIconColor: String? = nil,
             fontStyle: String? = nil) {
            self.headerColor = headerColor
            self.headerText = headerText
            self.backgroundColor = backgroundColor
            self.buttonText = buttonText
            self.textFontSize = textFontSize
            self.useCloseIcon = useCloseIcon
            self.closeIconColor = closeIconColor
            self.fontStyle = fontStyle
        }
    }
    
    // MARK: - Cancel Popup Customization
    class CancelPopupCustomization {
        var continueButtonCustomization: ButtonCustomization?
        var exitButtonCustomization: ButtonCustomization?
        var headerTextCustomization: TextCustomization?
        var contentTextCustomization: TextCustomization?
        var headerText: String?
        var labelText: String?
        var exitButtonText: String?
        var continueButtonText: String?
        
        init(continueButtonCustomization: ButtonCustomization? = nil,
             exitButtonCustomization: ButtonCustomization? = nil,
             headerTextCustomization: TextCustomization? = nil,
             contentTextCustomization: TextCustomization? = nil,
             headerText: String? = nil,
             labelText: String? = nil,
             exitButtonText: String? = nil,
             continueButtonText: String? = nil) {
            self.continueButtonCustomization = continueButtonCustomization
            self.exitButtonCustomization = exitButtonCustomization
            self.headerTextCustomization = headerTextCustomization
            self.contentTextCustomization = contentTextCustomization
            self.headerText = headerText
            self.labelText = labelText
            self.exitButtonText = exitButtonText
            self.continueButtonText = continueButtonText
        }
    }
    
    // MARK: - Font Customization
    class FontCustomization {
        // Base font customization class
        // Can be extended with specific font properties as needed
        
        init() {
            // Initialize with default values or empty implementation
        }
    }
    
    // MARK: - Custom Font Style
    class CustomFontStyle {
        // Custom font style implementation
        // Can be extended with specific font style properties
        
        init() {
            // Initialize with default values or empty implementation
        }
    }
    
    // MARK: - Severity Enum (for validation/warnings)
    enum Severity: Int, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
    }
}
