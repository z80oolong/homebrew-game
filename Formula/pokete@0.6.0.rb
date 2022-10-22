class PoketeAT060 < Formula
  include Language::Python::Virtualenv

  desc "A terminal based Pokemon like game"
  homepage "https://lxgr-linux.github.io/pokete"
  url "https://github.com/lxgr-linux/pokete/archive/refs/tags/0.6.0.tar.gz"
  sha256 "465b87230bff6fbd243a31f7778b9c97ea65ca7b37c48caeb1b475b06e48c491"
  version "0.6.0"
  revision 1
  license "GPL-3.0"

  keg_only :versioned_formula

  depends_on "imagemagick" => :build
  depends_on "python@3.9" => :recommended

  resource("appimage-python3.9") do
    url "https://github.com/niess/python-appimage/releases/download/python3.9/python3.9.15-cp39-cp39-manylinux2014_x86_64.AppImage"
    sha256 "93087e57e51eeeb33da8ceec8f70627d0c19c9655f78099bb96cedafab9f542f"
  end if build.without?("python@3.9")

  resource("scrap_engine") do
    url "https://github.com/lxgr-linux/scrap_engine/releases/download/1.2.0/scrap_engine-1.2.0.tar.gz"
    sha256 "767ffdc312b550777771cdc9a350a9f6dca73855259dd1fe7197c8736e38cac1"
  end

  patch :p1, :DATA

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

    if build.without?("python@3.9") then
      resource("appimage-python3.9").stage do
        (Pathname.pwd/"python3.9.15-cp39-cp39-manylinux2014_x86_64.AppImage").chmod(0755)
        system "./python3.9.15-cp39-cp39-manylinux2014_x86_64.AppImage", "--appimage-extract"
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

    system "#{Formula["imagemagick"].opt_bin}/convert", \
      "#{buildpath}/assets/pokete.png", "-resize", "256x256!", "#{buildpath}/assets/pokete-256x256.png"
 
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
diff --git a/pokete.py b/pokete.py
index 094c4a0..a186f2a 100755
--- a/pokete.py
+++ b/pokete.py
@@ -15,6 +15,7 @@ import threading
 import math
 import socket
 import json
+import poketedir
 from pathlib import Path
 import scrap_engine as se
 import pokete_data as p_data
@@ -1485,14 +1486,14 @@ def save():
         # filters doublicates from used_npcs
         "used_npcs": list(dict.fromkeys(used_npcs))
     }
-    with open(HOME + SAVEPATH + "/pokete.json", "w+") as file:
+    with open(poketedir.savepath() / "pokete.json", "w+") as file:
         # writes the data to the save file in a nice format
         json.dump(_si, file, indent=4)
 
 
 def read_save():
     """Reads form savefile"""
-    Path(HOME + SAVEPATH).mkdir(parents=True, exist_ok=True)
+    Path(poketedir.savepath()).mkdir(parents=True, exist_ok=True)
     # Default test session_info
     _si = {
         "user": "DEFAULT",
@@ -1513,8 +1514,11 @@ def read_save():
         "used_npcs": []
     }
 
-    if (not os.path.exists(HOME + SAVEPATH + "/pokete.json")
-        and os.path.exists(HOME + SAVEPATH + "/pokete.py")):
+    if os.path.exists(poketedir.savepath() / "pokete.json"):
+        with open(poketedir.savepath() / "pokete.json") as _file:
+            _si = json.load(_file)
+    elif (not os.path.exists(HOME + SAVEPATH + "/pokete.json")
+          and os.path.exists(HOME + SAVEPATH + "/pokete.py")):
         with open(HOME + SAVEPATH + "/pokete.py") as _file:
             exec(_file.read())
         _si = json.loads(json.dumps(session_info))
@@ -2663,6 +2667,7 @@ if __name__ == "__main__":
     # Loading mods
     if settings.load_mods:
         try:
+            sys.path.insert(0, str(poketedir.modspath()))
             import mods
         except ModError as err:
             error_box = InfoBox(str(err), "Mod-loading Error")
