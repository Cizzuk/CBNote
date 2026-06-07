//
//  SortHelpers.swift
//  CBNote
//
//  Created by Cizzuk on 2025/12/14.
//

import Foundation

enum SortKey: String, CaseIterable {
    case name // Default
    case date // Modification Date
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .name:
            return "Name"
        case .date:
            return "Date"
        }
    }
}

enum SortDirection: String {
    case descending // Default
    case ascending
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .descending:
            return "Descending"
        case .ascending:
            return "Ascending"
        }
    }
}
