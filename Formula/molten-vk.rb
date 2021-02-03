class MoltenVk < Formula
   desc "Implementation of the Vulkan graphics and compute API on top of Metal"
   homepage "https://github.com/KhronosGroup/MoltenVK"
   url "https://github.com/KhronosGroup/MoltenVK/archive/v1.0.41.tar.gz"
   sha256 "a11208f3bc2eb5cd6cfebbc0bc09ac2af8ecbe5cc3e57cde817bc8bc96d2cc33"
   url "https://github.com/KhronosGroup/MoltenVK/archive/v1.1.1.tar.gz"
   sha256 "cd1712c571d4155f4143c435c8551a5cb8cbb311ad7fff03595322ab971682c0"
   license "Apache-2.0"
   revision 2

   depends_on "python@3.9" => :build
   depends_on xcode: ["11.0", :build]
   # Requires IOSurface/IOSurfaceRef.h.
   depends_on macos: :sierra
   depends_on macos: :mojave

   # MoltenVK depends on very specific revisions of its dependencies.
   # For each resource the path to the file describing the expected
   # revision is listed.
   resource "cereal" do
     # ExternalRevisions/cereal_repo_revision
     url "https://github.com/USCiLab/cereal.git",
         revision: "51cbda5f30e56c801c07fe3d3aba5d7fb9e6cca4"
   end

   resource "Vulkan-Headers" do
     # ExternalRevisions/Vulkan-Headers_repo_revision
     url "https://github.com/KhronosGroup/Vulkan-Headers.git",
         revision: "fb7f9c9bcd1d1544ea203a1f3d4253d0e90c5a90"
   end

   resource "Vulkan-Portability" do
     # ExternalRevisions/Vulkan-Portability_repo_revision
     url "https://github.com/KhronosGroup/Vulkan-Portability.git",
         revision: "53be040f04ce55463d0e5b25fd132f45f003e903"
   end

   resource "SPIRV-Cross" do
     # ExternalRevisions/SPIRV-Cross_repo_revision
     url "https://github.com/KhronosGroup/SPIRV-Cross.git",
         revision: "e58e8d5dbe03ea2cc755dbaf43ffefa1b8d77bef"
   end

   resource "glslang" do
     # ExternalRevisions/glslang_repo_revision
     url "https://github.com/KhronosGroup/glslang.git",
         revision: "e157435c1e777aa1052f446dafed162b4a722e03"
   end

   resource "SPIRV-Tools" do
     # External/glslang/known_good.json
     url "https://github.com/KhronosGroup/SPIRV-Tools.git",
         revision: "fd8e130510a6b002b28eee5885a9505040a9bdc9"
   end

   resource "SPIRV-Headers" do
     # External/glslang/known_good.json
     url "https://github.com/KhronosGroup/SPIRV-Headers.git",
         revision: "f8bf11a0253a32375c32cad92c841237b96696c0"
   end

   resource "Vulkan-Tools" do
     # ExternalRevisions/Vulkan-Tools_repo_revision
     url "https://github.com/KhronosGroup/Vulkan-Tools.git",
         revision: "7844b9b4e180612c7ca35bcb07ce7f86610b22c4"
   end

   def install
     system "./fetchDependencies --macos"
     resources.each do |res|
       res.stage(buildpath/"External"/res.name)
     end
     mv "External/SPIRV-Tools", "External/glslang/External/spirv-tools"
     mv "External/SPIRV-Headers", "External/glslang/External/spirv-tools/external/spirv-headers"

     mkdir "External/glslang/External/spirv-tools/build" do
       # Required due to files being generated during build.
       system "cmake", "..", *std_cmake_args
       system "make"
     end

     xcodebuild "-project", "ExternalDependencies.xcodeproj",
                "-scheme", "ExternalDependencies-macOS",
                "-derivedDataPath", "External/build",
                "SYMROOT=External/build", "OBJROOT=External/build",
                "build"

     xcodebuild "-project", "MoltenVKPackaging.xcodeproj",
                "-scheme", "MoltenVK Package (macOS only)",
                "-scheme", "MoltenVK Package",
                "SYMROOT=#{buildpath}/build", "OBJROOT=build",
                "build"
