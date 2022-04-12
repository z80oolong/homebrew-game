class Pokete < Formula
  include Language::Python::Virtualenv

  desc "A terminal based Pokemon like game"
  homepage "https://lxgr-linux.github.io/pokete"
  license "GPL-3.0"

  stable do
    url "https://github.com/lxgr-linux/pokete/archive/refs/tags/0.6.0.tar.gz"
    sha256 "465b87230bff6fbd243a31f7778b9c97ea65ca7b37c48caeb1b475b06e48c491"
    version "0.6.0"

    patch :p1, Formula["z80oolong/game/pokete@0.6.0"].diff_data
  end

  head do
    url "https://github.com/lxgr-linux/pokete.git"

    patch :p1, :DATA
  end

  depends_on "python@3.9" => :recommended

  resource("appimage-python3.9") do
    url "https://github.com/niess/python-appimage/releases/download/python3.9/python3.9.12-cp39-cp39-manylinux2014_x86_64.AppImage"
    sha256 "949427e55791fb91107bdd497a873ad375298445aac3b3d11ec18e10d0dbaf0d"
  end if build.without?("python@3.9")

  resource("scrap_engine") do
    url "https://github.com/lxgr-linux/scrap_engine/releases/download/1.2.0/scrap_engine-1.2.0.tar.gz"
    sha256 "767ffdc312b550777771cdc9a350a9f6dca73855259dd1fe7197c8736e38cac1"
  end

  def pokete_sh(python_home); <<~EOS
    #!/bin/sh
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    export PYTHON_HOME="#{python_home}"
    exec #{python_home}/bin/python3.9 #{libexec}/pokete/pokete.py "$@"
    EOS
  end

  def install
    libexec.mkdir; bin.mkdir

    if build.without?("python@3.9")
      resource("appimage-python3.9").stage do
        (Pathname.pwd/"python3.9.12-cp39-cp39-manylinux2014_x86_64.AppImage").chmod(0755)
        system "./python3.9.12-cp39-cp39-manylinux2014_x86_64.AppImage", "--appimage-extract"
        libexec.install "./squashfs-root"
      end

      resource("scrap_engine").stage do
        system "env", "PYTHON_HOME='#{libexec}/squashfs-root/usr'", \
          libexec/"squashfs-root/usr/bin/pip", "install", "-v", "--no-binary", ":all:", "--ignore-installed", "."
      end
      (buildpath/"pokete").write(pokete_sh(libexec/"squashfs-root/usr"))
    else
      venv = virtualenv_create(libexec, "python3")

      resource("scrap_engine").stage do
        system "env", "PYTHON_HOME='#{libexec}'", \
          libexec/"bin/pip", "install", "-v", "--no-binary", ":all:", "--ignore-installed", "."
      end
      (buildpath/"pokete").write(pokete_sh(libexec))
    end
 
    bin.install buildpath/"pokete"
    (libexec/"pokete").mkpath
    (libexec/"pokete").install Dir["*"]
    (bin/"pokete").chmod(0755)
  end

  def diff_data
    lines = self.path.each_line.inject([]) do |result, line|
      result.push(line) if ((/^__END__/ === line) || result.first)
      result
    end
    lines.shift
    return lines.join("")
  end

  test do
    system "false"
  end
end

__END__
diff --git a/pokete_classes/input.py b/pokete_classes/input.py
index 3bcf29f..8ca29b2 100644
--- a/pokete_classes/input.py
+++ b/pokete_classes/input.py
@@ -16,7 +16,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
         wrap_len: The len at which the text wraps
         max_len: The len at which the text shall end"""
     _ev.clear()
-    obj.rechar(hard_liner(wrap_len, name + "█"))
+    obj.rechar(hard_liner(wrap_len, name + "_"))
     bname = name
     _map.show()
     while True:
@@ -32,7 +32,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
                 _map.show()
                 return bname
             name = name[:-1]
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         elif _ev.get() not in ["", "Key.enter", "exit", "Key.backspace",
@@ -41,7 +41,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
             if _ev.get() == "Key.space":
                 _ev.set("' '")
             name += str(_ev.get().strip("'"))
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         std_loop(_map.name == "movemap")
diff --git a/pokete_classes/ui_elements.py b/pokete_classes/ui_elements.py
index 5dfa714..1572528 100644
--- a/pokete_classes/ui_elements.py
+++ b/pokete_classes/ui_elements.py
@@ -20,9 +20,9 @@ class StdFrame(se.Frame):
 
     def __init__(self, height, width):
         super().__init__(width=width, height=height,
-                         corner_chars=["┌", "┐", "└", "┘"],
-                         horizontal_chars=["─", "─"],
-                         vertical_chars=["│", "│"], state="float")
+                         corner_chars=["*", "*", "*", "*"],
+                         horizontal_chars=["-", "-"],
+                         vertical_chars=["|", "|"], state="float")
 
 
 class StdFrame2(se.Frame):