diff --git a/pokete_classes/input.py b/pokete_classes/input.py
index d066d59..ed5a287 100644
--- a/pokete_classes/input.py
+++ b/pokete_classes/input.py
@@ -8,7 +8,7 @@ from .ui_elements import InfoBox, InputBox
 def text_input(obj, _map, name, ev, wrap_len, max_len=1000000):
     """Processes text input"""
     ev.clear()
-    obj.rechar(hard_liner(wrap_len, name + "█"))
+    obj.rechar(hard_liner(wrap_len, name + "_"))
     bname = name
     _map.show()
     while True:
@@ -24,7 +24,7 @@ def text_input(obj, _map, name, ev, wrap_len, max_len=1000000):
                 _map.show()
                 return bname
             name = name[:-1]
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             ev.clear()
         elif ev.get() not in ["", "Key.enter", "exit", "Key.backspace", "Key.shift",
@@ -32,7 +32,7 @@ def text_input(obj, _map, name, ev, wrap_len, max_len=1000000):
             if ev.get() == "Key.space":
                 ev.set("' '")
             name += str(ev.get().strip("'"))
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             ev.clear()
         std_loop(ev)
diff --git a/pokete_classes/ui_elements.py b/pokete_classes/ui_elements.py
index 0946260..d07d9a1 100644
--- a/pokete_classes/ui_elements.py
+++ b/pokete_classes/ui_elements.py
@@ -17,9 +17,9 @@ class StdFrame(se.Frame):
 
     def __init__(self, height, width):
         super().__init__(width=width, height=height,
-                         corner_chars=["┌", "┐", "└", "┘"],
-                         horizontal_chars=["─", "─"],
-                         vertical_chars=["│", "│"], state="float")
+                         corner_chars=["*", "*", "*", "*"],
+                         horizontal_chars=["-", "-"],
+                         vertical_chars=["|", "|"], state="float")
 
 
 class StdFrame2(se.Frame):
diff --git a/poketedir.py b/poketedir.py
new file mode 100644
index 0000000..03bc203
--- /dev/null
+++ b/poketedir.py
@@ -0,0 +1,55 @@
+"""It is a file containing a module that sets the path
+to save the Pokete settings, the path to write the log
+file, and the path to place the MOD from the environment
+variable "POKETEDIR"."""
+
+import os
+import sys
+import shutil
+from pathlib import Path
+from release import SAVEPATH
+
+savePath = None
+logPath  = None
+modsPath = None
+
+def savepath():
+    """Path for saving the 'Pokete' data, setting, etc."""
+    global savePath
+    if savePath == None:
+        savePath = os.environ.get("POKETEDIR", str(SAVEPATH))
+        savePath = Path(os.path.abspath(Path(savePath) / "json"))
+        Path(savePath).mkdir(parents=True, exist_ok=True)
+        return savePath
+    else:
+        return savePath
+
+def logpath():
+    """Path for writing the logfile of 'Pokete'."""
+    global logPath
+    if logPath == None:
+        logPath = os.environ.get("POKETEDIR", str(SAVEPATH))
+        logPath = Path(os.path.abspath(Path(logPath) / "log"))
+        Path(logPath).mkdir(parents=True, exist_ok=True)
+        return logPath
+    else:
+        return logPath
+
+def modspath():
+    """Path for Mods of 'Pokete'."""
+    global modsPath
+    if modsPath == None:
+        modsPath = os.environ.get("POKETEDIR", str(SAVEPATH))
+        modsPath = Path(os.path.abspath(modsPath))
+        _orig_modsPath = os.path.abspath(Path(os.path.dirname(__file__)) / "mods")
+        _new_modsPath  = os.path.abspath(Path(modsPath) / "mods")
+        if not os.path.isdir(_new_modsPath):
+            shutil.copytree(_orig_modsPath, _new_modsPath)
+        return modsPath
+    else:
+        return modsPath
+
+if __name__ == "__main__":
+    print(savepath())
+    print(logpath())
+    print(modspath())
