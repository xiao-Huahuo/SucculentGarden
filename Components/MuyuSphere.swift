// 球体直接使用官方黑白 ChatGPT 图标；功德变化时整体旋转一圈。
import SwiftUI

struct MuyuSphere: View {
    var merit: Int

    var body: some View {
        Image("ChatGPTIcon")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(Double(merit) * 360))
            .animation(.easeInOut(duration: 1), value: merit)
            .aspectRatio(1, contentMode: .fit)
    }
}
