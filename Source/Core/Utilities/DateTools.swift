// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class DateTools {
  
  public static func calculateSecondsByPeriod(value: Double, period: SearchDateTimePeriods) -> Double {
    
    var seconds = 0.0
    
    switch period {
      
    case SearchDateTimePeriods.Seconds:
      seconds = value
      
    case SearchDateTimePeriods.Minutes:
      seconds = value * 60.0
      
    case SearchDateTimePeriods.Hours:
      seconds = value * 3600
      
    case SearchDateTimePeriods.Days:
      seconds = value * 86400
      
    case SearchDateTimePeriods.Weeks:
      seconds = value * 604800
      
    case SearchDateTimePeriods.Months:
      seconds = value * 2628000
      
    case SearchDateTimePeriods.Years:
      seconds = value * 31536000
      
    }
    
    return seconds
    
  }
  
  public static func buildDate(input:String) -> String {
    if let dateObj = getDate(input: input) {
      
      let dateFormatterPrint = DateFormatter()
      dateFormatterPrint.dateFormat = "d/MM/yy HH:mm:ss"
      
      return dateFormatterPrint.string(from: dateObj)
    }
    
    return ""
    
    
  }
  
  public static func buildDateLarge(input: String) -> String {
      if let dateObj = getDate(input: input) {
          let dateFormatterPrint = DateFormatter()
          dateFormatterPrint.dateFormat = "MMM d, yyyy HH:mm:ss"
          return dateFormatterPrint.string(from: dateObj)
      }
      return ""
  }

  public static func buildDateLarge(input: Date) -> String {
      let dateFormatterPrint = DateFormatter()
      dateFormatterPrint.dateFormat = "d MMM yyyy HH:mm:ss.SSSS"
      return dateFormatterPrint.string(from: input)
  }

  public static func getDate(input: String) -> Date? {
      // Array of possible date formats to try
      let dateFormats = [
          "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // Original format with timezone
          "yyyy-MM-dd'T'HH:mm:ss.SSS",      // ISO with milliseconds
          "yyyy-MM-dd'T'HH:mm:ss",          // ISO basic format (your example)
          "yyyy-MM-dd HH:mm:ss.SSSZ",       // Space separated with timezone
          "yyyy-MM-dd HH:mm:ss.SSS",        // Space separated with milliseconds
          "yyyy-MM-dd HH:mm:ss",            // Space separated basic
          "yyyy-MM-dd'T'HH:mm:ssZ",         // ISO with timezone, no milliseconds
          "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",   // ISO with microseconds
          "MMM d, yyyy HH:mm:ss",           // Human readable format
          "d MMM yyyy HH:mm:ss.SSSS",       // Alternative human readable
          "yyyy-MM-dd",                     // Date only
      ]
      
      // Try each format until one works
      for format in dateFormats {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = format
          dateFormatter.timeZone = TimeZone.current
          dateFormatter.locale = Locale.current
          
          if let date = dateFormatter.date(from: input) {
              return date
          }
      }
      
      // Try ISO8601DateFormatter as fallback
      let iso8601Formatter = ISO8601DateFormatter()
      
      // Try with full internet date time format
      iso8601Formatter.formatOptions = [.withInternetDateTime]
      if let date = iso8601Formatter.date(from: input) {
          return date
      }
      
      // Try with date, time, and fractional seconds (no timezone)
      iso8601Formatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
      if let date = iso8601Formatter.date(from: input) {
          return date
      }
      
      // Try basic format with just date and time
      iso8601Formatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withFractionalSeconds]
      if let date = iso8601Formatter.date(from: input) {
          return date
      }
      
      return nil
  }
  
  public static func dateString(_ dateInput: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // Full day, Monday
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.locale = Locale.current
    return dateFormatter.string(from: dateInput)
  }
  
  public static func getDateString(_ dateInput: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd / MM / yyyy" // Full day, Monday
    return dateFormatter.string(from: dateInput)
  }
  
  
  public static func getHourString(_ dateInput: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss a" // Full day, Monday
    return dateFormatter.string(from: dateInput)
  }

}
