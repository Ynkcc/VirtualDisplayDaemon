# patches_queue 补丁清单

本目录保存 VirtualDisplay daemon 对 scrcpy 子模块 `server/` 的补丁集合。
补丁路径前缀（`server/...`、`gradlew`）相对目标仓库根 **`daemon/scrcpy`**。

共 **66 个补丁**：45 个新增文件（38 个 daemon 源码 + 7 个单元测试）+ 21 个修改上游文件。

> 应用工具：`../tools/apply_patches.sh`（逐补丁判定 APPLIED/CLEAN/CONFLICT，普通重跑即可
> 修复缺失文件；`--force` 可先还原 baseline 再整体重放）、
> `../tools/test_compilation.sh`（reset 到 pristine master → 重放 → 编译 → 跑单元测试）。
> `./apply.sh`（`list` / `check` / `apply` / `reverse`）仍可用于逐个查看补丁状态。
> 单个补丁的生成：`../tools/gen_patch.sh <相对 scrcpy 根的路径>`，把输出重定向到本目录同名 `.patch`。

---

## 1. 新增文件（45 个）

按包分组。这些是 daemon 模式新增的独立实现，**无相互依赖**，可任意序应用，
但需在引用它们的「修改上游」补丁之前应用（保证编译正确）。

### 1.1 control（1）
| 补丁 | 目标文件 | 被谁引用 |
|---|---|---|
| `control/ControlMessageExtension.java.patch` | `server/.../control/ControlMessageExtension.java` | `Controller`（修改） |

### 1.2 video（2）
| 补丁 | 目标文件 | 被谁引用 |
|---|---|---|
| `video/ExternalDisplayProvider.java.patch` | `server/.../video/ExternalDisplayProvider.java` | `ScreenCapture`（修改）、`DisplaySurfaceBroker` |
| `video/FrameSink.java.patch` | `server/.../video/FrameSink.java` | `Streamer`/`SurfaceEncoder`（修改）、`FrameBroadcaster` |

### 1.3 daemon（35）
`daemon/` 包为 daemon 模式的核心，内部有包级依赖，但均为新增、互相可解析：

| 补丁 | 目标文件 |
|---|---|
| `daemon/ClientSession.java.patch` | `daemon/ClientSession.java` |
| `daemon/compat/DisplayCompat.java.patch` | `daemon/compat/DisplayCompat.java` |
| `daemon/control/CommandHandler.java.patch` | `daemon/control/CommandHandler.java` |
| `daemon/control/DaemonCommandHandler.java.patch` | `daemon/control/DaemonCommandHandler.java` |
| `daemon/control/DaemonControlMessage.java.patch` | `daemon/control/DaemonControlMessage.java` |
| `daemon/control/DaemonControlMessageReader.java.patch` | `daemon/control/DaemonControlMessageReader.java` |
| `daemon/control/DaemonDeviceMessage.java.patch` | `daemon/control/DaemonDeviceMessage.java` |
| `daemon/control/DaemonDeviceMessageWriter.java.patch` | `daemon/control/DaemonDeviceMessageWriter.java` |
| `daemon/control/DaemonMessages.java.patch` | `daemon/control/DaemonMessages.java` |
| `daemon/control/ExecutionPolicy.java.patch` | `daemon/control/ExecutionPolicy.java` |
| `daemon/control/ExtensionCarrier.java.patch` | `daemon/control/ExtensionCarrier.java` |
| `daemon/ControlLoopRunner.java.patch` | `daemon/ControlLoopRunner.java` |
| `daemon/DaemonArgs.java.patch` | `daemon/DaemonArgs.java` |
| `daemon/DaemonExitCoordinator.java.patch` | `daemon/DaemonExitCoordinator.java` |
| `daemon/DaemonOptions.java.patch` | `daemon/DaemonOptions.java` |
| `daemon/DaemonServer.java.patch` | `daemon/DaemonServer.java` |
| `daemon/DaemonVideoPipeline.java.patch` | `daemon/DaemonVideoPipeline.java` |
| `daemon/display/ActivityLauncher.java.patch` | `daemon/display/ActivityLauncher.java` |
| `daemon/display/AppLister.java.patch` | `daemon/display/AppLister.java` |
| `daemon/display/DisplaySurfaceBroker.java.patch` | `daemon/display/DisplaySurfaceBroker.java` |
| `daemon/display/RefCountedDisplayRegistry.java.patch` | `daemon/display/RefCountedDisplayRegistry.java` |
| `daemon/display/RotationController.java.patch` | `daemon/display/RotationController.java` |
| `daemon/display/VirtualDisplayRegistry.java.patch` | `daemon/display/VirtualDisplayRegistry.java` |
| `daemon/display/VirtualDisplaySession.java.patch` | `daemon/display/VirtualDisplaySession.java` |
| `daemon/net/DaemonWire.java.patch` | `daemon/net/DaemonWire.java` |
| `daemon/net/InstanceMutex.java.patch` | `daemon/net/InstanceMutex.java` |
| `daemon/net/TcpDesktopConnection.java.patch` | `daemon/net/TcpDesktopConnection.java` |
| `daemon/net/TcpServerSocketListener.java.patch` | `daemon/net/TcpServerSocketListener.java` |
| `daemon/SessionConfigurator.java.patch` | `daemon/SessionConfigurator.java` |
| `daemon/SessionVideoController.java.patch` | `daemon/SessionVideoController.java` |
| `daemon/video/ByteArrayPool.java.patch` | `daemon/video/ByteArrayPool.java` |
| `daemon/video/FrameBroadcaster.java.patch` | `daemon/video/FrameBroadcaster.java` |
| `daemon/video/FrameBroadcasterRegistry.java.patch` | `daemon/video/FrameBroadcasterRegistry.java` |
| `daemon/video/Frame.java.patch` | `daemon/video/Frame.java` |
| `daemon/video/VideoSubscriber.java.patch` | `daemon/video/VideoSubscriber.java` |

