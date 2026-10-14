// 球在左、信息在右；当前时间由系统实时更新，不依赖后台轮询。
import SwiftUI
import WidgetKit

struct MuyuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MuyuEntry

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        HStack(spacing: isSmall ? 6 : 10) {
            if let progress = entry.progress {
                sphere(progress)

                VStack(alignment: .leading, spacing: isSmall ? 3 : 6) {
                    Text(.currentDate, format: .dateTime
                        .hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits))
                        .font(.system(size: isSmall ? 13 : 21, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("当前时间")

                    metric("功德", value: progress.merit)
                    metric("福缘", value: progress.fortune)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("今日箴言")
                            .font(.system(size: isSmall ? 8 : 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(entry.saying)
                            .font(.system(size: isSmall ? 9 : 12))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let error = entry.errorMessage {
                        Text(error).font(.system(size: 10)).foregroundStyle(.red)
                    }
                }
            } else {
                Text("数据暂时无法读取")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor)
        }
    }

    private func sphere(_ progress: MuyuProgress) -> some View {
        ZStack {
            Button(intent: MuyuTapIntent()) {
                MuyuSphere(merit: progress.merit)
                    .frame(width: isSmall ? 40 : 88, height: isSmall ? 40 : 88)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("敲木鱼球，功德加一")

            if progress.lastTap != nil {
                Text("功德+1")
                    .font(.system(size: isSmall ? 9 : 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .offset(x: progress.popupX * (isSmall ? 0.45 : 1),
                            y: progress.popupY * (isSmall ? 0.55 : 1))
                    .id(progress.merit)
                    .transition(.opacity.combined(with: .scale(scale: 0.65)))
            }
        }
        .frame(width: isSmall ? 46 : 112, height: 132)
        .animation(.easeOut(duration: 0.6), value: progress.merit)
    }

    private func metric(_ title: String, value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: isSmall ? 3 : 7) {
            Text(title).foregroundStyle(.secondary)
            Text(value, format: .number.grouping(.never))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: value)
        }
        .font(.system(size: isSmall ? 10 : 14, weight: .medium))
    }
}
