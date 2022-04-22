const std = @import("std");
const Builder = @import("std").build.Builder;
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;

// TODO: Add other architectures

const default_qemu_path: []const u8 = "/usr/share/ovmf/OVMF.fd";

pub fn build(b: *Builder) void {
    const features = Target.x86.Feature;

    var disabled_features = Feature.Set.empty;
    var enabled_features = Feature.Set.empty;

    disabled_features.addFeature(@enumToInt(features.mmx));
    disabled_features.addFeature(@enumToInt(features.sse));
    disabled_features.addFeature(@enumToInt(features.sse2));
    disabled_features.addFeature(@enumToInt(features.avx));
    disabled_features.addFeature(@enumToInt(features.avx2));
    enabled_features.addFeature(@enumToInt(features.soft_float));

    const target = CrossTarget{ .cpu_arch = Target.Cpu.Arch.x86_64, .os_tag = Target.Os.Tag.freestanding, .abi = Target.Abi.none, .cpu_features_sub = disabled_features, .cpu_features_add = enabled_features };

    const mode = b.standardReleaseOptions();

    const kernel = b.addExecutable("kernel.elf", "src/main.zig");
    kernel.setTarget(target);
    kernel.setBuildMode(mode);
    kernel.setLinkerScriptPath(.{ .path = "src/link.ld" });
    kernel.code_model = .kernel;
    kernel.install();

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.install_step.?.step);
    const kernel_path = b.getInstallPath(kernel.install_step.?.dest_dir, kernel.out_filename);

    const bios_path = b.env_map.get("OVMF_PATH") orelse default_qemu_qpath;
    const initrd_step = b.addSystemCommand(&.{
        
    });
    const uefi_run_step = b.addSystemCommand(&.{
        "uefi-run",
        "--files", b.fmt("{s}/assets/bootboot.efi", .{b.build_root}), kernel_path,
        "--bios", bios_path,
        "--size", "100",
        "--qemu", "qemu-system-x86_64",
        "--", "-s", "-d", "guest_errors,cpu_reset", "-serial", "stdio", "-no-reboot", "-no-shutdown"});
    uefi_run_step.step.dependOn(kernel_step);

    const run_step = b.step("run", "Run the OS");
    run_step.dependOn(&uefi_run_step.step);
}
