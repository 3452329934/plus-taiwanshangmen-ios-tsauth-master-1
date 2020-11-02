//
//  Regex.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2019/7/22.
//  Copyright © 2019 ZhiYiCX. All rights reserved.
//

import Foundation

public struct MatchResult {
    public let string: String
    public let result: NSTextCheckingResult
    public let matchedString: String
    public let range: Range<String.Index>

    public init(string: String, result: NSTextCheckingResult) {
        self.string = string
        self.result = result
        range = Range(result.range, in: string)!
        matchedString = String(string[range])
    }
}

public class Regex {
    public let regularExpression: NSRegularExpression

    public init(_ pattern: String, options: NSRegularExpression.Options = []) {
        do {
            self.regularExpression = try NSRegularExpression(
                pattern: pattern,
                options: options
            )
        } catch {
            preconditionFailure("unexpected error creating regex: \(error)")
        }
    }
    
    public func matches(_ string: String) -> Bool {
        return regularExpression.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) != nil
    }

    public func allMatches(in string: String) -> [MatchResult] {
        return regularExpression.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)).map {
            MatchResult(string: string, result: $0)
        }
    }

    public func firstMatch(in string: String) -> MatchResult? {
        guard let result = regularExpression.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) else {
            return nil
        }
        return MatchResult(string: string, result: result)
    }
}

extension String {
    public mutating func replaceAll(matching regex: Regex, with template: String) {
        self = replacingAll(matching: regex, with: template)
    }

    public func replacingAll(matching regex: Regex, with template: String) -> String {
        return regex.regularExpression.stringByReplacingMatches(in: self, options: [], range:  NSRange(location: 0, length: self.count), withTemplate: template)
    }

    public mutating func replaceFirst(matching regex: Regex, with template: String) {
        if let matchResult = regex.firstMatch(in: self) {
            self = regex.regularExpression.replacementString(for: matchResult.result, in: self, offset: 0, template: template)
        }
    }

    public func replacingAll(matching pattern: String, with template: String) -> String {
        return replacingAll(matching: Regex(pattern), with: template)
    }

    public mutating func replaceAll(matching pattern: String, with template: String) {
        replaceAll(matching: Regex(pattern), with: template)
    }
}
