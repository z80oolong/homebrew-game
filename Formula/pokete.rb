class Pokete < Formula
  include Language::Python::Virtualenv

  desc "A terminal based Pokemon like game"
  homepage "https://lxgr-linux.github.io/pokete"
  license "GPL-3.0"

  stable do
    url "https://github.com/lxgr-linux/pokete/archive/refs/tags/0.7.2.tar.gz"
    sha256 "7410b2043a53e636bfb8c9ede4c24f933f2bd3f5685ff0b2b3031206d7cbd5f4"
    version "0.7.2"

    patch :p1, Formula["z80oolong/game/pokete@0.7.2"].diff_data
  end

  head do
    url "https://github.com/lxgr-linux/pokete.git"

    patch :p1, :DATA
  end

  depends_on "imagemagick" => :build
  depends_on "python@3.9" => :recommended

  resource("appimage-python3.9") do
    url "https://github.com/niess/python-appimage/releases/download/python3.9/python3.9.12-cp39-cp39-manylinux2014_x86_64.AppImage"
    sha256 "318b380d944e30ff7dda62c1baa92307ed08f1aa160ebcdd68a4e7c428e68416"
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

    if build.without?("python@3.9") then
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
index 45258d6..7b73da0 100755
--- a/pokete.py
+++ b/pokete.py
@@ -15,6 +15,7 @@ import math
 import socket
 import json
 import logging
+import poketedir
 from pathlib import Path
 import scrap_engine as se
 import pokete_data as p_data
@@ -756,7 +757,7 @@ def save():
         "pokete_care": pokete_care.dict(),
         "time": timer.time.time
     }
-    with open(SAVEPATH / "pokete.json", "w+") as file:
+    with open(poketedir.savepath() / "pokete.json", "w+") as file:
         # writes the data to the save file in a nice format
         json.dump(_si, file, indent=4)
     logging.info("[General] Saved")
@@ -766,7 +767,7 @@ def read_save():
     """Reads from savefile
     RETURNS:
         session_info dict"""
-    Path(SAVEPATH).mkdir(parents=True, exist_ok=True)
+    Path(poketedir.savepath()).mkdir(parents=True, exist_ok=True)
     # Default test session_info
     _si = {
         "user": "DEFAULT",
@@ -797,8 +798,8 @@ def read_save():
         "time": 0
     }
 
-    if os.path.exists(SAVEPATH / "pokete.json"):
-        with open(SAVEPATH / "pokete.json") as _file:
+    if os.path.exists(poketedir.savepath() / "pokete.json"):
+        with open(poketedir.savepath() / "pokete.json") as _file:
             _si = json.load(_file)
     elif os.path.exists(HOME / ".cache" / "pokete" / "pokete.json"):
         with open(HOME / ".cache" / "pokete" / "pokete.json") as _file:
@@ -810,7 +811,6 @@ def read_save():
         _si = json.loads(json.dumps(l_dict["session_info"]))
     return _si
 
-
 def on_press(key):
     """Sets the input to either a character like 'a' or '1', or Key.enter, Key.backspace, Key.space, Key.esc, exit
     ARGS:
@@ -1450,7 +1450,7 @@ if __name__ == "__main__":
     session_info = read_save()
 
     # logging config
-    log_file = (SAVEPATH / "pokete.log") if do_logging else None
+    log_file = (poketedir.logpath() / "pokete.log") if do_logging else None
     logging.basicConfig(filename=log_file,
                         format='[%(asctime)s][%(levelname)s]: %(message)s',
                         level=logging.DEBUG if do_logging else logging.ERROR)
@@ -1466,6 +1466,7 @@ if __name__ == "__main__":
     # Loading mods
     if settings("load_mods").val:
         try:
+            sys.path.insert(0, str(poketedir.modspath()))
             import mods
         except ModError as err:
             error_box = InfoBox(str(err), "Mod-loading Error")
diff --git a/pokete_classes/input.py b/pokete_classes/input.py
index 6e5a753..c3db70f 100644
--- a/pokete_classes/input.py
+++ b/pokete_classes/input.py
@@ -16,7 +16,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
         wrap_len: The len at which the text wraps
         max_len: The len at which the text shall end"""
     _ev.clear()
-    obj.rechar(hard_liner(wrap_len, name + "???"))
+    obj.rechar(hard_liner(wrap_len, name + "_"))
     bname = name
     _map.show()
     while True:
@@ -33,7 +33,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
                 _map.show()
                 return bname
             name = name[:-1]
-            obj.rechar(hard_liner(wrap_len, name + "???"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         elif ((i := _ev.get()) not in ["", "exit"] and "Key." not in i) \
@@ -41,7 +41,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
             if _ev.get() == "Key.space":
                 _ev.set(" ")
             name += str(_ev.get())
-            obj.rechar(hard_liner(wrap_len, name + "???"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         std_loop(_map.name == "movemap")
diff --git a/pokete_classes/ui_elements.py b/pokete_classes/ui_elements.py
index 400cada..448f283 100644
--- a/pokete_classes/ui_elements.py
+++ b/pokete_classes/ui_elements.py
@@ -22,9 +22,9 @@ class StdFrame(se.Frame):
 
     def __init__(self, height, width):
         super().__init__(width=width, height=height,
-                         corner_chars=["???", "???", "???", "???"],
-                         horizontal_chars=["???", "???"],
-                         vertical_chars=["???", "???"], state="float")
+                         corner_chars=["*", "*", "*", "*"],
+                         horizontal_chars=["-", "-"],
+                         vertical_chars=["|", "|"], state="float")
 
 
 class StdFrame2(se.Frame):
@@ -176,15 +176,15 @@ class BetterChooserItem(Box):
 
     def choose(self):
         """Rechars the frame to be highlighted"""
-        self.frame.rechar(corner_chars=["???", "???", "???", "???"],
-                          horizontal_chars=["???", "???"],
-                          vertical_chars=["???", "???"])
+        self.frame.rechar(corner_chars=["@", "@", "@", "@"],
+                          horizontal_chars=["=", "="],
+                          vertical_chars=["|", "|"])
 
     def unchoose(self):
         """Rechars the frame to be not highlighted"""
-        self.frame.rechar(corner_chars=["???", "???", "???", "???"],
-                          horizontal_chars=["???", "???"],
-                          vertical_chars=["???", "???"])
+        self.frame.rechar(corner_chars=["*", "*", "*", "*"],
+                          horizontal_chars=["-", "-"],
+                          vertical_chars=["|", "|"])
 
 
 class BetterChooseBox(Box):
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
diff --git a/release.py b/release.py
index 55efda1..09ff03e 100644
--- a/release.py
+++ b/release.py
@@ -7,8 +7,8 @@ VERSION = "0.7.2"
 CODENAME = "Grey Edition"
 SAVEPATH = Path(
     os.environ.get(
-        "XDG_DATA_HOME",
-        str(Path.home())+"/.local/share"
+        "XDG_CONFIG_HOME",
+        str(Path.home())+"/.config"
     )
 ) / "pokete"
 FRAMETIME = 0.05
