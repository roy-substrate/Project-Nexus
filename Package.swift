// swift-tools-version: 6.0

import PackageDescription

var targetExcludes: [String] = [
    "App/Info.plist",
    "App/ProjectNexusApp.swift",
    "Services/ASREffectivenessService.swift",
    "Services/SubscriptionManager.swift",
    "Audio/ML/WhisperSurrogate.swift",
    "Audio/ML/DeepSpeechSurrogate.swift"
]

var testExcludes: [String] = [
    "TestCoverageProposal.md"
]

#if os(Linux)
targetExcludes += [
    "Audio",
    "Extensions",
    "Services/AnalyticsService.swift",
    "Services/MetricsService.swift",
    "Services/PerturbationService.swift"
]

testExcludes += [
    "AVAudioPCMBufferUtilitiesTests.swift",
    "BabbleNoiseGeneratorTests.swift",
    "CodecSimulatorTests.swift",
    "DSPUtilitiesTests.swift",
    "EndToEndTests.swift",
    "FloatArrayDSPTests.swift",
    "FrequencySweepGeneratorTests.swift",
    "MetricsServiceTests.swift",
    "NexusE2ETestAgent.swift",
    "PerturbationServiceTests.swift",
    "PsychoacousticMaskerTests.swift",
    "SpectralNotchGeneratorTests.swift",
    "UAPManagerTests.swift"
]
#endif

let package = Package(
    name: "ProjectNexus",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ProjectNexus",
            type: .static,
            targets: ["ProjectNexus"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectNexus",
            path: "ProjectNexus",
            exclude: targetExcludes
        ),
        .testTarget(
            name: "ProjectNexusTests",
            dependencies: ["ProjectNexus"],
            path: "ProjectNexusTests",
            exclude: testExcludes
        ),
    ]
)
