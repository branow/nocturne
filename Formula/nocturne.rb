# Installs the prebuilt universal binary from a GitHub release.
# The `url`, `sha256`, and `version` lines below are rewritten by the release
# workflow on every tag — do not hand-edit them.
class Nocturne < Formula
  desc "Keep macOS awake — menu bar + CLI, no App Store, no account"
  homepage "https://github.com/branow/nocturne"
  url "https://github.com/branow/nocturne/releases/download/v0.1.0/nocturne-0.1.0-macos.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  version "0.1.0"
  license "MIT"

  def install
    bin.install "nocturne"
  end

  service do
    run [opt_bin/"nocturne", "daemon"]
    keep_alive true
    log_path var/"log/nocturne.log"
    error_log_path var/"log/nocturne.log"
  end

  test do
    assert_match "nocturne", shell_output("#{bin}/nocturne status")
  end
end
