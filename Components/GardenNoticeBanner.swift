// 每条提示独立计时；替换或离开视图会取消旧计时，旧横幅不能关闭新消息。
import SwiftUI

struct GardenNoticeBanner: View {
    let model: GardenModel

    var body: some View {
        if let notice = model.notice {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: notice.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(notice.isError ? Color.red : Color.accentColor)
                    .accessibilityHidden(true)
                Text(notice.message)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Button { model.dismissNotice(notice.id) } label: {
                    Image(systemName: "xmark").font(.caption.weight(.medium))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭操作提示")
            }
            .padding(12)
            .frame(maxWidth: 440)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .accessibilityIdentifier("garden.action.notice")
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: notice.id) {
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                guard !Task.isCancelled else { return }
                model.dismissNotice(notice.id)
            }
        }
    }
}