### 1.4 单元测试（7）

目标目录前缀 `server/src/test/java/com/genymobile/scrcpy/`。纯 JVM 逻辑测试，
由 `tools/test_compilation.sh` 的 `:server:testDebugUnitTest` 步骤执行。

| 补丁 | 覆盖内容 |
|---|---|
| `daemon/DaemonArgsTest.java.patch` | `strip` / `changeDisplayId` / `mergeOptions`（含 blocked key 过滤与畸形行处理） |
| `daemon/control/DaemonControlMessageReaderTest.java.patch` | daemon 请求载荷解析（含 `CONFIGURE_SESSION` entriesCount 越界拒绝） |
| `daemon/control/DaemonDeviceMessageWriterTest.java.patch` | daemon 响应序列化（generic / displays / infos / apps，经 `DeviceMessageWriter` 全路径） |
| `daemon/control/DeviceMessageSenderTest.java.patch` | `awaitDrained` 排空等待、超时语义、队列满时 pending 计数不漂移 |
| `daemon/video/ByteArrayPoolTest.java.patch` | 桶对齐（2 的幂）、回收复用、非 2 幂不入池、容量上限 |
| `daemon/video/FrameTest.java.patch` | header/meta 无池化 buffer、packet 拷贝语义、retain/release 引用计数、droppable |
| `daemon/video/VideoSubscriberTest.java.patch` | 关闭后 deliver 释放帧、`close()`/`deliver()` 并发竞态回归、关闭时排空队列 |

---

## 2. 修改上游文件（21 个）

这些补丁在**现有 scrcpy 文件**上做增量修改，引用部分新增类。应在新增之后应用。

