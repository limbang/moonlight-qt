#import "macmetalcompat.h"

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

static bool deviceNameIsOldIntel(NSString* name)
{
    if (name == nil) {
        return false;
    }

    // 这些一代的 Intel iGPU 上，Qt 6 的 Metal 后端会反复报
    // "Failed to create render pipeline state: Attribute N refers to a buffer
    // index X that is not valid"，QML 整窗空白；OpenGL 后端实测正常。
    // Haswell/Broadwell/Skylake 都不能原生跑 macOS 13+，在这类系统上出现时
    // 基本都来自 OpenCore Legacy Patcher。
    //
    // 按前缀匹配，且不匹配 2017+ 的 Iris Plus / UHD Graphics（那些 Metal 正常）。
    static NSArray<NSString*>* kOldIntelGpuPrefixes = @[
        // Haswell / Ivy Bridge
        @"Intel HD Graphics 4000",
        @"Intel HD Graphics 4200",
        @"Intel HD Graphics 4400",
        @"Intel HD Graphics 4600",
        @"Intel HD Graphics 5000",
        // Broadwell
        @"Intel HD Graphics 5600",
        @"Intel HD Graphics 5300",
        @"Intel HD Graphics 5500",
        @"Intel HD Graphics 6000",
        // Skylake
        @"Intel HD Graphics 510",
        @"Intel HD Graphics 515",
        @"Intel HD Graphics 520",
        @"Intel HD Graphics 530",
        @"Intel HD Graphics 540",
        @"Intel HD Graphics 550",
        @"Intel HD Graphics 580",
    ];

    for (NSString* prefix in kOldIntelGpuPrefixes) {
        if ([name hasPrefix:prefix]) {
            return true;
        }
    }

    // 旧 Iris / Iris Pro 的命名不带型号数字（例如 "Intel Iris Pro Graphics"），
    // 而 2017+ 的核显叫 "Intel Iris Plus Graphics"，不会撞上前缀。
    if ([name hasPrefix:@"Intel Iris Pro Graphics"] ||
        [name hasPrefix:@"Intel Iris Graphics"]) {
        return true;
    }

    return false;
}

static bool hasOldIntelIntegratedGpuIn(NSArray<id<MTLDevice>>* devices)
{
    for (id<MTLDevice> device in devices) {
        if (deviceNameIsOldIntel(device.name)) {
            return true;
        }
    }

    return false;
}

bool hasOldIntelIntegratedGpu()
{
    // 双 GPU Mac（例如 2015 款 15 寸 MacBook Pro）上，MTLCreateSystemDefaultDevice()
    // 在进程启动时可能返回独显（AMD Radeon R9 M370X），而 Qt 的 Metal RHI 实际
    // 用的却是核显。所以必须遍历 MTLCopyAllDevices()，只要机器上存在任何一代
    // 老 Intel iGPU 就算命中。
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
#if !__has_feature(objc_arc)
    [devices autorelease];
#endif

    return hasOldIntelIntegratedGpuIn(devices);
}

bool shouldForceOpenGLSceneGraphBackend()
{
    NSArray<id<MTLDevice>>* devices = MTLCopyAllDevices();
#if !__has_feature(objc_arc)
    [devices autorelease];
#endif

    if (devices.count == 0) {
        // 连 Metal 设备都拿不到，Qt Quick 无论如何都起不来，退回 OpenGL。
        return true;
    }

    return hasOldIntelIntegratedGpuIn(devices);
}
