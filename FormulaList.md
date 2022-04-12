# z80oolong/game に含まれる Formula 一覧

## 概要

本文書では、 [Linuxbrew][BREW] 向け Tap リポジトリ z80oolong/game に含まれる Formula 一覧を示します。各 Formula の詳細等については ```brew info <formula>``` コマンドも参照して下さい。

## Formula 一覧

### z80oolong/game/pokete

人気ゲームポケモンライクのテキストベースのオープンソースゲームソフトである [Pokete][POKE] について、 [Pokete][POKE] を日本語環境で動作させる際に罫線の文字幅が適切に扱えないために画面表示が崩れる問題を回避したもののうち、最新の安定版若しくは HEAD 版を導入する為の Formula です。

なお、 [Pokete][POKE] が用いる Python について、 [Linuxbrew][BREW] によって導入した ```python 3.9``` に代えて ```python 3.9``` の AppImage パッケージを用いる場合は、オプションに ```--without-python@3.9``` を指定して下さい。

### z80oolong/game/pokete@0.6.0

人気ゲームポケモンライクのテキストベースのオープンソースゲームソフトである [Pokete][POKE] について、 [Pokete][POKE] を日本語環境で動作させる際に罫線の文字幅が適切に扱えないために画面表示が崩れる問題を回避したもののうち、安定版 [Pokete 0.6.0][POKE] を導入する為の Formula です。

なお、 [Pokete][POKE] が用いる Python について、 [Linuxbrew][BREW] によって導入した ```python 3.9``` に代えて ```python 3.9``` の AppImage パッケージを用いる場合は、オプションに ```--without-python@3.9``` を指定して下さい。

**この Formula は、 versioned formula であるため、この Formula によって導入される ncurses は、 keg only で導入されることに留意して下さい。**

<!-- 外部リンク一覧 -->

[BREW]:https://linuxbrew.sh/
[POKE]:https://github.com/lxgr-linux/pokete