| 补丁 | 目标文件 | 依赖的新增/关键改动 |
|---|---|---|
| `gradlew.patch` | `gradlew` | 无（构建脚本，注入 Java 21 自动探测） |
| `server/build.gradle.patch` | `server/build.gradle` | 无 |
| `server/.gitignore.patch` | `server/.gitignore` | 无 |
| `control/ControlChannel.java.patch` | `control/ControlChannel.java` | 构造函数改为 `InputStream`/`OutputStream` |
| `control/ControlMessage.java.patch` | `control/ControlMessage.java` | 新增 `extensionPayload` 字段 + `implements ExtensionCarrier` |
| `control/ControlMessageReader.java.patch` | `control/ControlMessageReader.java` | → `DaemonControlMessageReader`（新增） |
| `control/Controller.java.patch` | `control/Controller.java` | → `ControlMessageExtension`（新增）、`mirrorDisplayId` |
| `control/DeviceMessage.java.patch` | `control/DeviceMessage.java` | 新增 `extensionPayload` + `createEmpty()` + `implements ExtensionCarrier` |
| `control/DeviceMessageSender.java.patch` | `control/DeviceMessageSender.java` | 队列 16→64 |
| `control/DeviceMessageWriter.java.patch` | `control/DeviceMessageWriter.java` | → `DaemonDeviceMessageWriter`（新增） |
| `control/UhidManager.java.patch` | `control/UhidManager.java` | daemon 模式下的 UHID 适配 |
| `device/DesktopConnection.java.patch` | `device/DesktopConnection.java` | 适配 `ControlChannel` 新构造 |
| `device/Device.java.patch` | `device/Device.java` | 输入注入支持 `displayId>=0` |
| `device/Streamer.java.patch` | `device/Streamer.java` | `implements FrameSink`（新增） |
| `display/DisplayInfo.java.patch` | `display/DisplayInfo.java` | 新增 `mirrorDisplayId/owned/owner*` 字段 |
| `display/DisplayMonitor.java.patch` | `display/DisplayMonitor.java` | `setDisplayId()` 动态切换 |
| `Server.java.patch` | `Server.java` | → `DaemonServer`/`DaemonOptions`/`DaemonArgs`（新增） |
| `video/CaptureControl.java.patch` | `video/CaptureControl.java` | `requestSyncFrame()` |
| `video/ScreenCapture.java.patch` | `video/ScreenCapture.java` | → `ExternalDisplayProvider`（新增）、daemon 分支 |
| `video/SurfaceEncoder.java.patch` | `video/SurfaceEncoder.java` | `Streamer`→`FrameSink`（新增） |
| `wrappers/DisplayManager.java.patch` | `wrappers/DisplayManager.java` | 反射健壮性、创建 VD 多分支 |

---

## 3. 应用顺序与依赖说明

1. **先新增、后修改**。所有新增文件（§1）在前，修改文件（§2）在后。
   `apply_patches.sh` 已按 `patches_queue/server/` 下的排序应用，无需手工排序。
2. **接口先行**：`ControlMessageExtension`、`ExternalDisplayProvider`、`FrameSink`、
   `ExtensionCarrier`、`DaemonMessages`、`DaemonWire`、`RefCountedDisplayRegistry`
   被修改类直接实现/引用，务必在引用类之前落盘。
3. **同一文件仅一个补丁**，故补丁间无「互相覆盖」冲突。
4. 依赖关系仅影响**编译正确性**，`git apply` 本身按文本上下文匹配，不校验编译。

---

## 4. 使用方法（apply.sh）

```bash
# 查看清单
./apply.sh list

# 只读检查每个补丁在 ../scrcpy 的状态（CLEAN / APPLIED / CONFLICT）
./apply.sh check

# 按序应用（NEW→MODIFY），幂等：已应用自动跳过
./apply.sh apply

# 指定目标目录
./apply.sh apply -t /path/to/scrcpy

# 反向撤销（MODIFY→NEW 逆序）
./apply.sh reverse
```

### 状态含义
- **CLEAN**：目标工作区与补丁基线一致，可干净应用。
- **APPLIED**：目标已包含该改动（可用 `--reverse` 撤销）。
- **CONFLICT**：目标工作区已漂移（内容与补丁基线不一致），需人工处理。

> 注意：由于 scrcpy 工作区本身就是补丁的物化结果，`apply.sh check` 会把多数补丁标为
> **CONFLICT**。这表示「补丁与工作区现况不一致」，并非错误。修复请使用
> `../tools/apply_patches.sh`：它会逐补丁判定状态，普通重跑即可补齐缺失/漂移的文件；
> `--force` 则先 `git checkout`/`git clean` 还原 baseline 后整体重放；
> `../tools/test_compilation.sh` 在此基础上额外执行编译与单元测试验证。
