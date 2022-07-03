class PoketeAT073 < Formula
  include Language::Python::Virtualenv

  desc "A terminal based Pokemon like game"
  homepage "https://lxgr-linux.github.io/pokete"
  url "https://github.com/lxgr-linux/pokete/archive/refs/tags/0.7.3.tar.gz"
  sha256 "bee2eb4fc50da086b04101fab8a479719af46e74dd3ccd05d3aa50235a576aed"
  version "0.7.3"
  license "GPL-3.0"

  keg_only :versioned_formula

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
index 8a613fe..b84b987 100755
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
@@ -741,7 +742,7 @@ def save():
         "pokete_care": pokete_care.dict(),
         "time": timer.time.time
     }
-    with open(HOME + SAVEPATH + "/pokete.json", "w+") as file:
+    with open(poketedir.savepath() + "/pokete.json", "w+") as file:
         # writes the data to the save file in a nice format
         json.dump(_si, file, indent=4)
     logging.info("[General] Saved")
@@ -751,7 +752,7 @@ def read_save():
     """Reads form savefile
     RETURNS:
         session_info dict"""
-    Path(HOME + SAVEPATH).mkdir(parents=True, exist_ok=True)
+    Path(poketedir.savepath()).mkdir(parents=True, exist_ok=True)
     # Default test session_info
     _si = {
         "user": "DEFAULT",
@@ -781,14 +782,14 @@ def read_save():
         "time": 0
     }
 
-    if (not os.path.exists(HOME + SAVEPATH + "/pokete.json")
-        and os.path.exists(HOME + SAVEPATH + "/pokete.py")):
+    if (not os.path.exists(poketedir.savepath() + "/pokete.json")
+        and os.path.exists(poketedir.savepath() + "/pokete.py")):
         l_dict = {}
-        with open(HOME + SAVEPATH + "/pokete.py", "r") as _file:
+        with open(poketedir.savepath() + "/pokete.py", "r") as _file:
             exec(_file.read(), {"session_info": _si}, l_dict)
         _si = json.loads(json.dumps(l_dict["session_info"]))
-    elif os.path.exists(HOME + SAVEPATH + "/pokete.json"):
-        with open(HOME + SAVEPATH + "/pokete.json") as _file:
+    elif os.path.exists(poketedir.savepath() + "/pokete.json"):
+        with open(poketedir.savepath() + "/pokete.json") as _file:
             _si = json.load(_file)
     return _si
 
@@ -1407,7 +1408,7 @@ if __name__ == "__main__":
     loading_screen()
 
     # logging config
-    log_file = f"{HOME}{SAVEPATH}/pokete.log" if do_logging else None
+    log_file = f"{poketedir.logpath()}/pokete.log" if do_logging else None
     logging.basicConfig(filename=log_file,
                         format='[%(asctime)s][%(levelname)s]: %(message)s',
                         level=logging.DEBUG if do_logging else logging.ERROR)
@@ -1424,6 +1425,7 @@ if __name__ == "__main__":
     # Loading mods
     if settings("load_mods").val:
         try:
+            sys.path.insert(0, poketedir.modspath())
             import mods
         except ModError as err:
             error_box = InfoBox(str(err), "Mod-loading Error")
diff --git a/pokete_classes/input.py b/pokete_classes/input.py
index 3d70144..9429d6e 100644
--- a/pokete_classes/input.py
+++ b/pokete_classes/input.py
@@ -15,7 +15,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
         wrap_len: The len at which the text wraps
         max_len: The len at which the text shall end"""
     _ev.clear()
-    obj.rechar(hard_liner(wrap_len, name + "█"))
+    obj.rechar(hard_liner(wrap_len, name + "_"))
     bname = name
     _map.show()
     while True:
@@ -31,7 +31,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
                 _map.show()
                 return bname
             name = name[:-1]
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         elif ((i := _ev.get()) not in ["", "exit"] and "Key." not in i) \
@@ -39,7 +39,7 @@ def text_input(obj, _map, name, wrap_len, max_len=1000000):
             if _ev.get() == "Key.space":
                 _ev.set("' '")
             name += str(_ev.get().strip("'"))
-            obj.rechar(hard_liner(wrap_len, name + "█"))
+            obj.rechar(hard_liner(wrap_len, name + "_"))
             _map.show()
             _ev.clear()
         std_loop(_map.name == "movemap")
diff --git a/pokete_classes/ui_elements.py b/pokete_classes/ui_elements.py
index 5dfa714..fa5ef4e 100644
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
@@ -162,15 +162,15 @@ class BetterChooserItem(Box):
 
     def choose(self):
         """Rechars the frame to be highlighted"""
-        self.frame.rechar(corner_chars=["┏", "┓", "┗", "┛"],
-                          horizontal_chars=["━", "━"],
-                          vertical_chars=["┃", "┃"])
+        self.frame.rechar(corner_chars=["@", "@", "@", "@"],
+                          horizontal_chars=["=", "="],
+                          vertical_chars=["|", "|"])
 
     def unchoose(self):
         """Rechars the frame to be not highlighted"""
-        self.frame.rechar(corner_chars=["┌", "┐", "└", "┘"],
-                          horizontal_chars=["─", "─"],
-                          vertical_chars=["│", "│"])
+        self.frame.rechar(corner_chars=["*", "*", "*", "*"],
+                          horizontal_chars=["-", "-"],
+                          vertical_chars=["|", "|"])
 
 
 class BetterChooseBox(Box):
diff --git a/poketedir.py b/poketedir.py
new file mode 100644
index 0000000..c6ecf5e
--- /dev/null
+++ b/poketedir.py
@@ -0,0 +1,57 @@
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
+HOME = os.path.abspath(Path.home())
+
+savePath = None
+logPath  = None
+modsPath = None
+
+def savepath():
+    """Path for saving the 'Pokete' data, setting, etc."""
+    global savePath
+    if savePath == None:
+        savePath = os.environ.get("POKETEDIR", HOME + SAVEPATH)
+        savePath = os.path.abspath(savePath + "/json")
+        Path(savePath).mkdir(parents=True, exist_ok=True)
+        return savePath
+    else:
+        return savePath
+
+def logpath():
+    """Path for writing the logfile of 'Pokete'."""
+    global logPath
+    if logPath == None:
+        logPath = os.environ.get("POKETEDIR", HOME + SAVEPATH)
+        logPath = os.path.abspath(logPath + "/log")
+        Path(logPath).mkdir(parents=True, exist_ok=True)
+        return logPath
+    else:
+        return logPath
+
+def modspath():
+    """Path for Mods of 'Pokete'."""
+    global modsPath
+    if modsPath == None:
+        modsPath = os.environ.get("POKETEDIR", HOME + SAVEPATH)
+        modsPath = os.path.abspath(modsPath)
+        _orig_modsPath = os.path.abspath(os.path.dirname(__file__) + "/mods")
+        _new_modsPath  = os.path.abspath(modsPath + "/mods")
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
index 9c17650..7f9df9c 100644
--- a/release.py
+++ b/release.py
@@ -2,5 +2,5 @@
 
 VERSION = "0.7.2"
 CODENAME = "Grey Edition"
-SAVEPATH = "/.cache/pokete"
+SAVEPATH = "/.config/pokete"
 FRAMETIME = 0.05
