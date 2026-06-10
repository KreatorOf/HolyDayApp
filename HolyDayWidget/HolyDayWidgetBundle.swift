//
//  HolyDayWidgetBundle.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

@main
struct HolyDayWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayNowWidget()
    VerseWidget()
    HeatmapWidget()
  }
}
