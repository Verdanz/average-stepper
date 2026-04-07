#!/usr/bin/env python3
"""Generate a minimal project.pbxproj for the AverageStepper iOS target."""
import os
import uuid


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    root = os.path.join(repo, "AverageStepper")
    swift_files: list[str] = []
    for dirpath, _, filenames in os.walk(root):
        for f in sorted(filenames):
            if f.endswith(".swift"):
                rel = os.path.relpath(os.path.join(dirpath, f), start=repo)
                swift_files.append(rel.replace("\\", "/"))
    swift_files.sort()

    test_root = os.path.join(repo, "AverageStepperTests")
    test_swift_files: list[str] = []
    if os.path.isdir(test_root):
        for dirpath, _, filenames in os.walk(test_root):
            for f in sorted(filenames):
                if f.endswith(".swift"):
                    rel = os.path.relpath(os.path.join(dirpath, f), start=repo)
                    test_swift_files.append(rel.replace("\\", "/"))
    test_swift_files.sort()

    files: list[tuple[str, str, str]] = []
    for p in swift_files:
        files.append((uid(), uid(), p))

    assets_ref = uid()
    assets_build = uid()
    proj_native = uid()
    target_id = uid()
    proj_config_list = uid()
    target_config_list = uid()
    debug_target = uid()
    release_target = uid()
    debug_proj = uid()
    release_proj = uid()
    sources_phase = uid()
    resources_phase = uid()
    frameworks_phase = uid()
    group_main = uid()
    proj_group = uid()
    products_group = uid()
    product_ref = uid()
    group_resources = uid()
    group_tests = uid()
    product_ref_test = uid()
    target_id_test = uid()
    sources_phase_test = uid()
    frameworks_phase_test = uid()
    target_config_list_test = uid()
    debug_test_target = uid()
    release_test_target = uid()
    container_proxy = uid()
    target_dep = uid()

    test_file_entries: list[tuple[str, str, str]] = []
    for p in test_swift_files:
        test_file_entries.append((uid(), uid(), p))

    pb: list[str] = []
    pb.append("// !$*UTF8*$!")
    pb.append("{")
    pb.append("\tarchiveVersion = 1;")
    pb.append("\tclasses = {};")
    pb.append("\tobjectVersion = 56;")
    pb.append("\tobjects = {")

    pb.append("\t\t/* Begin PBXBuildFile section */")
    for br, fr, path in files:
        pb.append(f"\t\t{br} /* {os.path.basename(path)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr}; }};")
    for br, fr, path in test_file_entries:
        pb.append(f"\t\t{br} /* {os.path.basename(path)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr}; }};")
    pb.append(f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref}; }};")
    pb.append("\t\t/* End PBXBuildFile section */")

    pb.append("\t\t/* Begin PBXFileReference section */")
    pb.append(
        f"\t\t{product_ref} /* AverageStepper.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AverageStepper.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    pb.append(
        f"\t\t{product_ref_test} /* AverageStepperTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = AverageStepperTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    for br, fr, path in files:
        rel = "/".join(path.split("/")[1:])  # strip AverageStepper/
        base = os.path.basename(path)
        pb.append(
            f"\t\t{fr} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel}\"; sourceTree = \"<group>\"; }};"
        )
    pb.append(
        f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};"
    )
    for br, fr, path in test_file_entries:
        rel = "/".join(path.split("/")[1:])  # strip AverageStepperTests/
        base = os.path.basename(path)
        pb.append(
            f"\t\t{fr} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel}\"; sourceTree = \"<group>\"; }};"
        )
    pb.append("\t\t/* End PBXFileReference section */")

    pb.append("\t\t/* Begin PBXFrameworksBuildPhase section */")
    pb.append(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    pb.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    pb.append("\t\t\tbuildActionMask = 2147483647;")
    pb.append("\t\t\tfiles = ();")
    pb.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pb.append("\t\t};")
    pb.append("\t\t/* End PBXFrameworksBuildPhase section */")

    pb.append("\t\t/* Begin PBXGroup section */")
    pb.append(f"\t\t{proj_group} = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append("\t\t\tchildren = (")
    pb.append(f"\t\t\t\t{group_main} /* AverageStepper */,")
    if test_file_entries:
        pb.append(f"\t\t\t\t{group_tests} /* AverageStepperTests */,")
    pb.append(f"\t\t\t\t{products_group} /* Products */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")
    pb.append(f"\t\t{products_group} = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append("\t\t\tchildren = (")
    pb.append(f"\t\t\t\t{product_ref} /* AverageStepper.app */,")
    if test_file_entries:
        pb.append(f"\t\t\t\t{product_ref_test} /* AverageStepperTests.xctest */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tname = Products;")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")
    pb.append(f"\t\t{group_resources} = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append("\t\t\tchildren = (")
    pb.append(f"\t\t\t\t{assets_ref} /* Assets.xcassets */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tpath = Resources;")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")
    pb.append(f"\t\t{group_main} = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append("\t\t\tchildren = (")
    for _, fr, _ in files:
        pb.append(f"\t\t\t\t{fr},")
    pb.append(f"\t\t\t\t{group_resources} /* Resources */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tpath = AverageStepper;")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")
    if test_file_entries:
        pb.append(f"\t\t{group_tests} = {{")
        pb.append("\t\t\tisa = PBXGroup;")
        pb.append("\t\t\tchildren = (")
        for _, fr, _ in test_file_entries:
            pb.append(f"\t\t\t\t{fr},")
        pb.append("\t\t\t);")
        pb.append("\t\t\tpath = AverageStepperTests;")
        pb.append("\t\t\tsourceTree = \"<group>\";")
        pb.append("\t\t};")
    pb.append("\t\t/* End PBXGroup section */")

    pb.append("\t\t/* Begin PBXNativeTarget section */")
    pb.append(f"\t\t{target_id} /* AverageStepper */ = {{")
    pb.append("\t\t\tisa = PBXNativeTarget;")
    pb.append(
        f"\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget \"AverageStepper\" */;"
    )
    pb.append("\t\t\tbuildPhases = (")
    pb.append(f"\t\t\t\t{sources_phase} /* Sources */,")
    pb.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    pb.append(f"\t\t\t\t{resources_phase} /* Resources */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tbuildRules = ();")
    pb.append("\t\t\tdependencies = ();")
    pb.append("\t\t\tname = AverageStepper;")
    pb.append("\t\t\tproductName = AverageStepper;")
    pb.append(f"\t\t\tproductReference = {product_ref} /* AverageStepper.app */;")
    pb.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pb.append("\t\t};")
    if test_file_entries:
        pb.append(f"\t\t{container_proxy} /* PBXContainerItemProxy */ = {{")
        pb.append("\t\t\tisa = PBXContainerItemProxy;")
        pb.append("\t\t\tcontainerPortal = {0} /* Project object */;".format(proj_native))
        pb.append("\t\t\tproxyType = 1;")
        pb.append(f"\t\t\tremoteGlobalIDString = {target_id};")
        pb.append("\t\t\tremoteInfo = AverageStepper;")
        pb.append("\t\t};")
        pb.append(f"\t\t{target_dep} /* PBXTargetDependency */ = {{")
        pb.append("\t\t\tisa = PBXTargetDependency;")
        pb.append(f"\t\t\ttarget = {target_id} /* AverageStepper */;")
        pb.append(f"\t\t\ttargetProxy = {container_proxy} /* PBXContainerItemProxy */;")
        pb.append("\t\t};")
        pb.append(f"\t\t{target_id_test} /* AverageStepperTests */ = {{")
        pb.append("\t\t\tisa = PBXNativeTarget;")
        pb.append(
            f"\t\t\tbuildConfigurationList = {target_config_list_test} /* Build configuration list for PBXNativeTarget \"AverageStepperTests\" */;"
        )
        pb.append("\t\t\tbuildPhases = (")
        pb.append(f"\t\t\t\t{sources_phase_test} /* Sources */,")
        pb.append(f"\t\t\t\t{frameworks_phase_test} /* Frameworks */,")
        pb.append("\t\t\t);")
        pb.append("\t\t\tbuildRules = ();")
        pb.append("\t\t\tdependencies = (")
        pb.append(f"\t\t\t\t{target_dep} /* PBXTargetDependency */,")
        pb.append("\t\t\t);")
        pb.append("\t\t\tname = AverageStepperTests;")
        pb.append("\t\t\tproductName = AverageStepperTests;")
        pb.append(f"\t\t\tproductReference = {product_ref_test} /* AverageStepperTests.xctest */;")
        pb.append("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
        pb.append("\t\t};")
    pb.append("\t\t/* End PBXNativeTarget section */")

    pb.append("\t\t/* Begin PBXProject section */")
    pb.append(f"\t\t{proj_native} /* Project object */ = {{")
    pb.append("\t\t\tisa = PBXProject;")
    pb.append("\t\t\tattributes = {")
    pb.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    pb.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    pb.append("\t\t\t\tLastUpgradeCheck = 1500;")
    pb.append("\t\t\t\tTargetAttributes = {")
    pb.append(f"\t\t\t\t\t{target_id} = {{")
    pb.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    pb.append("\t\t\t\t\t\tProvisioningStyle = Automatic;")
    pb.append("\t\t\t\t\t};")
    pb.append("\t\t\t\t};")
    pb.append("\t\t\t};")
    pb.append(
        f"\t\t\tbuildConfigurationList = {proj_config_list} /* Build configuration list for PBXProject \"AverageStepper\" */;"
    )
    pb.append("\t\t\tcompatibilityVersion = \"Xcode 16.0\";")
    pb.append("\t\t\tdevelopmentRegion = en;")
    pb.append("\t\t\thasScannedForEncodings = 0;")
    pb.append("\t\t\tknownRegions = (")
    pb.append("\t\t\t\ten,")
    pb.append("\t\t\t\tBase,")
    pb.append("\t\t\t);")
    pb.append(f"\t\t\tmainGroup = {proj_group};")
    pb.append(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    pb.append("\t\t\tprojectDirPath = \"\";")
    pb.append("\t\t\tprojectRoot = \"\";")
    pb.append("\t\t\ttargets = (")
    pb.append(f"\t\t\t\t{target_id} /* AverageStepper */,")
    if test_file_entries:
        pb.append(f"\t\t\t\t{target_id_test} /* AverageStepperTests */,")
    pb.append("\t\t\t);")
    pb.append("\t\t};")
    pb.append("\t\t/* End PBXProject section */")

    pb.append("\t\t/* Begin PBXResourcesBuildPhase section */")
    pb.append(f"\t\t{resources_phase} /* Resources */ = {{")
    pb.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pb.append("\t\t\tbuildActionMask = 2147483647;")
    pb.append("\t\t\tfiles = (")
    pb.append(f"\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pb.append("\t\t};")
    pb.append("\t\t/* End PBXResourcesBuildPhase section */")

    pb.append("\t\t/* Begin PBXSourcesBuildPhase section */")
    pb.append(f"\t\t{sources_phase} /* Sources */ = {{")
    pb.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pb.append("\t\t\tbuildActionMask = 2147483647;")
    pb.append("\t\t\tfiles = (")
    for br, _, path in files:
        pb.append(f"\t\t\t\t{br} /* {os.path.basename(path)} in Sources */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pb.append("\t\t};")
    pb.append("\t\t/* End PBXSourcesBuildPhase section */")

    if test_file_entries:
        pb.append("\t\t/* Begin PBXFrameworksBuildPhase section */")
        pb.append(f"\t\t{frameworks_phase_test} /* Frameworks */ = {{")
        pb.append("\t\t\tisa = PBXFrameworksBuildPhase;")
        pb.append("\t\t\tbuildActionMask = 2147483647;")
        pb.append("\t\t\tfiles = ();")
        pb.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        pb.append("\t\t};")
        pb.append("\t\t/* End PBXFrameworksBuildPhase section */")

        pb.append("\t\t/* Begin PBXSourcesBuildPhase section */")
        pb.append(f"\t\t{sources_phase_test} /* Sources */ = {{")
        pb.append("\t\t\tisa = PBXSourcesBuildPhase;")
        pb.append("\t\t\tbuildActionMask = 2147483647;")
        pb.append("\t\t\tfiles = (")
        for br, _, path in test_file_entries:
            pb.append(f"\t\t\t\t{br} /* {os.path.basename(path)} in Sources */,")
        pb.append("\t\t\t);")
        pb.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        pb.append("\t\t};")
        pb.append("\t\t/* End PBXSourcesBuildPhase section */")

    pb.append("\t\t/* Begin XCBuildConfiguration section */")
    for name, cfg_id, is_debug in (
        ("Debug", debug_target, True),
        ("Release", release_target, False),
    ):
        pb.append(f"\t\t{cfg_id} /* {name} */ = {{")
        pb.append("\t\t\tisa = XCBuildConfiguration;")
        pb.append("\t\t\tbuildSettings = {")
        pb.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
        pb.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
        pb.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
        pb.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
        pb.append("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
        pb.append("\t\t\t\tENABLE_PREVIEWS = YES;")
        if name == "Debug":
            pb.append("\t\t\t\tENABLE_TESTABILITY = YES;")
        pb.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
        pb.append("\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = \"Average Stepper\";")
        pb.append(
            "\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = \"Average Stepper needs your approximate location to generate walking routes near you and to show your position during an active walk. Data stays on your device.\";"
        )
        pb.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
        pb.append("\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;")
        pb.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;")
        pb.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
        pb.append(
            "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\");"
        )
        pb.append("\t\t\t\tMARKETING_VERSION = 0.1.0;")
        pb.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.AverageStepper;")
        pb.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
        pb.append("\t\t\t\tSDKROOT = iphoneos;")
        pb.append("\t\t\t\tSUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
        pb.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
        pb.append("\t\t\t\tSWIFT_VERSION = 5.0;")
        pb.append("\t\t\t\tTARGETED_DEVICE_FAMILY = 1;")
        if not is_debug:
            pb.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        pb.append("\t\t\t};")
        pb.append(f"\t\t\tname = {name};")
        pb.append("\t\t};")

    for name, cfg_id, is_debug in (
        ("Debug", debug_proj, True),
        ("Release", release_proj, False),
    ):
        pb.append(f"\t\t{cfg_id} /* {name} */ = {{")
        pb.append("\t\t\tisa = XCBuildConfiguration;")
        pb.append("\t\t\tbuildSettings = {")
        pb.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
        pb.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
        pb.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
        pb.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
        pb.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
        pb.append("\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;")
        pb.append("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
        pb.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
        pb.append("\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;")
        pb.append("\t\t\t\tSDKROOT = iphoneos;")
        if is_debug:
            pb.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
            pb.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
        else:
            pb.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        pb.append("\t\t\t};")
        pb.append(f"\t\t\tname = {name};")
        pb.append("\t\t};")

    if test_file_entries:
        for name, cfg_id, is_debug in (
            ("Debug", debug_test_target, True),
            ("Release", release_test_target, False),
        ):
            pb.append(f"\t\t{cfg_id} /* {name} */ = {{")
            pb.append("\t\t\tisa = XCBuildConfiguration;")
            pb.append("\t\t\tbuildSettings = {")
            pb.append("\t\t\t\tBUNDLE_LOADER = \"$(TEST_HOST)\";")
            pb.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
            pb.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
            pb.append("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
            pb.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
            pb.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
            pb.append(
                "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\", \"@loader_path/Frameworks\");"
            )
            pb.append("\t\t\t\tMARKETING_VERSION = 0.1.0;")
            pb.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.example.AverageStepperTests;")
            pb.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
            pb.append("\t\t\t\tSDKROOT = iphoneos;")
            pb.append("\t\t\t\tSUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
            pb.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;")
            pb.append("\t\t\t\tSWIFT_VERSION = 5.0;")
            pb.append("\t\t\t\tTARGETED_DEVICE_FAMILY = 1;")
            pb.append("\t\t\t\tTEST_HOST = \"$(BUILT_PRODUCTS_DIR)/AverageStepper.app/AverageStepper\";")
            if not is_debug:
                pb.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
            pb.append("\t\t\t};")
            pb.append(f"\t\t\tname = {name};")
            pb.append("\t\t};")

    pb.append("\t\t/* End XCBuildConfiguration section */")

    pb.append("\t\t/* Begin XCConfigurationList section */")
    pb.append(f"\t\t{target_config_list} /* Build configuration list for PBXNativeTarget \"AverageStepper\" */ = {{")
    pb.append("\t\t\tisa = XCConfigurationList;")
    pb.append("\t\t\tbuildConfigurations = (")
    pb.append(f"\t\t\t\t{debug_target} /* Debug */,")
    pb.append(f"\t\t\t\t{release_target} /* Release */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pb.append("\t\t\tdefaultConfigurationName = Release;")
    pb.append("\t\t};")
    if test_file_entries:
        pb.append(f"\t\t{target_config_list_test} /* Build configuration list for PBXNativeTarget \"AverageStepperTests\" */ = {{")
        pb.append("\t\t\tisa = XCConfigurationList;")
        pb.append("\t\t\tbuildConfigurations = (")
        pb.append(f"\t\t\t\t{debug_test_target} /* Debug */,")
        pb.append(f"\t\t\t\t{release_test_target} /* Release */,")
        pb.append("\t\t\t);")
        pb.append("\t\t\tdefaultConfigurationIsVisible = 0;")
        pb.append("\t\t\tdefaultConfigurationName = Release;")
        pb.append("\t\t};")
    pb.append(f"\t\t{proj_config_list} /* Build configuration list for PBXProject \"AverageStepper\" */ = {{")
    pb.append("\t\t\tisa = XCConfigurationList;")
    pb.append("\t\t\tbuildConfigurations = (")
    pb.append(f"\t\t\t\t{debug_proj} /* Debug */,")
    pb.append(f"\t\t\t\t{release_proj} /* Release */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pb.append("\t\t\tdefaultConfigurationName = Release;")
    pb.append("\t\t};")
    pb.append("\t\t/* End XCConfigurationList section */")

    pb.append("\t};")
    pb.append(f"\trootObject = {proj_native} /* Project object */;")
    pb.append("}")

    out = os.path.join(repo, "AverageStepper.xcodeproj", "project.pbxproj")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(pb))

    print(
        f"Wrote {out} ({len(files)} app Swift files"
        + (f", {len(test_file_entries)} test files)" if test_file_entries else ")")
    )


if __name__ == "__main__":
    main()
