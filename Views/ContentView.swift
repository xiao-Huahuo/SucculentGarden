// 木鱼球主应用说明；游戏数据由桌面 Widget 扩展独立持久化。
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 18) {
            MuyuSphere(merit: 0)
                .frame(width: 110, height: 110)
            Text("木鱼球").font(.title.weight(.semibold))
            Text("将木鱼球小组件添加到桌面，点击球积累功德。")
            Text("每次获得 1 至 3 点福缘，每天读一条箴言。")
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 360)
    }
}

#Preview {
    ContentView()
}
