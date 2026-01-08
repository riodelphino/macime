class Macime < Formula
  desc "Fast macOS IME switcher CLI"
  homepage "https://github.com/riodelphino/macime"
  url "https://github.com/riodelphino/macime/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "9d735becb328de48575225a24ae9cd01c56e01732a6ceb7a3dd8d8e5e4b6014e"
  license "MIT"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release"
    bin.install ".build/release/macime"
  end
end
