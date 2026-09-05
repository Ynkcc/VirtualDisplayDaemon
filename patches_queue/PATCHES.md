# patches_queue 补丁清单

本目录保存 VirtualDisplay daemon 对 scrcpy 子模块 `server/` 的补丁集合。
补丁路径前缀（`server/...`、`gradlew`）相对目标仓库根 **`daemon/scrcpy`**。

共 **60 个补丁**：39 个新增文件 + 21 个修改上游文件。

> 应用工具：`./apply.sh`（支持 `list` / `check` / `apply` / `reverse`），见文末。

---

## 1. 新增文件（39 个）

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

### 1.3 daemon（36）
`daemon/` 包为 daemon 模式的核心，内部有包级依赖，但均为新增、互相可解析：

| 补丁 | 目标文件 |
|---|---|
| `daemon/ClientSession.java.patch` | `daemon/ClientSession.java` |
| `daemon/compat/DisplayCompat.java.patch` | `daemon/compat/DisplayCompat.java` |
| `daemon/control/CommandContext.java.patch` | `daemon/control/CommandContext.java` |
| `daemon/control/CommandHandler.java.patch` | `daemon/control/CommandHandler.java` |
| `daemon/control/DaemonCommandHandler.java.patch` | `daemon/control/DaemonCommandHandler.java` |
| `daemon/control/DaemonControlMessage.java.patch` | `daemon/control/DaemonControlMessage.java` |
| `daemon/control/DaemonControlMessageReader.java.patch` | `daemon/control/DaemonControlMessageReader.java` |
| `daemon/control/DaemonDeviceMessage.java.patch` | `daemon/control/DaemonDeviceMessage.java` |
| `daemon/control/DaemonDeviceMessageWriter.java.patch` | `daemon/control/DaemonDeviceMessageWriter.java` |
| `daemon/control/DaemonMessages.java.patch` | `daemon/control/DaemonMessages.java` |
| `daemon/control/DaemonWire.java.patch` | `daemon/control/DaemonWire.java` |
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
| `daemon/net/InstanceMutex.java.patch` | `daemon/net/InstanceMutex.java` |
| `daemon/net/TcpDesktopConnection.java.patch` | `daemon/net/TcpDesktopConnection.java` |
| `daemon/net/TcpServerSocketListener.java.patch` | `daemon/net/TcpServerSocketListener.java` |
| `daemon/SessionConfigurator.java.patch` | `daemon/SessionConfigurator.java` |
| `daemon/SessionVideoController.java.patch` | `daemon/SessionVideoController.java` |
| `daemon/VideoController.java.patch` | `daemon/VideoController.java` |
| `daemon/video/ByteArrayPool.java.patch` | `daemon/video/ByteArrayPool.java` |
| `daemon/video/FrameBroadcaster.java.patch` | `daemon/video/FrameBroadcaster.java` |
| `daemon/video/FrameBroadcasterRegistry.java.patch` | `daemon/video/FrameBroadcasterRegistry.java` |
| `daemon/video/Frame.java.patch` | `daemon/video/Frame.java` |
| `daemon/video/VideoSubscriber.java.patch` | `daemon/video/VideoSubscriber.java` |

---

## 2. 修改上游文件（20 个）

这些补丁在**现有 scrcpy 文件**上做增量修改，引用部分新增类。应在新增之后应用。

| 补丁 | 目标文件 | 依赖的新增/关键改动 |
|---|---|---|
| `gradlew.patch` | `gradlew` | 无（构建脚本） |
| `server/build.gradle.patch` | `server/build.gradle` | 无 |
| `server/.gitignore.patch` | `server/.gitignore` | 无 |
| `control/ControlChannel.java.patch` | `control/ControlChannel.java` | 构造函数改为 `InputStream`/`OutputStream` |
| `control/ControlMessage.java.patch` | `control/ControlMessage.java` | 新增 `extensionPayload` 字段 + `implements ExtensionCarrier` |
| `control/ControlMessageReader.java.patch` | `control/ControlMessageReader.java` | → `DaemonControlMessageReader`（新增） |
| `control/Controller.java.patch` | `control/Controller.java` | → `ControlMessageExtension`（新增）、`mirrorDisplayId` |
| `control/DeviceMessage.java.patch` | `control/DeviceMessage.java` | 新增 `extensionPayload` + `createEmpty()` + `implements ExtensionCarrier` |
| `control/DeviceMessageSender.java.patch` | `control/DeviceMessageSender.java` | 队列 16→64 |
| `control/DeviceMessageWriter.java.patch` | `control/DeviceMessageWriter.java` | → `DaemonDeviceMessageWriter`（新增） |
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
   `apply.sh` 已强制该顺序，无需手工排序。
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

> 注意：当前 `daemon/scrcpy` 工作区已包含 daemon 改动，`apply.sh check` 大概率
> 会将多数补丁标为 **CONFLICT**。这表示「补丁与工作区现况不一致」，并非错误；
> 若需从干净基线重放，请先在 scrcpy 仓库 `git stash` / 重置工作区后再 `apply`。
