#pragma once

// macOS 专用：判断本机是否存在一代老 Intel iGPU（Haswell/Broadwell/Skylake
// 一代的 HD/Iris/Iris Pro）。这些 GPU 上 Qt 6 的 Metal 渲染管线创建失败，
// MoltenVK 的 Vulkan 视频渲染也不稳定（VK_ERROR_DEVICE_LOST 黑屏）。
// 实现见 macmetalcompat.mm。
bool hasOldIntelIntegratedGpu();

// macOS 专用：判断 Qt Quick 是否应该从 Metal 后端退回 OpenGL。
// 老 Intel iGPU（Haswell/Broadwell/Skylake 一代）上 Qt 6 的 Metal 渲染管线
// 创建失败，QML 界面会整窗空白。实现见 macmetalcompat.mm。
bool shouldForceOpenGLSceneGraphBackend();
